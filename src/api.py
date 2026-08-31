import os
import random
from datetime import datetime, timedelta

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr, Field
import joblib
import pandas as pd

from src.database import engine, get_db, Base
from src.models_db import TransactionLog, User, PasswordResetCode
from src.auth import hash_password, verify_password, create_access_token, get_current_user
from src.email_util import send_reset_code_email

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Fraud Detection API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = joblib.load("models/fraud_model.pkl")


# ───────────────────────── schemas ─────────────────────────

class Transaction(BaseModel):
    amount: float = Field(gt=0, le=10_000_000)
    hour_of_day: float = Field(ge=0, le=23)
    transactions_last_hour: int = Field(ge=0, le=1000)
    is_new_device: int = Field(ge=0, le=1)
    account_age_days: float = Field(ge=0, le=36500)


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str = Field(min_length=6)


# ───────────────────────── public endpoints (no login needed) ─────────────────────────

@app.get("/")
def home():
    return {"message": "Fraud Detection API is running"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


# ### NEW: register
@app.post("/register")
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(email=payload.email, hashed_password=hash_password(payload.password))
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"message": "Account created successfully", "email": user.email}


# ### NEW: login (returns JWT token)
@app.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password")

    token = create_access_token(data={"sub": user.email})
    return {"access_token": token, "token_type": "bearer"}


# ### NEW: forgot password — emails a 6-digit code
@app.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        # Don't reveal whether the email exists — respond the same either way
        return {"message": "If that email exists, a reset code has been sent"}

    code = str(random.randint(100000, 999999))
    reset_entry = PasswordResetCode(
        email=payload.email,
        code=code,
        expires_at=datetime.utcnow() + timedelta(minutes=15),
    )
    db.add(reset_entry)
    db.commit()

    try:
        send_reset_code_email(payload.email, code)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")

    return {"message": "If that email exists, a reset code has been sent"}


# ### NEW: reset password using the emailed code
@app.post("/reset-password")
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    reset_entry = (
        db.query(PasswordResetCode)
        .filter(
            PasswordResetCode.email == payload.email,
            PasswordResetCode.code == payload.code,
            PasswordResetCode.used == False,
        )
        .order_by(PasswordResetCode.id.desc())
        .first()
    )

    if not reset_entry:
        raise HTTPException(status_code=400, detail="Invalid or already-used code")
    if reset_entry.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Code has expired")

    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.hashed_password = hash_password(payload.new_password)
    reset_entry.used = True
    db.commit()

    return {"message": "Password reset successfully"}


# ───────────────────────── protected endpoints (login required) ─────────────────────────

@app.post("/check-transaction")
def check_transaction(
    transaction: Transaction,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    df = pd.DataFrame([transaction.dict()])
    fraud_probability = float(model.predict_proba(df)[0][1])
    is_fraud = bool(model.predict(df)[0])
    risk_level = "HIGH" if fraud_probability > 0.7 else "MEDIUM" if fraud_probability > 0.3 else "LOW"

    log_entry = TransactionLog(
        amount=transaction.amount,
        hour_of_day=transaction.hour_of_day,
        transactions_last_hour=transaction.transactions_last_hour,
        is_new_device=transaction.is_new_device,
        account_age_days=transaction.account_age_days,
        is_fraud=is_fraud,
        fraud_probability=round(fraud_probability, 4),
        risk_level=risk_level,
    )
    db.add(log_entry)
    db.commit()
    db.refresh(log_entry)

    return {
        "id": log_entry.id,
        "is_fraud": is_fraud,
        "fraud_probability": round(fraud_probability, 4),
        "risk_level": risk_level,
    }


@app.get("/history")
def get_history(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    logs = db.query(TransactionLog).order_by(TransactionLog.id.desc()).limit(limit).all()
    return logs


@app.get("/stats")
def get_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    total = db.query(TransactionLog).count()
    fraud_count = db.query(TransactionLog).filter(TransactionLog.is_fraud == True).count()
    return {
        "total_checked": total,
        "fraud_detected": fraud_count,
        "fraud_rate": round(fraud_count / total, 4) if total > 0 else 0,
    }
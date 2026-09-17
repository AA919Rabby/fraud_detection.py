import random
from datetime import datetime, timedelta

import joblib
import pandas as pd

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm

from pydantic import BaseModel, EmailStr, Field

from sqlalchemy import inspect, text
from sqlalchemy.orm import Session

from src.database import engine, get_db, Base
from src.models_db import (
    TransactionLog,
    User,
    PasswordResetCode,
)
from src.auth import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_user,
)
from src.email_util import send_reset_code_email


# ============================================================
# DATABASE
# ============================================================

Base.metadata.create_all(bind=engine)


def migrate_transaction_logs():
    """
    Adds user_id to existing transaction_logs tables.

    IMPORTANT:
    SQLAlchemy create_all() does NOT modify an existing table.
    This small migration makes existing deployments safer.
    """

    inspector = inspect(engine)

    try:
        columns = inspector.get_columns("transaction_logs")
    except Exception:
        return

    column_names = {column["name"] for column in columns}

    if "user_id" in column_names:
        return

    dialect = engine.dialect.name

    with engine.begin() as connection:

        if dialect == "postgresql":
            connection.execute(
                text(
                    """
                    ALTER TABLE transaction_logs
                    ADD COLUMN user_id INTEGER
                    """
                )
            )

            connection.execute(
                text(
                    """
                    CREATE INDEX IF NOT EXISTS
                    ix_transaction_logs_user_id
                    ON transaction_logs(user_id)
                    """
                )
            )

        elif dialect == "sqlite":
            connection.execute(
                text(
                    """
                    ALTER TABLE transaction_logs
                    ADD COLUMN user_id INTEGER
                    """
                )
            )

            connection.execute(
                text(
                    """
                    CREATE INDEX IF NOT EXISTS
                    ix_transaction_logs_user_id
                    ON transaction_logs(user_id)
                    """
                )
            )

        else:
            # Generic SQLAlchemy-compatible fallback
            connection.execute(
                text(
                    """
                    ALTER TABLE transaction_logs
                    ADD COLUMN user_id INTEGER
                    """
                )
            )


migrate_transaction_logs()


# ============================================================
# APP
# ============================================================

app = FastAPI(
    title="Fraud Detection API",
    version="2.0.0",
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# MODEL
# ============================================================

MODEL_PATH = "models/fraud_model.pkl"

try:
    model = joblib.load(MODEL_PATH)
except Exception as e:
    raise RuntimeError(
        f"Could not load fraud model from {MODEL_PATH}: {e}"
    )


# ============================================================
# SCHEMAS
# ============================================================


class Transaction(BaseModel):
    amount: float = Field(
        gt=0,
        le=10_000_000,
    )

    hour_of_day: float = Field(
        ge=0,
        le=23,
    )

    transactions_last_hour: int = Field(
        ge=0,
        le=1000,
    )

    # EXACTLY 0 OR 1
    is_new_device: int = Field(
        ge=0,
        le=1,
    )

    account_age_days: float = Field(
        ge=0,
        le=36500,
    )


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(
        min_length=6,
        max_length=128,
    )


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr

    code: str = Field(
        min_length=6,
        max_length=6,
    )

    new_password: str = Field(
        min_length=6,
        max_length=128,
    )


# ============================================================
# PUBLIC
# ============================================================


@app.get("/")
def home():
    return {
        "message": "Fraud Detection API is running",
        "version": "2.0.0",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "model_loaded": model is not None,
    }


# ============================================================
# REGISTER
# ============================================================


@app.post("/register")
def register(
    payload: RegisterRequest,
    db: Session = Depends(get_db),
):
    existing = (
        db.query(User)
        .filter(User.email == payload.email)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Email already registered",
        )

    user = User(
        email=payload.email,
        hashed_password=hash_password(
            payload.password
        ),
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return {
        "message": "Account created successfully",
        "email": user.email,
    }


# ============================================================
# LOGIN
# ============================================================


@app.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = (
        db.query(User)
        .filter(User.email == form_data.username)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password",
        )

    if not verify_password(
        form_data.password,
        user.hashed_password,
    ):
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password",
        )

    token = create_access_token(
        data={
            "sub": user.email,
            "user_id": user.id,
        }
    )

    return {
        "access_token": token,
        "token_type": "bearer",
    }


# ============================================================
# FORGOT PASSWORD
# ============================================================


@app.post("/forgot-password")
def forgot_password(
    payload: ForgotPasswordRequest,
    db: Session = Depends(get_db),
):
    user = (
        db.query(User)
        .filter(User.email == payload.email)
        .first()
    )

    if not user:
        return {
            "message": (
                "If that email exists, "
                "a reset code has been sent"
            )
        }

    code = str(
        random.randint(
            100000,
            999999,
        )
    )

    reset_entry = PasswordResetCode(
        email=payload.email,
        code=code,
        expires_at=(
            datetime.utcnow()
            + timedelta(minutes=15)
        ),
    )

    db.add(reset_entry)
    db.commit()

    try:
        send_reset_code_email(
            payload.email,
            code,
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send email: {str(e)}",
        )

    return {
        "message": (
            "If that email exists, "
            "a reset code has been sent"
        )
    }


# ============================================================
# RESET PASSWORD
# ============================================================


@app.post("/reset-password")
def reset_password(
    payload: ResetPasswordRequest,
    db: Session = Depends(get_db),
):
    reset_entry = (
        db.query(PasswordResetCode)
        .filter(
            PasswordResetCode.email
            == payload.email,

            PasswordResetCode.code
            == payload.code,

            PasswordResetCode.used == False,
        )
        .order_by(
            PasswordResetCode.id.desc()
        )
        .first()
    )

    if not reset_entry:
        raise HTTPException(
            status_code=400,
            detail="Invalid or already-used code",
        )

    if reset_entry.expires_at < datetime.utcnow():
        raise HTTPException(
            status_code=400,
            detail="Code has expired",
        )

    user = (
        db.query(User)
        .filter(User.email == payload.email)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )

    user.hashed_password = hash_password(
        payload.new_password
    )

    reset_entry.used = True

    db.commit()

    return {
        "message": "Password reset successfully"
    }


# ============================================================
# CHECK TRANSACTION
# ============================================================


@app.post("/check-transaction")
def check_transaction(
    transaction: Transaction,
    db: Session = Depends(get_db),

    # JWT AUTHENTICATION
    current_user: User = Depends(
        get_current_user
    ),
):
    """
    Check a transaction and save it under
    the currently logged-in user.
    """

    # --------------------------------------------------------
    # MODEL INPUT
    # --------------------------------------------------------

    transaction_data = {
        "amount": transaction.amount,
        "hour_of_day": transaction.hour_of_day,
        "transactions_last_hour":
            transaction.transactions_last_hour,
        "is_new_device":
            transaction.is_new_device,
        "account_age_days":
            transaction.account_age_days,
    }

    df = pd.DataFrame([transaction_data])

    # --------------------------------------------------------
    # PREDICTION
    # --------------------------------------------------------

    fraud_probability = float(
        model.predict_proba(df)[0][1]
    )

    is_fraud = bool(
        model.predict(df)[0]
    )

    # --------------------------------------------------------
    # RISK
    # --------------------------------------------------------

    if fraud_probability >= 0.80:
        risk_level = "CRITICAL"

    elif fraud_probability >= 0.60:
        risk_level = "HIGH"

    elif fraud_probability >= 0.30:
        risk_level = "MEDIUM"

    else:
        risk_level = "LOW"

    # --------------------------------------------------------
    # SAVE USER-OWNED HISTORY
    # --------------------------------------------------------

    log_entry = TransactionLog(
        # THIS IS THE IMPORTANT PART
        user_id=current_user.id,

        amount=transaction.amount,
        hour_of_day=transaction.hour_of_day,
        transactions_last_hour=(
            transaction.transactions_last_hour
        ),
        is_new_device=transaction.is_new_device,
        account_age_days=transaction.account_age_days,

        is_fraud=is_fraud,

        fraud_probability=round(
            fraud_probability,
            4,
        ),

        risk_level=risk_level,
    )

    db.add(log_entry)
    db.commit()
    db.refresh(log_entry)

    # --------------------------------------------------------
    # RESPONSE
    # --------------------------------------------------------

    return {
        "id": log_entry.id,

        "is_fraud": is_fraud,

        "fraud_probability": round(
            fraud_probability,
            4,
        ),

        "risk_level": risk_level,

        "message": (
            "Transaction analyzed successfully"
        ),
    }


# ============================================================
# USER HISTORY
# ============================================================


@app.get("/history")
def get_history(
    limit: int = 20,

    db: Session = Depends(get_db),

    current_user: User = Depends(
        get_current_user
    ),
):
    """
    IMPORTANT:

    Only return transactions belonging to
    the currently authenticated user.
    """

    # Prevent unreasonable values
    limit = max(
        1,
        min(limit, 100),
    )

    logs = (
        db.query(TransactionLog)
        .filter(
            TransactionLog.user_id
            == current_user.id
        )
        .order_by(
            TransactionLog.id.desc()
        )
        .limit(limit)
        .all()
    )

    return logs


# ============================================================
# STATS
# ============================================================


@app.get("/stats")
def get_stats(
    db: Session = Depends(get_db),

    current_user: User = Depends(
        get_current_user
    ),
):
    """
    Stats are also scoped to the logged-in user.

    This prevents one user from seeing another
    user's transaction statistics.
    """

    base_query = (
        db.query(TransactionLog)
        .filter(
            TransactionLog.user_id
            == current_user.id
        )
    )

    total = base_query.count()

    fraud_count = (
        base_query
        .filter(
            TransactionLog.is_fraud == True
        )
        .count()
    )

    fraud_rate = (
        fraud_count / total
        if total > 0
        else 0
    )

    return {
        "total_checked": total,

        "fraud_detected": fraud_count,

        "fraud_rate": round(
            fraud_rate,
            4,
        ),
    }
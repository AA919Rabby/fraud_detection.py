from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
import joblib
import pandas as pd
from fastapi.middleware.cors import CORSMiddleware
from src.database import engine, get_db, Base
from src.models_db import TransactionLog

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Fraud Detection API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allows requests from any website (fine for a portfolio project)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = joblib.load("models/fraud_model.pkl")

class Transaction(BaseModel):
    amount: float
    hour_of_day: float
    transactions_last_hour: int
    is_new_device: int
    account_age_days: float

@app.get("/")
def home():
    return {"message": "Fraud Detection API is running"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.post("/check-transaction")
def check_transaction(transaction: Transaction, db: Session = Depends(get_db)):
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
        risk_level=risk_level
    )
    db.add(log_entry)
    db.commit()
    db.refresh(log_entry)

    return {
        "id": log_entry.id,
        "is_fraud": is_fraud,
        "fraud_probability": round(fraud_probability, 4),
        "risk_level": risk_level
    }

@app.get("/history")
def get_history(limit: int = 20, db: Session = Depends(get_db)):
    logs = db.query(TransactionLog).order_by(TransactionLog.id.desc()).limit(limit).all()
    return logs

@app.get("/stats")
def get_stats(db: Session = Depends(get_db)):
    total = db.query(TransactionLog).count()
    fraud_count = db.query(TransactionLog).filter(TransactionLog.is_fraud == True).count()
    return {
        "total_checked": total,
        "fraud_detected": fraud_count,
        "fraud_rate": round(fraud_count / total, 4) if total > 0 else 0
    }
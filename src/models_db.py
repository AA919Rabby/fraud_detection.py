from sqlalchemy import Column, Integer, Float, Boolean, String, DateTime
from sqlalchemy.sql import func
from src.database import Base

class TransactionLog(Base):
    __tablename__ = "transaction_logs"

    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Float)
    hour_of_day = Column(Float)
    transactions_last_hour = Column(Integer)
    is_new_device = Column(Integer)
    account_age_days = Column(Float)
    is_fraud = Column(Boolean)
    fraud_probability = Column(Float)
    risk_level = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, index=True, nullable=False)
    code = Column(String, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    used = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
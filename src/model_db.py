from sqlalchemy import Column,Integer,Float,Boolean,String,DateTime
from sqlalchemy.sql import func
from src.database import Base

class TransactionLog(Base):
    __tablename__="transaction_log"
    id=Column(Integer,primary_key=True,index=True)
    amount=Column(Float)
    hour_of_day=Column(Integer)
    is_new_device=Column(Integer)
    account_age=Column(Float)
    is_fraud=Column(Boolean)
    fraud_probability=Column(Float)
    risk_level=Column(String)
    created_at=Column(DateTime(timezone=True),server_default=func.now())


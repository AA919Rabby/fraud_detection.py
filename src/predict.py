import joblib
import pandas as pd

def predict_fraud(transaction: dict):
    model=joblib.load("models/fraud_model.pkl")
    df=pd.DataFrame([transaction])
    fraud_probability=model.predict_proba(df)[0][1]
    is_fraud=bool(model.predict(df)[0])
    return {
        "is_fraud": is_fraud,
        "fraud_probability": round(float(fraud_probability), 4)
    }

if __name__ == "__main__":
    suspicious_transaction = {
        "amount": 15000,
        "hour_of_day": 3,
        "transactions_last_hour": 6,
        "is_new_device": 1,
        "account_age_days": 15
    }
    result = predict_fraud(suspicious_transaction)
    print(f"Prediction: {result}")
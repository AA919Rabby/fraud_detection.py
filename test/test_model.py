import joblib
import pandas as pd

def test_model_loads():
    model = joblib.load("models/fraud_model.pkl")
    assert model is not None

def test_flags_obvious_fraud():
    model = joblib.load("models/fraud_model.pkl")
    obvious_fraud = pd.DataFrame([{
        "amount": 50000, "hour_of_day": 3, "transactions_last_hour": 10,
        "is_new_device": 1, "account_age_days": 5
    }])
    prediction = model.predict(obvious_fraud)[0]
    assert prediction == 1  # should flag as fraud
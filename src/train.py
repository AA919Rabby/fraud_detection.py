import pandas as pd
import numpy as np
import json
import joblib
import os
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    precision_score, recall_score, f1_score,
    roc_auc_score, confusion_matrix, classification_report
)
from imblearn.over_sampling import SMOTE

# ### EDIT 1: Increased n_samples to 50000 to ensure we have enough data
# to train the model with a realistic, highly-imbalanced fraud rate.
def generate_realistic_fraud_data(n_samples=50000):
    """
    Simulates mobile financial transactions.
    Patterns grounded in documented fraud research:
    - Fraudulent transactions tend toward higher dollar value (PaySim dataset findings)
    - SIM-swap/account-takeover fraud often shows: a new/unrecognized device,
      followed by one or few large transactions draining the account,
      on a relatively young or recently-compromised account
    """
    np.random.seed(42)

    # ### EDIT 2: Adjusted to world statistics.
    # The global average for digital transaction fraud is roughly 0.1% to 0.5%.
    # We are using 0.5% (0.005) to represent realistic global financial data.
    n_fraud = int(n_samples * 0.005)
    n_normal = n_samples - n_fraud

    normal = pd.DataFrame({
        "amount": np.random.lognormal(mean=6.0, sigma=1.0, size=n_normal).clip(10, 20000),
        "hour_of_day": np.random.normal(14, 5, n_normal).clip(0, 23),
        "transactions_last_hour": np.random.poisson(1, n_normal),
        "is_new_device": np.random.binomial(1, 0.05, n_normal),
        "account_age_days": np.random.gamma(5, 100, n_normal).clip(1, 7300),
        "is_fraud": 0
    })

    fraud = pd.DataFrame({
        "amount": np.random.lognormal(mean=9.5, sigma=1.2, size=n_fraud).clip(2000, 200000),
        "hour_of_day": np.random.normal(3, 3, n_fraud).clip(0, 23),
        "transactions_last_hour": np.random.poisson(2, n_fraud),
        "is_new_device": np.random.binomial(1, 0.75, n_fraud),
        "account_age_days": np.random.gamma(2, 40, n_fraud).clip(1, 3650),
        "is_fraud": 1
    })

    df = pd.concat([normal, fraud], ignore_index=True)
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)
    return df

def train_fraud_model():
    df = generate_realistic_fraud_data()
    os.makedirs("data", exist_ok=True)
    df.to_csv("data/transactions.csv", index=False)

    X = df.drop(columns=["is_fraud"])
    y = df["is_fraud"]

    print(f"Total transactions generated: {len(df)}")
    print(f"Fraud cases (World Stat Baseline): {y.sum()} ({y.mean()*100:.2f}%)")

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    smote = SMOTE(random_state=42)
    X_train_balanced, y_train_balanced = smote.fit_resample(X_train, y_train)

    model = RandomForestClassifier(n_estimators=200, random_state=42, max_depth=10)
    model.fit(X_train_balanced, y_train_balanced)

    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)[:, 1]

    metrics = {
        "precision": round(precision_score(y_test, y_pred), 4),
        "recall": round(recall_score(y_test, y_pred), 4),
        "f1_score": round(f1_score(y_test, y_pred), 4),
        "auroc": round(roc_auc_score(y_test, y_proba), 4),
    }

    print("\nTraining complete. Metrics:")
    print(json.dumps(metrics, indent=2))
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=["Not Fraud", "Fraud"]))

    os.makedirs("models", exist_ok=True)
    joblib.dump(model, "models/fraud_model.pkl")
    with open("models/metrics.json", "w") as f:
        json.dump(metrics, f, indent=2)
    print("\nModel saved successfully to models/fraud_model.pkl")

# ### EDIT 3: Separated the prediction function properly so it doesn't cause a Syntax Error.
def predict_fraud(transaction: dict):
    # Ensure the model exists before trying to load it
    if not os.path.exists("models/fraud_model.pkl"):
        print("Model not found! Training model first...")
        train_fraud_model()

    model = joblib.load("models/fraud_model.pkl")
    df = pd.DataFrame([transaction])
    fraud_probability = model.predict_proba(df)[0][1]
    is_fraud = bool(model.predict(df)[0])

    return {
        "is_fraud": is_fraud,
        "fraud_probability": round(float(fraud_probability), 4)
    }

# ### EDIT 4: Fixed the execution block to run training first, then test a prediction.
if __name__ == "__main__":
    # 1. Train the model
    print("--- STARTING MODEL TRAINING ---")
    train_fraud_model()

    # 2. Test a prediction
    print("\n--- TESTING PREDICTION ---")
    suspicious_transaction = {
        "amount": 15000,
        "hour_of_day": 3,
        "transactions_last_hour": 6,
        "is_new_device": 1,
        "account_age_days": 15
    }
    result = predict_fraud(suspicious_transaction)
    print(f"Prediction result for suspicious transaction: {result}")
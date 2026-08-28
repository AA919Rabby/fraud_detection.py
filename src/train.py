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

def generate_realistic_fraud_data(n_samples=10000):
    """Simulates mobile financial transaction data (like bKash/Nagad)."""
    np.random.seed(42)

    # Normal transactions (majority)
    n_fraud = int(n_samples * 0.02)  # only 2% are fraud - REALISTIC imbalance
    n_normal = n_samples - n_fraud

    normal = pd.DataFrame({
        "amount": np.random.gamma(2, 500, n_normal),          # typical transaction sizes
        "hour_of_day": np.random.normal(14, 5, n_normal).clip(0, 23),
        "transactions_last_hour": np.random.poisson(1, n_normal),
        "is_new_device": np.random.binomial(1, 0.05, n_normal),
        "account_age_days": np.random.gamma(5, 100, n_normal),
        "is_fraud": 0
    })

    # Fraudulent transactions (minority) - different patterns
    fraud = pd.DataFrame({
        "amount": np.random.gamma(5, 2000, n_fraud),           # unusually large amounts
        "hour_of_day": np.random.normal(3, 3, n_fraud).clip(0, 23),  # odd hours (late night)
        "transactions_last_hour": np.random.poisson(8, n_fraud),     # rapid transactions
        "is_new_device": np.random.binomial(1, 0.7, n_fraud),        # often new/unrecognized device
        "account_age_days": np.random.gamma(1, 20, n_fraud),         # newer accounts
        "is_fraud": 1
    })

    df = pd.concat([normal, fraud], ignore_index=True)
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)  # shuffle
    return df

def train_fraud_model():
    df = generate_realistic_fraud_data()

    os.makedirs("data", exist_ok=True)
    df.to_csv("data/transactions.csv", index=False)

    X = df.drop(columns=["is_fraud"])
    y = df["is_fraud"]

    print(f"Total transactions: {len(df)}")
    print(f"Fraud cases: {y.sum()} ({y.mean()*100:.2f}%)")

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y  # stratify keeps fraud ratio balanced in split
    )

    # Handle imbalance: SMOTE creates synthetic fraud examples so model doesn't ignore them
    smote = SMOTE(random_state=42)
    X_train_balanced, y_train_balanced = smote.fit_resample(X_train, y_train)

    print(f"After SMOTE - training fraud cases: {y_train_balanced.sum()} / {len(y_train_balanced)}")

    # Train model
    model = RandomForestClassifier(n_estimators=200, random_state=42, max_depth=10)
    model.fit(X_train_balanced, y_train_balanced)

    # Predictions
    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)[:, 1]  # probability of fraud (needed for AUROC)

    # THE KEY METRICS for fraud detection
    precision = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)
    auroc = roc_auc_score(y_test, y_proba)
    cm = confusion_matrix(y_test, y_pred)

    metrics = {
        "precision": round(precision, 4),
        "recall": round(recall, 4),
        "f1_score": round(f1, 4),
        "auroc": round(auroc, 4),
        "confusion_matrix": {
            "true_negative": int(cm[0][0]),
            "false_positive": int(cm[0][1]),
            "false_negative": int(cm[1][0]),
            "true_positive": int(cm[1][1])
        }
    }

    print("\nTraining complete. Metrics:")
    print(json.dumps(metrics, indent=2))
    print("\n" + classification_report(y_test, y_pred, target_names=["Not Fraud", "Fraud"]))

    os.makedirs("models", exist_ok=True)
    joblib.dump(model, "models/fraud_model.pkl")
    with open("models/metrics.json", "w") as f:
        json.dump(metrics, f, indent=2)

    print("Model saved to models/fraud_model.pkl")
    return model, metrics

if __name__ == "__main__":
    train_fraud_model()
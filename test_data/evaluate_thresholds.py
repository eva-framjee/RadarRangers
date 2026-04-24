import numpy as np
import pandas as pd
import joblib
from sklearn.metrics import confusion_matrix
import glob
import os

MODEL_PATH = "rf_model_safety.pkl"

NORMAL_DIR = r"C:\Users\class\OneDrive\Desktop\Archive\ECEN 403\Radar_Parsing_Code\test_data\realistic_cases\normal"
EMERGENCY_DIR = r"C:\Users\class\OneDrive\Desktop\Archive\ECEN 403\Radar_Parsing_Code\test_data\realistic_cases\emergency"


# From Training
def add_features(df):

    df = df.copy()

    df["hr_slope"] = df["heart_rate_bpm"].diff().fillna(0)
    df["br_slope"] = df["breathing_rate_bpm"].diff().fillna(0)

    df["hr_avg5"] = df["heart_rate_bpm"].rolling(5).mean().bfill()
    df["br_avg5"] = df["breathing_rate_bpm"].rolling(5).mean().bfill()

    df["hr_avg10"] = df["heart_rate_bpm"].rolling(10).mean().bfill()
    df["br_avg10"] = df["breathing_rate_bpm"].rolling(10).mean().bfill()

    df["hr_std5"] = df["heart_rate_bpm"].rolling(5).std().fillna(0)
    df["br_std5"] = df["breathing_rate_bpm"].rolling(5).std().fillna(0)

    df["hr_jitter"] = (df["heart_rate_bpm"] - df["hr_avg5"]).abs()
    df["br_jitter"] = (df["breathing_rate_bpm"] - df["br_avg5"]).abs()

    return df


# Load data
def load_all():
    rows = []

    normals = sorted(glob.glob(os.path.join(NORMAL_DIR, "*.csv")))
    emergencies = sorted(glob.glob(os.path.join(EMERGENCY_DIR, "*.csv")))

    for p in normals:
        df = pd.read_csv(p)
        df = df[(df.presence_flag == 1) &
                (df.heart_rate_bpm != 0) &
                (df.breathing_rate_bpm != 0)]
        df["label"] = 0
        rows.append(df)

    for p in emergencies:
        df = pd.read_csv(p)
        df = df[(df.presence_flag == 1) &
                (df.heart_rate_bpm != 0) &
                (df.breathing_rate_bpm != 0)]
        df["label"] = 1
        rows.append(df)

    df = pd.concat(rows, ignore_index=True)
    df = add_features(df)
    return df

# Evaluate thresholds
def evaluate_thresholds():

    print("Loading trained model...")
    packed = joblib.load(MODEL_PATH)
    model = packed["model"]
    features = packed["features"]

    print("Loading evaluation dataset...")
    df = load_all()

    X = df[features].values
    y_true = df["label"].values

    print("Computing probabilities...")
    proba = model.predict_proba(X)[:, 1]

    thresholds = np.linspace(0.01, 0.60, 30)

    print("\nTHRESHOLD | FN_RATE | FP_RATE | TOTAL_FN | TOTAL_FP")
    print("-" * 60)

    for T in thresholds:
        y_pred = (proba >= T).astype(int)
        cm = confusion_matrix(y_true, y_pred)

        TN, FP, FN, TP = cm.ravel()

        FN_rate = FN / (FN + TP)
        FP_rate = FP / (FP + TN)

        print(f"{T:.2f}       {FN_rate:.4f}    {FP_rate:.4f}    {FN}        {FP}")

    print("\nDone. Choose the threshold with TOTAL_FN = 0.")

if __name__ == "__main__":
    evaluate_thresholds()

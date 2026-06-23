from fastapi import FastAPI
from pathlib import Path
from typing import List, Dict, Any, Optional
import os
import pandas as pd
import boto3
from botocore.exceptions import ClientError

from src.inference_pipeline.inference import predict
from src.batch.run_monthly import run_monthly_predictions

# ----------------------------
# Config
# ----------------------------
S3_BUCKET = os.getenv("S3_BUCKET", "housing-regression-data-mlops")
REGION = os.getenv("AWS_REGION", "ap-southeast-1")
s3 = boto3.client("s3", region_name=REGION)

APP_VERSION = "2026-04-14-safe-s3-startup-v1"

MODEL_KEY = "models/xgb_best_model.pkl"
TRAIN_FE_KEY = "processed/feature_engineered_train.csv"

MODEL_PATH = Path("models/xgb_best_model.pkl")
TRAIN_FE_PATH = Path("data/processed/feature_engineered_train.csv")

TRAIN_FEATURE_COLUMNS: Optional[List[str]] = None

app = FastAPI(title="Housing Regression API")


def load_from_s3_safe(key: str, local_path: Path) -> Optional[Path]:
    """
    Download from S3 if file doesn't exist.
    NEVER raise exception to kill app.
    """
    try:
        if not local_path.exists():
            local_path.parent.mkdir(parents=True, exist_ok=True)
            print(f"[{APP_VERSION}] Downloading s3://{S3_BUCKET}/{key} -> {local_path}")
            s3.download_file(S3_BUCKET, key, str(local_path))
        return local_path if local_path.exists() else None
    except ClientError as e:
        print(f"[{APP_VERSION}] S3 ClientError for {key}: {e}")
        return None
    except Exception as e:
        print(f"[{APP_VERSION}] Unexpected error for {key}: {e}")
        return None


@app.on_event("startup")
def startup_event():
    """
    Startup must not crash.
    Try loading artifacts; if failed, app stays up in degraded mode.
    """
    global TRAIN_FEATURE_COLUMNS

    print(f"[{APP_VERSION}] Startup begin")
    model_local = load_from_s3_safe(MODEL_KEY, MODEL_PATH)
    train_local = load_from_s3_safe(TRAIN_FE_KEY, TRAIN_FE_PATH)

    if train_local and train_local.exists():
        try:
            cols = pd.read_csv(train_local, nrows=1).columns.tolist()
            TRAIN_FEATURE_COLUMNS = [c for c in cols if c != "price"]
        except Exception as e:
            print(f"[{APP_VERSION}] Failed to parse training columns: {e}")
            TRAIN_FEATURE_COLUMNS = None

    print(f"[{APP_VERSION}] Startup done. model_exists={bool(model_local and model_local.exists())}")


@app.get("/")
def root():
    return {"message": "Housing Regression API is running 🚀", "version": APP_VERSION}


@app.get("/health")
def health():
    status: Dict[str, Any] = {
        "status": "healthy" if MODEL_PATH.exists() else "degraded",
        "version": APP_VERSION,
        "model_exists": MODEL_PATH.exists(),
        "model_path": str(MODEL_PATH),
        "train_features_exists": TRAIN_FE_PATH.exists(),
    }
    if TRAIN_FEATURE_COLUMNS:
        status["n_features_expected"] = len(TRAIN_FEATURE_COLUMNS)
    return status


@app.post("/predict")
def predict_batch(data: List[dict]):
    # Lazy-load model at request time if missing
    if not MODEL_PATH.exists():
        model_local = load_from_s3_safe(MODEL_KEY, MODEL_PATH)
        if not model_local:
            return {"error": "Model unavailable from S3 (403/NoSuchKey/KMS/bucket-policy)."}

    df = pd.DataFrame(data)
    if df.empty:
        return {"error": "No data provided"}

    preds_df = predict(df, model_path=MODEL_PATH, expected_columns=TRAIN_FEATURE_COLUMNS)

    resp = {"predictions": preds_df["predicted_price"].astype(float).tolist()}
    if "actual_price" in preds_df.columns:
        resp["actuals"] = preds_df["actual_price"].astype(float).tolist()
    return resp


@app.post("/run_batch")
def run_batch():
    preds = run_monthly_predictions()
    return {
        "status": "success",
        "rows_predicted": int(len(preds)),
        "output_dir": "data/predictions/"
    }


@app.get("/latest_predictions")
def latest_predictions(limit: int = 5):
    pred_dir = Path("data/predictions")
    files = sorted(pred_dir.glob("preds_*.csv"))
    if not files:
        return {"error": "No predictions found"}

    latest_file = files[-1]
    df = pd.read_csv(latest_file)
    return {
        "file": latest_file.name,
        "rows": int(len(df)),
        "preview": df.head(limit).to_dict(orient="records")
    }
"""
🔹 Execution Order / Module Flow

1. Imports (FastAPI, pandas, boto3, your inference function).
2. Config setup (env vars → bucket/region).
3. S3 utility (load_from_s3).
4. Download + load model/artifacts (MODEL_PATH, TRAIN_FE_PATH).
5. Infer schema (TRAIN_FEATURE_COLUMNS).
6. Create FastAPI app (app = FastAPI).
7. Declare endpoints (/, /health, /predict, /run_batch, /latest_predictions).
"""
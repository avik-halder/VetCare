# app.py — FastAPI backend with RandomForest SHAP explanations
from fastapi import FastAPI, File, UploadFile, Query
from fastapi.responses import StreamingResponse, HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from ultralytics import YOLO
from tensorflow.keras.models import load_model
from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime, timedelta
from lime.lime_tabular import LimeTabularExplainer
import pymongo
import numpy as np
import joblib
import cv2
import threading
import hashlib
import os
import sys
import time
import pandas as pd
import shap  # NEW for XAI


import base64
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input


print("Python version:", sys.version)

app = FastAPI()

# -------------------------------------------------------------------------
# CORS
# -------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------------------------------------------------------
# MongoDB
# -------------------------------------------------------------------------
client = MongoClient(
    "mongodb+srv://avik:avik1234@cluster0.yrfckol.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
)
db = client["VetCare"]
skin_collection = db["Skin"]
sensor_collection = db["SensorData"]
users = db["Users"]
users.create_index("email", unique=True)

# -------------------------------------------------------------------------
# Simple auth
# -------------------------------------------------------------------------
SALT = os.getenv("PWD_SALT", "dev_salt_change_me")

def _hash(pw: str) -> str:
    return hashlib.sha256((pw + SALT).encode("utf-8")).hexdigest()

class RegisterBody(BaseModel):
    name: str
    email: EmailStr
    password: str

class LoginBody(BaseModel):
    email: EmailStr
    password: str

@app.post("/auth/register")
def register_user(body: RegisterBody):
    if users.find_one({"email": body.email.lower()}):
        return {"ok": False, "error": "Email already registered"}
    users.insert_one({
        "name": body.name.strip(),
        "email": body.email.lower(),
        "password_hash": _hash(body.password),
        "created_at": datetime.utcnow(),
    })
    return {"ok": True}

@app.post("/auth/login")
def login_user(body: LoginBody):
    u = users.find_one({"email": body.email.lower()})
    if not u or u.get("password_hash") != _hash(body.password):
        return JSONResponse(status_code=401, content={"ok": False, "error": "Invalid credentials"})
    return {"ok": True}

# -------------------------------------------------------------------------
# ML models & shared state
# -------------------------------------------------------------------------
yolo_model = YOLO("yolo11n.pt")
lumpy_model = load_model("lumpy_model.h5")

# RandomForest pipeline
random_forest_model = joblib.load("random_forest_model.pkl")
scaler = joblib.load("scaler.pkl")
le = joblib.load("label_encoder.pkl")
feature_order = joblib.load("feature_order.pkl")  # NEW: load feature order
explainer = shap.TreeExplainer(random_forest_model)  # NEW: SHAP explainer
class_baselines = joblib.load("class_baselines.pkl")


# app.py (after loading model/scaler/encoder/feature_order/SHAP):contentReference[oaicite:3]{index=3}
try:
    _df_bg = pd.read_csv("Cattle_Disease_Dataset_final one.csv")
    _df_bg["Accel_Magnitude"] = (_df_bg["Accel_X"]**2 + _df_bg["Accel_Y"]**2 + _df_bg["Accel_Z"]**2) ** 0.5
    _df_bg["Gyro_Magnitude"]  = (_df_bg["Gyro_X"]**2 + _df_bg["Gyro_Y"]**2 + _df_bg["Gyro_Z"]**2) ** 0.5
    _X_bg_df = _df_bg[feature_order].copy()
    _X_bg_scaled = scaler.transform(_X_bg_df)

    lime_explainer = LimeTabularExplainer(
        training_data=_X_bg_scaled,
        feature_names=feature_order,
        class_names=list(le.classes_),
        mode="classification",
        discretize_continuous=True
    )
except Exception as e:
    lime_explainer = None
    print("LIME init failed:", e, flush=True)


# Shared video frame
latest_frame = None
lock = threading.Lock()

last_insert_time = datetime.min

# -------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------
def serialize_doc(doc):
    doc["_id"] = str(doc["_id"])
    if "timestamp" in doc and hasattr(doc["timestamp"], "isoformat"):
        doc["timestamp"] = doc["timestamp"].isoformat()
    return doc

# -------------------------------------------------------------------------
# Routes
# -------------------------------------------------------------------------
@app.get("/")
def index():
    return HTMLResponse("""
        <h2>Live Cow Detection</h2>
        <img src="/video_feed" width="800">
    """)

@app.post("/upload-frame")
async def upload_frame(file: UploadFile = File(...)):
    global latest_frame, last_insert_time

    contents = await file.read()
    np_arr = np.frombuffer(contents, np.uint8)
    frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    if frame is None:
        return JSONResponse(status_code=400, content={"error": "Could not decode frame; corrupted or unsupported image data."})

    results = yolo_model.predict(source=frame, conf=0.3, verbose=False)

    for r in results:
        for box in r.boxes:
            cls_id = int(box.cls[0])
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            label = yolo_model.names[cls_id]

            if label == "cow":
                crop = frame[y1:y2, x1:x2]
                if crop.size == 0:
                    continue
                resized = cv2.resize(crop, (224, 224))
                img_arr = resized.astype("float32") / 255.0
                img_arr = np.expand_dims(img_arr, axis=0)

                prediction = lumpy_model.predict(img_arr, verbose=0)[0][0]
                label = "lumpy skin cow" if prediction > 0.5 else "normal cow"

                now = datetime.now()
                if (now - last_insert_time) > timedelta(minutes=1):
                    skin_collection.insert_one({
                        "timestamp": now,
                        "result": label
                    })
                    last_insert_time = now

            font = cv2.FONT_HERSHEY_SIMPLEX
            font_scale = 0.6
            thickness = 2
            box_color = (255, 0, 0) if "cow" in label else (100, 255, 100)
            text_color = (255, 255, 255)

            (tw, th), _ = cv2.getTextSize(label, font, font_scale, thickness)
            cv2.rectangle(frame, (x1, y1 - th - 10), (x1 + tw + 4, y1), box_color, -1)
            cv2.putText(frame, label, (x1 + 2, y1 - 5), font, font_scale, text_color, thickness)
            cv2.rectangle(frame, (x1, y1), (x2, y2), box_color, 2)

    with lock:
        latest_frame = frame.copy()

    return {"status": "Frame received and processed"}

@app.get("/video_feed")
def video_feed():
    def stream():
        while True:
            if latest_frame is not None:
                with lock:
                    _, buffer = cv2.imencode(".jpg", latest_frame)
                yield (b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' +
                       buffer.tobytes() + b'\r\n')
            time.sleep(0.05)
    return StreamingResponse(stream(), media_type="multipart/x-mixed-replace; boundary=frame")

@app.get("/logs")
def get_logs():
    logs = list(skin_collection.find().sort("timestamp", pymongo.DESCENDING).limit(50))
    return JSONResponse(content=[serialize_doc(doc) for doc in logs])

@app.get("/skin-latest")
def skin_latest():
    try:
        latest_skin_doc = skin_collection.find_one(sort=[("timestamp", pymongo.DESCENDING)])
        if not latest_skin_doc:
            return {"error": "No skin prediction data found."}
        return {
            "result": latest_skin_doc["result"],
            "timestamp": latest_skin_doc["timestamp"].isoformat()
        }
    except Exception as e:
        return {"error": str(e)}

@app.post("/store-sensor")
async def store_sensor(data: dict):
    try:
        accel_mag = (data["Accel_X"]**2 + data["Accel_Y"]**2 + data["Accel_Z"]**2) ** 0.5
        gyro_mag = (data["Gyro_X"]**2 + data["Gyro_Y"]**2 + data["Gyro_Z"]**2) ** 0.5

        data_to_store = {
            "timestamp": datetime.now(),
            "Temp": data["Temp"],
            "MQ": data["MQ"],
            "Accel_X": data["Accel_X"],
            "Accel_Y": data["Accel_Y"],
            "Accel_Z": data["Accel_Z"],
            "Gyro_X": data["Gyro_X"],
            "Gyro_Y": data["Gyro_Y"],
            "Gyro_Z": data["Gyro_Z"],
            "pH": data["pH"],
            "Pulse": data["Pulse"],
            "Accel_Mag": accel_mag,
            "Gyro_Mag": gyro_mag
        }

        sensor_collection.insert_one(data_to_store)
        return {"status": "Sensor data stored successfully"}
    except Exception as e:
        return {"error": str(e)}

@app.get("/sensor-latest")
def get_latest_sensor_data():
    try:
        latest_docs = list(sensor_collection.find().sort("timestamp", pymongo.DESCENDING).limit(10))
        result = []
        for doc in latest_docs:
            doc["_id"] = str(doc["_id"])
            if "timestamp" in doc and hasattr(doc["timestamp"], "isoformat"):
                doc["timestamp"] = doc["timestamp"].isoformat()
            result.append(doc)
        return JSONResponse(content=result)
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

# -------------------------------------------------------------------------
# UPDATED: /predict-latest with SHAP explanation
# -------------------------------------------------------------------------

@app.get("/predict-latest")
def predict_latest(
    explain: bool = Query(default=False),
    k: int = Query(default=3, ge=1, le=12)
):
    """
    Returns the latest sensor prediction from RandomForest.
    If explain=true, also returns top-k contributing features with hints
    computed against the *predicted class* baseline (means/std).
    """

    # Friendly names for UI
    DISPLAY_NAME = {
        "Temperature_C": "Temperature",
        "Pulse_BPM": "Pulse",
        "Accel_X": "Accel X",
        "Accel_Y": "Accel Y",
        "Accel_Z": "Accel Z",
        "Gyro_X": "Gyro X",
        "Gyro_Y": "Gyro Y",
        "Gyro_Z": "Gyro Z",
        "MQ_Gas": "MQ gas level",
        "Saliva_pH": "Saliva pH",
        "Accel_Magnitude": "Accel magnitude",
        "Gyro_Magnitude": "Gyro magnitude",
    }

    def hint_against_class(feature: str, value: float, cls_label: str) -> str:
        """
        Compare raw value to (predicted) class mean/std and return a short hint.
        Bands: ±0.5σ (slight), ±1.5σ (strong).
        """
        base = class_baselines.get(cls_label) or {}
        mu = (base.get("mean") or {}).get(feature, None)
        sd = (base.get("std") or {}).get(feature, None)
        if mu is None or sd is None or sd == 0 or np.isnan(sd):
            return "no baseline"
        z = (value - mu) / sd
        if z < -1.5: return "low"
        if z < -0.5: return "slightly low"
        if z >  1.5: return "high"
        if z >  0.5: return "slightly high"
        return "normal"

    try:
        latest_doc = sensor_collection.find_one(sort=[("timestamp", pymongo.DESCENDING)])
        if not latest_doc:
            return {"error": "No sensor data found."}

        # Map Mongo -> training feature names (your schema):contentReference[oaicite:3]{index=3}
        row_map = {
            "Temperature_C":   latest_doc["Temp"],
            "Pulse_BPM":       latest_doc["Pulse"],
            "Accel_X":         latest_doc["Accel_X"],
            "Accel_Y":         latest_doc["Accel_Y"],
            "Accel_Z":         latest_doc["Accel_Z"],
            "Gyro_X":          latest_doc["Gyro_X"],
            "Gyro_Y":          latest_doc["Gyro_Y"],
            "Gyro_Z":          latest_doc["Gyro_Z"],
            "MQ_Gas":          latest_doc["MQ"],
            "Saliva_pH":       latest_doc["pH"],
            "Accel_Magnitude": latest_doc["Accel_Mag"],
            "Gyro_Magnitude":  latest_doc["Gyro_Mag"],
        }

        # 1-row DataFrame in exact training order (you saved feature_order):contentReference[oaicite:4]{index=4}
        x_df = pd.DataFrame([[row_map[c] for c in feature_order]], columns=feature_order)

        # Predict
        x_scaled = scaler.transform(x_df)
        probs = random_forest_model.predict_proba(x_scaled)[0]
        pred_idx = int(np.argmax(probs))
        pred_label = le.inverse_transform([pred_idx])[0]  # e.g., "Healthy", "Mastitis", ...

        resp = {
            "prediction": pred_label,
            "probabilities": {cls: float(p) for cls, p in zip(le.classes_, probs)},
            "data_timestamp": latest_doc["timestamp"].isoformat()
                if hasattr(latest_doc.get("timestamp", None), "isoformat") else None
        }

        if explain:
            # SHAP values (handle multiple formats robustly)
            sv = explainer.shap_values(x_df)
            if isinstance(sv, list):
                shap_vec = np.array(sv[pred_idx][0])         # (n_features,)
            else:
                sv = np.array(sv)
                if sv.ndim == 2 and sv.shape[0] == 1:
                    shap_vec = sv[0]                          # (n_features,)
                elif sv.ndim == 3 and sv.shape[0] == 1:
                    shap_vec = sv[0][:, pred_idx]             # (n_features,)
                else:
                    shap_vec = np.squeeze(sv)
                    if shap_vec.ndim != 1 or shap_vec.shape[0] != len(feature_order):
                        return {"error": f"Unexpected SHAP shape: {sv.shape}"}

            # Top-k by absolute contribution
            order = np.argsort(np.abs(shap_vec))[::-1][:k]

            # Build human-friendly list using *predicted class* baseline
            top_items = []
            for i in order:
                feat = feature_order[i]
                raw_val = float(row_map[feat])
                hint = hint_against_class(feat, raw_val, pred_label)
                top_items.append({
                    "feature": feat,
                    "display": DISPLAY_NAME.get(feat, feat),
                    "value": raw_val,
                    "hint": hint,
                    "shap": float(shap_vec[i]),
                })

            sentence = "Top contributors: " + ", ".join(
                f'{t["display"]} ({t["hint"]})' for t in top_items
            )

            resp["top_features"] = top_items
            resp["top_features_sentence"] = sentence

        return resp

    except KeyError as ke:
        return {"error": f"Missing field: {ke!s}"}
    except Exception as e:
        return {"error": str(e)}

@app.post("/predict-image/")
async def predict_image_api(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        np_arr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        if img is None:
            return {"error": "Could not decode image."}

        resized = cv2.resize(img, (224, 224))
        img_arr = resized.astype("float32") / 255.0
        img_arr = np.expand_dims(img_arr, axis=0)

        prediction = lumpy_model.predict(img_arr, verbose=0)[0][0]
        label = "lumpy skin cow" if prediction > 0.5 else "normal cow"

        return {
            "prediction": label,
            "confidence": float(prediction)
        }
    except Exception as e:
        return {"error": str(e)}


@app.get("/predict-consistency")
def predict_consistency(k: int = 3):
    """
    Compare SHAP vs LIME for the latest sensor row.
    Returns: prediction, probs, SHAP top-k, LIME top-k, and agreement metrics.
    """
    if lime_explainer is None:
        return {"error": "LIME explainer not initialized on server."}

    # ----- reuse friendly labels + hint function from your SHAP endpoint:contentReference[oaicite:6]{index=6} -----
    DISPLAY_NAME = {
        "Temperature_C": "Temperature", "Pulse_BPM": "Pulse",
        "Accel_X": "Accel X", "Accel_Y": "Accel Y", "Accel_Z": "Accel Z",
        "Gyro_X": "Gyro X", "Gyro_Y": "Gyro Y", "Gyro_Z": "Gyro Z",
        "MQ_Gas": "MQ gas level", "Saliva_pH": "Saliva pH",
        "Accel_Magnitude": "Accel magnitude", "Gyro_Magnitude": "Gyro magnitude",
    }
    def hint_against_class(feature: str, value: float, cls_label: str) -> str:
        base = class_baselines.get(cls_label) or {}
        mu = (base.get("mean") or {}).get(feature)
        sd = (base.get("std") or {}).get(feature)
        if mu is None or sd is None or sd == 0 or np.isnan(sd): return "no baseline"
        z = (value - mu) / sd
        if z < -1.5: return "low"
        if z < -0.5: return "slightly low"
        if z >  1.5: return "high"
        if z >  0.5: return "slightly high"
        return "normal"

    # ----- fetch latest row (same mapping as /predict-latest):contentReference[oaicite:7]{index=7} -----
    latest_doc = sensor_collection.find_one(sort=[("timestamp", pymongo.DESCENDING)])
    if not latest_doc:
        return {"error": "No sensor data found."}

    row_map = {
        "Temperature_C":   latest_doc["Temp"],
        "Pulse_BPM":       latest_doc["Pulse"],
        "Accel_X":         latest_doc["Accel_X"],
        "Accel_Y":         latest_doc["Accel_Y"],
        "Accel_Z":         latest_doc["Accel_Z"],
        "Gyro_X":          latest_doc["Gyro_X"],
        "Gyro_Y":          latest_doc["Gyro_Y"],
        "Gyro_Z":          latest_doc["Gyro_Z"],
        "MQ_Gas":          latest_doc["MQ"],
        "Saliva_pH":       latest_doc["pH"],
        "Accel_Magnitude": latest_doc["Accel_Mag"],
        "Gyro_Magnitude":  latest_doc["Gyro_Mag"],
    }
    x_df = pd.DataFrame([[row_map[c] for c in feature_order]], columns=feature_order)  # exact order:contentReference[oaicite:8]{index=8}
    x_scaled = scaler.transform(x_df)

    # ----- model prediction -----
    probs = random_forest_model.predict_proba(x_scaled)[0]
    pred_idx = int(np.argmax(probs))
    pred_label = le.inverse_transform([pred_idx])[0]
    ts = latest_doc["timestamp"].isoformat() if hasattr(latest_doc.get("timestamp"), "isoformat") else None

    # ===== SHAP (predicted class) =====
    sv = explainer.shap_values(x_df)  # you already handle multiclass elsewhere:contentReference[oaicite:9]{index=9}
    if isinstance(sv, list):
        shap_vec = np.array(sv[pred_idx][0])                  # (n_features,)
    else:
        sv = np.array(sv)
        shap_vec = sv[0] if sv.ndim == 2 else sv[0][:, pred_idx]

    # top-k by |value|
    shap_order = np.argsort(np.abs(shap_vec))[::-1][:k]
    shap_top = [{
        "feature": feature_order[i],
        "display": DISPLAY_NAME.get(feature_order[i], feature_order[i]),
        "value": float(row_map[feature_order[i]]),
        "hint": hint_against_class(feature_order[i], float(row_map[feature_order[i]]), pred_label),
        "contribution": float(shap_vec[i]),
        "source": "SHAP"
    } for i in shap_order]

    # ===== LIME (predicted class) =====
    def _predict_proba_scaled(xx):
        return random_forest_model.predict_proba(xx)

    exp = lime_explainer.explain_instance(
        data_row=x_scaled[0],
        predict_fn=_predict_proba_scaled,
        num_features=min(k, len(feature_order)),
        top_labels=1
    )
    lime_pairs = exp.as_map()[pred_idx]  # list[(feat_idx, weight)]
    # (LIME already gives top features; enforce k)
    lime_pairs = sorted(lime_pairs, key=lambda t: abs(t[1]), reverse=True)[:k]

    lime_top = []
    for feat_idx, weight in lime_pairs:
        feat = feature_order[feat_idx]
        lime_top.append({
            "feature": feat,
            "display": DISPLAY_NAME.get(feat, feat),
            "value": float(row_map[feat]),
            "hint": hint_against_class(feat, float(row_map[feat]), pred_label),
            "contribution": float(weight),
            "source": "LIME"
        })

    # ===== Agreement metrics =====
    shap_set = {d["feature"] for d in shap_top}
    lime_set = {d["feature"] for d in lime_top}
    inter = shap_set & lime_set
    union = shap_set | lime_set
    jaccard = (len(inter) / len(union)) if union else 0.0

    # direction agreement on shared features
    def _sign(x): return 1 if x > 0 else (-1 if x < 0 else 0)
    shap_sign = {d["feature"]: _sign(d["contribution"]) for d in shap_top}
    lime_sign = {d["feature"]: _sign(d["contribution"]) for d in lime_top}
    if inter:
        sign_matches = sum(1 for f in inter if shap_sign[f] == lime_sign[f])
        sign_agree = sign_matches / len(inter)
    else:
        sign_agree = 0.0

    # rank correlation on shared features (Spearman)
    from scipy.stats import spearmanr
    if len(inter) >= 2:
        # build ranks by absolute importance
        shap_rank = {d["feature"]: i for i, d in enumerate(sorted(shap_top, key=lambda x: abs(x["contribution"]), reverse=True))}
        lime_rank = {d["feature"]: i for i, d in enumerate(sorted(lime_top, key=lambda x: abs(x["contribution"]), reverse=True))}
        common = list(inter)
        r, _ = spearmanr([shap_rank[f] for f in common], [lime_rank[f] for f in common])
        rank_corr = float(r) if not np.isnan(r) else 0.0
    else:
        rank_corr = 0.0

    # simple verdict (tune thresholds as you like)
    verdict = (
        "high" if (jaccard >= 0.6 and sign_agree >= 0.8)
        else "medium" if (jaccard >= 0.4 and sign_agree >= 0.6)
        else "low"
    )

    return {
        "prediction": pred_label,
        "probabilities": {cls: float(p) for cls, p in zip(le.classes_, probs)},
        "data_timestamp": ts,

        "explanations": {
            "shap_top": shap_top,
            "lime_top": lime_top
        },

        "agreement": {
            "jaccard_topk_overlap": jaccard,
            "direction_agreement_on_overlap": sign_agree,
            "spearman_rank_on_overlap": rank_corr,
            "verdict": verdict
        }
    }

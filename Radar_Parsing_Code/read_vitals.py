import os
import csv
import time
from collections import deque
from datetime import datetime, timedelta

import numpy as np
import joblib

from parseFrame import parseStandardFrame
from gui_parser import UARTParser
from demo_defines import *

# ================== USER SETTINGS ==================
COM_PORT = "/dev/ttyACM0"  # change if needed
CFG_FILE = "/home/radarrangers/Desktop/radarmodule/Radar_Parsing_Code/Vital_Signs_With_Tracking_BOOST.cfg"

CSV_DIR = "/home/radarrangers/Desktop/radarmodule/Radar_Parsing_Code/vitals_logs"
MODEL_PATH = r"/home/radarrangers/Desktop/radarmodule/Radar_Parsing_Code/rf_model_window_v2.pkl"      # model file
ROTATE_EVERY_MIN = 15                       # << stays 15 minutes
WINDOW_SIZE = 12                            # must match training
# ===================================================

# These match what we used in training for "abnormal" flags
EMERG_HR_HIGH = 120.0
EMERG_HR_LOW = 40.0
EMERG_BR_HIGH = 25.0
EMERG_BR_LOW = 8.0

class AITriageEngine:
    """
    Pure AI triage (no manual thresholds for classification).
    We only use thresholds internally to compute the same
    "fraction abnormal" features we used during training.
    """

    def __init__(self, model_path: str):
        packed = joblib.load(model_path)  # we saved with joblib.dump(...)
        self.model = packed["model"]
        self.feature_names = packed["features"]
        self.window_size = packed.get("window_size", WINDOW_SIZE)

        self.window = deque(maxlen=self.window_size)
        self.pred_history = deque(maxlen=3)  # for 2-of-3 smoothing

    def reset(self):
        self.window.clear()
        self.pred_history.clear()

    def _compute_window_features(self, hr_arr: np.ndarray, br_arr: np.ndarray) -> dict:
        n = len(hr_arr)
        denom = max(1, n - 1)

        hr_mean = hr_arr.mean()
        hr_std = hr_arr.std()
        hr_median = np.median(hr_arr)
        hr_min = hr_arr.min()
        hr_max = hr_arr.max()
        hr_range = hr_max - hr_min
        hr_slope = (hr_arr[-1] - hr_arr[0]) / denom

        br_mean = br_arr.mean()
        br_std = br_arr.std()
        br_median = np.median(br_arr)
        br_min = br_arr.min()
        br_max = br_arr.max()
        br_range = br_max - br_min
        br_slope = (br_arr[-1] - br_arr[0]) / denom

        hr_high = hr_arr > EMERG_HR_HIGH
        hr_low = hr_arr < EMERG_HR_LOW
        br_high = br_arr > EMERG_BR_HIGH
        br_low = br_arr < EMERG_BR_LOW

        frac_hr_high = hr_high.mean()
        frac_hr_low = hr_low.mean()
        frac_br_high = br_high.mean()
        frac_br_low = br_low.mean()
        frac_any_abnormal = (hr_high | hr_low | br_high | br_low).mean()

        feats = {
            "hr_mean": hr_mean,
            "hr_std": hr_std,
            "hr_median": hr_median,
            "hr_min": hr_min,
            "hr_max": hr_max,
            "hr_range": hr_range,
            "hr_slope": hr_slope,
            "br_mean": br_mean,
            "br_std": br_std,
            "br_median": br_median,
            "br_min": br_min,
            "br_max": br_max,
            "br_range": br_range,
            "br_slope": br_slope,
            "frac_hr_high": frac_hr_high,
            "frac_hr_low": frac_hr_low,
            "frac_br_high": frac_br_high,
            "frac_br_low": frac_br_low,
            "frac_any_abnormal": frac_any_abnormal,
        }
        return feats

    def add_sample(self, hr, br, presence_flag):
        """
        Only call this when HR/BR CHANGED and presence_flag == 1.
        Returns: "WARMUP", "AI_NORMAL", or "AI_EMERGENCY".
        """

        if presence_flag == 0:
            self.reset()
            return "WARMUP"

        # Ignore zeros / warmup frames
        if hr is None or br is None or hr == 0.0 or br == 0.0:
            return "WARMUP"

        self.window.append({"hr": float(hr), "br": float(br)})

        if len(self.window) < self.window_size:
            return "WARMUP"

        frames = list(self.window)[-self.window_size:]
        hr_arr = np.array([s["hr"] for s in frames], dtype=float)
        br_arr = np.array([s["br"] for s in frames], dtype=float)

        feats = self._compute_window_features(hr_arr, br_arr)
        X = np.array([[feats[name] for name in self.feature_names]], dtype=float)

        pred = int(self.model.predict(X)[0])  # 0 = normal, 1 = emergency
        self.pred_history.append(pred)

        if self.pred_history.count(1) >= 2:
            return "AI_EMERGENCY"
        else:
            return "AI_NORMAL"

class CsvRotatingLogger:
    """
    Writes CSV with columns:
    timestamp_iso, frame_number, heart_rate_bpm, breathing_rate_bpm,
    presence_flag, vitals_range_bin, AI_state

    Only logs when HR/BR change.
    Rotates every ROTATE_EVERY_MIN minutes.
    Flushes on every row so premature exit still leaves valid CSV.
    """

    def __init__(self, output_dir: str, rotate_min: int):
        self.output_dir = output_dir
        os.makedirs(self.output_dir, exist_ok=True)

        self.rotate_td = timedelta(minutes=rotate_min)
        self.current_file = None
        self.writer = None
        self.start_time = None

        self.next_index = self._next_index()

        self.last_hr = None
        self.last_br = None

    def _next_index(self) -> int:
        max_idx = 0
        for name in os.listdir(self.output_dir):
            if name.startswith("live_data") and name.endswith(".csv"):
                core = name[len("live_data"):-4]
                try:
                    idx = int(core)
                    max_idx = max(max_idx, idx)
                except ValueError:
                    pass
        return max_idx + 1

    def _open_new(self):
        if self.current_file:
            self.current_file.flush()
            self.current_file.close()

        fname = f"live_data{self.next_index}.csv"
        self.next_index += 1
        path = os.path.join(self.output_dir, fname)

        self.current_file = open(path, "w", newline="", encoding="utf-8")
        self.writer = csv.writer(self.current_file)
        self.start_time = datetime.now()

        # EXACT columns from your sample + AI_state
        self.writer.writerow([
            "timestamp_iso",
            "frame_number",
            "heart_rate_bpm",
            "breathing_rate_bpm",
            "presence_flag",
            "vitals_range_bin",
            "AI_state",
        ])
        self.current_file.flush()

        print(f"[CSV] Logging to {path}")

    def log(self, ts_iso, frame_number, hr, br, presence_flag, vitals_range_bin, ai_state):
        # Only log when HR or BR change
        if hr == self.last_hr and br == self.last_br:
            return

        self.last_hr = hr
        self.last_br = br

        now = datetime.now()
        if self.current_file is None or (now - self.start_time) > self.rotate_td:
            self._open_new()

        self.writer.writerow([
            ts_iso,
            frame_number,
            hr,
            br,
            presence_flag,
            vitals_range_bin,
            ai_state,
        ])
        self.current_file.flush()

    def close(self):
        if self.current_file:
            self.current_file.flush()
            self.current_file.close()
            self.current_file = None

def find_vitals_block(obj):
    """Recursively find the sub-dict that has heart + breath/resp fields."""
    if isinstance(obj, dict):
        keys_lower = [k.lower() for k in obj.keys()]
        has_heart = any("heart" in k for k in keys_lower)
        has_breath = any(("breath" in k) or ("resp" in k) for k in keys_lower)
        if has_heart and has_breath:
            return obj
        for v in obj.values():
            out = find_vitals_block(v)
            if out is not None:
                return out
    elif isinstance(obj, (list, tuple)):
        for v in obj:
            out = find_vitals_block(v)
            if out is not None:
                return out
    return None


def extract_hr_br(vs_block):
    if not isinstance(vs_block, dict):
        return None, None
    hr = vs_block.get("heartRate")
    br = vs_block.get("breathRate")
    return hr, br


def main():
    os.makedirs(CSV_DIR, exist_ok=True)

    print(f"[INIT] Connecting to {COM_PORT}")
    parser = UARTParser("SingleCOMPort")
    parser.connectComPort(COM_PORT, cliBaud=115200)
            
    with open(CFG_FILE, "r") as f:
        cfg_lines = f.readlines()
    print(f"[INIT] Sending cfg: {CFG_FILE}")
    parser.sendCfg(cfg_lines)
    print("[INIT] cfg sent, starting stream...\n")

    logger = CsvRotatingLogger(CSV_DIR, ROTATE_EVERY_MIN)

    try:
        ai_engine = AITriageEngine(MODEL_PATH)
        print(f"[AI] Loaded model from {MODEL_PATH}")
    except Exception as e:
        print("[AI] ERROR loading model:", e)
        ai_engine = None

    first = True
    last_hr_for_ai = None
    last_br_for_ai = None
    ai_state = "WARMUP"

    try:
        while True:
            frame_raw = parser.readAndParseUartSingleCOMPort()
            if not frame_raw:
                continue

            if isinstance(frame_raw, (bytes, bytearray)):
                frame = parseStandardFrame(frame_raw, demo=parser.demo)
            else:
                frame = frame_raw

            if first:
                print("[DEBUG] Frame keys:", list(frame.keys()))
                first = False

            vitals = find_vitals_block(frame)
            hr, br = extract_hr_br(vitals)
            frame_number = frame.get("frameNum", frame.get("frame_number", None))
            ts_iso = datetime.now().isoformat(timespec="milliseconds")

            # presence_flag: 1 if there are any tracks, else 0
            num_tracks = frame.get("numDetectedTracks", 0) or 0
            presence_flag = 1 if num_tracks > 0 else 0

            vitals_range_bin = None
            if isinstance(vitals, dict):
                vitals_range_bin = vitals.get("rangeBin", 0)

            # AI only processes when HR or BR change
            changed = not (
                hr == last_hr_for_ai and br == last_br_for_ai
            )
            if changed and ai_engine is not None:
                ai_state = ai_engine.add_sample(hr, br, presence_flag)
                last_hr_for_ai = hr
                last_br_for_ai = br

            # Terminal "table" print
            print(
                f"[FRAME {frame_number:5}] "
                f"HR={hr!s:>6}  BR={br!s:>6}  P={presence_flag}  "
                f"RangeBin={vitals_range_bin}  AI={ai_state}"
            )

            # Log ONLY when HR/BR change (logger enforces this too)
            logger.log(
                ts_iso,
                frame_number,
                hr,
                br,
                presence_flag,
                vitals_range_bin,
                ai_state,
            )

            time.sleep(0.01)



    except KeyboardInterrupt:
        print("\n[MAIN] Stopped by user (Ctrl+C).")
    finally:
        logger.close()
        time.sleep(0.2)
        try:
            parser.cliCom.close()
        except Exception:
            pass

def run_vitals_loop(
    on_vitals,
    com_port: str = COM_PORT,
    cfg_file: str = CFG_FILE,
    model_path: str = MODEL_PATH,
    log_csv: bool = False,
):
    """
    Runs the radar vitals reader forever and calls:

        on_vitals(hr, br, presence_flag, frame_number, vitals_range_bin, ai_state)

    every time HR/BR CHANGES (and we hav
        ai_engine = AITriageEngine(model_path)
        print(f"[AI] Loaded model from {model_path}")
    except Exception as e:
        print("[AI] ERROR loading model:", e)
        ai_engine = Nonee a frame).
    This is meant to be imported and run from radar_ble.py (in a thread).
    """

    os.makedirs(CSV_DIR, exist_ok=True)

    print(f"[INIT] Connecting to {com_port}")
    parser = UARTParser("SingleCOMPort")
    parser.connectComPort(com_port, cliBaud=115200)

    with open(cfg_file, "r") as f:
        cfg_lines = f.readlines()
    print(f"[INIT] Sending cfg: {cfg_file}")
    parser.sendCfg(cfg_lines)
    print("[INIT] cfg sent, starting stream...\n")

    logger = CsvRotatingLogger(CSV_DIR, ROTATE_EVERY_MIN) if log_csv else None

    try:
        ai_engine = AITriageEngine(model_path)
        print(f"[AI] Loaded model from {model_path}")
    except Exception as e:
        print("[AI] ERROR loading model:", e)
        ai_engine = None

    last_hr_for_ai = None
    last_br_for_ai = None
    ai_state = "WARMUP"

    last_hr_sent = None
    last_br_sent = None

    try:
        while True:
            frame_raw = parser.readAndParseUartSingleCOMPort()
            if not frame_raw:
                continue

            if isinstance(frame_raw, (bytes, bytearray)):
                frame = parseStandardFrame(frame_raw, demo=parser.demo)
            else:
                frame = frame_raw

            vitals = find_vitals_block(frame)
            hr, br = extract_hr_br(vitals)

            frame_number = frame.get("frameNum", frame.get("frame_number", None))
            ts_iso = datetime.now().isoformat(timespec="milliseconds")

            num_tracks = frame.get("numDetectedTracks", 0) or 0
            presence_flag = 1 if num_tracks > 0 else 0

            vitals_range_bin = None
            if isinstance(vitals, dict):
                vitals_range_bin = vitals.get("rangeBin", 0)

            # update AI state only when HR/BR change
            changed = not (hr == last_hr_for_ai and br == last_br_for_ai)
            if changed and ai_engine is not None:
                ai_state = ai_engine.add_sample(hr, br, presence_flag)
                last_hr_for_ai = hr
                last_br_for_ai = br

            # Call callback only when HR/BR actually change (and are valid)
            if hr is not None and br is not None and (hr != last_hr_sent or br != last_br_sent):
                last_hr_sent = hr
                last_br_sent = br
                on_vitals(hr, br, presence_flag, frame_number, vitals_range_bin, ai_state)

            # Optional CSV logging
            if logger is not None:
                logger.log(
                    ts_iso,
                    frame_number,
                    hr,
                    br,
                    presence_flag,
                    vitals_range_bin,
                    ai_state,
                )

            time.sleep(0.01)

    except KeyboardInterrupt:
        print("\n[VITALS] Stopped by user (Ctrl+C).")
    finally:
        if logger is not None:
            logger.close()
        try:
            parser.cliCom.close()
        except Exception:
            pass


if __name__ == "__main__":
    main()

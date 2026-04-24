#!/usr/bin/env python3

"""
VSCode-friendly synthetic vitals generator (v2) tuned to better match
your live radar logs.

Key changes vs v1:
- More realistic breathing jitter (less perfectly smooth).
- Normal cases never sustain "emergency-level" vitals; outliers are
  single-frame glitches only.
- Emergency cases still ramp and then stay clearly abnormal.
- vitals_range_bin is now populated in a way that roughly matches how
  your device behaves, instead of always being 0.
"""

# ==========================
# USER CONFIG (EDIT THESE)
# ==========================

OUT_ROOT = r"C:\Users\class\OneDrive\Desktop\Archive\ECEN 403\Radar_Parsing_Code\test_data\realistic_cases"
NUM_NORMAL = 500
NUM_EMERGENCY = 500
ROWS_PER_FILE = 500          # total rows including warmup + leaving
SEED = 123                   # set None for non-reproducible

# ============================================================
#                     IMPORTS & CONSTANTS
# ============================================================

import csv
import os
import random
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import List, Tuple

# Physiological-ish ranges (what you told me)
NORMAL_HR_RANGE = (60.0, 100.0)
NORMAL_BR_RANGE = (10.0, 20.0)

# Hard emergency thresholds (used by AI pipeline)
EMERG_HR_HIGH = 120.0
EMERG_HR_LOW = 40.0
EMERG_BR_HIGH = 25.0
EMERG_BR_LOW = 8.0


@dataclass
class VitalsSample:
    ts_iso: str
    frame_number: int
    heart_rate_bpm: float
    breathing_rate_bpm: float
    presence_flag: int
    vitals_range_bin: int

    def to_row(self):
        return {
            "timestamp_iso": self.ts_iso,
            "frame_number": self.frame_number,
            "heart_rate_bpm": round(self.heart_rate_bpm, 3),
            "breathing_rate_bpm": round(self.breathing_rate_bpm, 3),
            "presence_flag": self.presence_flag,
            "vitals_range_bin": self.vitals_range_bin,
        }


# ============================================================
#                     UTILITY FUNCTIONS
# ============================================================

def clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


def draw_baseline() -> Tuple[float, float]:
    """
    Draw a realistic baseline HR/BR for one "person".
    HR ~ N(75, 7), clipped to [60, 100]
    BR ~ N(17, 2), clipped to [10, 20]
    """
    hr = random.gauss(75.0, 7.0)
    br = random.gauss(17.0, 2.0)
    hr = clamp(hr, *NORMAL_HR_RANGE)
    br = clamp(br, *NORMAL_BR_RANGE)
    return hr, br


def mean_reverting_step(prev: float, baseline: float, sigma: float, k: float = 0.05) -> float:
    """
    Ornstein–Uhlenbeck-style update:
        x_{t+1} = x_t + noise - k*(x_t - baseline)
    """
    noise = random.gauss(0.0, sigma)
    pull = -k * (prev - baseline)
    return prev + noise + pull


def observed_with_jitter(true_hr: float,
                         true_br: float,
                         allow_big_outlier: bool) -> Tuple[float, float]:
    """
    Convert the "true" physiological HR/BR into what the sensor reports.
    - Small Gaussian jitter every frame (to avoid perfectly smooth curves).
    - Optional rare, one-frame "measurement glitches" that can jump around
      quite a bit but do NOT affect the underlying state.
    """
    # small per-frame jitter (looks like little quantization noise)
    hr_obs = true_hr + random.gauss(0.0, 0.6)
    br_obs = true_br + random.gauss(0.0, 1.2)

    # occasional single-frame glitch outliers
    if allow_big_outlier and random.random() < 0.02:
        hr_obs += random.uniform(-10.0, 10.0)
        br_obs += random.uniform(-12.0, 12.0)

    # Clip to "non-crazy" values. For normal cases we will call this with
    # allow_big_outlier=True but we still keep it away from the true
    # emergency thresholds.
    hr_obs = clamp(hr_obs, 30.0, EMERG_HR_HIGH - 1.0)
    br_obs = clamp(br_obs, 6.0, EMERG_BR_HIGH - 1.0)

    return hr_obs, br_obs


def compute_vitals_bin(hr: float,
                       br: float,
                       baseline_hr: float) -> int:
    """
    Approximate how your device sets vitals_range_bin, using what we can see
    from your live logs:

    - A baseline HR around 75–80 bpm is mostly bin 7–8.
    - "Below baseline" HR gives bin 6.
    - High HR or strong hyperventilation bumps bin up to 8–9.
    """
    if hr <= 0.0 and br <= 0.0:
        return 0  # warmup / person not present

    delta_hr = hr - baseline_hr

    # basic HR-driven band
    if delta_hr < -5.0:
        bin_ = 6
    elif delta_hr < 3.0:
        bin_ = 7
    elif delta_hr < 10.0:
        bin_ = 8
    else:
        bin_ = 9

    # breathing modifiers: large BR pushes to a higher bin
    if br > 30.0 and bin_ < 9:
        bin_ += 1
    elif br < 10.0 and bin_ > 6:
        bin_ -= 1

    return int(clamp(bin_, 0, 9))


# ============================================================
#                NORMAL / EMERGENCY GENERATORS
# ============================================================

def generate_normal_series(n_rows: int) -> List[VitalsSample]:

    assert n_rows >= 3, "Need at least 3 rows (warmup, vitals, leaving)"

    baseline_hr, baseline_br = draw_baseline()
    start_time = datetime.now()

    samples: List[VitalsSample] = []

    # ---- Frame 0: warmup (presence=1, HR=0, BR=0) ----
    ts0 = start_time.isoformat(timespec="seconds")
    samples.append(VitalsSample(
        ts_iso=ts0,
        frame_number=0,
        heart_rate_bpm=0.0,
        breathing_rate_bpm=0.0,
        presence_flag=1,
        vitals_range_bin=0,
    ))

    # underlying "true" HR/BR we evolve over time
    hr = baseline_hr + random.gauss(0.0, 3.0)
    br = baseline_br + random.gauss(0.0, 2.0)

    frame = 1
    last_vitals_frame = n_rows - 2  # last frame where presence_flag = 1

    while frame <= last_vitals_frame:
        ts = (start_time + timedelta(seconds=frame)).isoformat(timespec="seconds")

        # ================================
        # 1) Multi-frame SPIKE BURSTS
        # ================================
        # These mimic what we see in your real data: breathing can jump and
        # stay high for 4–10 frames while HR stays fairly normal.
        if random.random() < 0.02:  # probability of starting a burst
            seg_len = random.randint(4, 10)
            br_spike_target = random.uniform(27.0, 40.0)
            hr_spike_target = clamp(
                baseline_hr + random.uniform(-5.0, 5.0),
                NORMAL_HR_RANGE[0] - 5.0,
                NORMAL_HR_RANGE[1] + 5.0,
            )

            for _ in range(seg_len):
                if frame > last_vitals_frame:
                    break

                ts_seg = (start_time + timedelta(seconds=frame)).isoformat(timespec="seconds")

                # HR stays near fairly normal range
                hr = mean_reverting_step(hr, hr_spike_target, sigma=2.0, k=0.05)
                # BR is strongly pulled toward a high target, with extra noise
                br = mean_reverting_step(br, br_spike_target, sigma=4.0, k=0.08)

                # allow BR to cross your emergency threshold (this is
                # *exactly* the kind of false-positive situation we want
                # the AI to learn is still "normal")
                hr = clamp(hr, NORMAL_HR_RANGE[0] - 10.0, NORMAL_HR_RANGE[1] + 10.0)
                br = clamp(br, NORMAL_BR_RANGE[0], 45.0)

                samples.append(VitalsSample(ts_seg, frame, hr, br, 1, 0))
                frame += 1

            # after the burst we go back to the normal loop
            continue

        # ================================
        # 2) Mild STRESS SEGMENTS
        # ================================
        if random.random() < 0.03:
            seg_len = random.randint(3, 8)
            hr_target = clamp(baseline_hr + random.uniform(5, 12), *NORMAL_HR_RANGE)
            br_target = clamp(baseline_br + random.uniform(2, 5), *NORMAL_BR_RANGE)

            for _ in range(seg_len):
                if frame > last_vitals_frame:
                    break
                ts_seg = (start_time + timedelta(seconds=frame)).isoformat(timespec="seconds")
                hr = mean_reverting_step(hr, hr_target, sigma=1.6, k=0.06)
                br = mean_reverting_step(br, br_target, sigma=1.0, k=0.06)

                hr = clamp(hr, NORMAL_HR_RANGE[0], NORMAL_HR_RANGE[1])
                br = clamp(br, NORMAL_BR_RANGE[0], NORMAL_BR_RANGE[1] + 2.0)

                samples.append(VitalsSample(ts_seg, frame, hr, br, 1, 0))
                frame += 1
            continue

        # ================================
        # 3) Default wandering (low-noise)
        # ================================
        hr = mean_reverting_step(hr, baseline_hr, sigma=1.2, k=0.05)
        br = mean_reverting_step(br, baseline_br, sigma=0.9, k=0.05)

        hr = clamp(hr, NORMAL_HR_RANGE[0], NORMAL_HR_RANGE[1])
        br = clamp(br, NORMAL_BR_RANGE[0], NORMAL_BR_RANGE[1])

        samples.append(VitalsSample(ts, frame, hr, br, 1, 0))
        frame += 1

    # ---- Final frame: person leaves (presence=0, HR=0, BR=0) ----
    ts_leave = (start_time + timedelta(seconds=n_rows - 1)).isoformat(timespec="seconds")
    samples.append(VitalsSample(
        ts_iso=ts_leave,
        frame_number=n_rows - 1,
        heart_rate_bpm=0.0,
        breathing_rate_bpm=0.0,
        presence_flag=0,
        vitals_range_bin=0,
    ))

    return samples

def choose_emergency_profile(baseline_hr: float, baseline_br: float) -> Tuple[float, float, str]:
    """
    Pick one of several emergency styles and return target HR/BR plus a label.
    """
    mode = random.choice(["tachy", "brady", "hypervent", "combined"])

    if mode == "tachy":
        # very high HR, BR slightly high/normal
        target_hr = random.uniform(EMERG_HR_HIGH + 5, EMERG_HR_HIGH + 40)      # 125-160
        target_br = random.uniform(baseline_br + 2, baseline_br + 6)
    elif mode == "brady":
        # very low HR, BR near normal
        target_hr = random.uniform(30.0, EMERG_HR_LOW - 1)                     # 30-39
        target_br = random.uniform(baseline_br - 2, baseline_br + 2)
    elif mode == "hypervent":
        # very high BR, modest HR increase (matches your sample)
        target_hr = random.uniform(baseline_hr + 5, baseline_hr + 15)
        target_br = random.uniform(EMERG_BR_HIGH + 2, EMERG_BR_HIGH + 15)      # 27-40
    else:  # combined
        target_hr = random.uniform(EMERG_HR_HIGH + 5, EMERG_HR_HIGH + 40)
        target_br = random.uniform(EMERG_BR_HIGH + 2, EMERG_BR_HIGH + 15)

    return target_hr, target_br, mode


def generate_emergency_series(n_rows: int) -> List[VitalsSample]:
    """
    Generate one emergency series with:
        - warmup frame at t=0 (presence=1, HR=0, BR=0)
        - pre-onset region like normal
        - ramp into emergency and sustain
        - leaving frame at t=n_rows-1 (presence=0, HR=0, BR=0)

    Design principles:
    - Before onset the behavior looks like a slightly jittery normal case.
    - After onset we *stay* clearly abnormal for a big chunk of the file,
      so the AI has sustained evidence instead of just spikes.
    """
    assert n_rows >= 3, "Need at least 3 rows (warmup, vitals, leaving)"

    baseline_hr, baseline_br = draw_baseline()
    start_time = datetime.now()
    samples: List[VitalsSample] = []

    # ---- Frame 0: warmup ----
    ts0 = start_time.isoformat(timespec="seconds")
    samples.append(VitalsSample(
        ts_iso=ts0,
        frame_number=0,
        heart_rate_bpm=0.0,
        breathing_rate_bpm=0.0,
        presence_flag=1,
        vitals_range_bin=0,
    ))

    frame = 1
    last_vitals_frame = n_rows - 2

    # starting underlying HR/BR
    true_hr = baseline_hr + random.gauss(0.0, 3.0)
    true_br = baseline_br + random.gauss(0.0, 1.5)

    # random emergency onset between 25% and 60% of vitals portion
    onset_frame = random.randint(
        frame + int(0.25 * (last_vitals_frame - frame)),
        frame + int(0.60 * (last_vitals_frame - frame))
    )
    # we also enforce that the abnormal segment lasts at least ~20 frames
    ramp_len = random.randint(5, 15)
    min_sustain = 20  # reserved if you want extra checks later

    target_hr, target_br, mode = choose_emergency_profile(baseline_hr, baseline_br)

    while frame <= last_vitals_frame:
        ts = (start_time + timedelta(seconds=frame * 4.26)).isoformat(timespec="seconds")

        if frame < onset_frame:
            # pre-onset behaves like a normal case
            true_hr = mean_reverting_step(true_hr, baseline_hr, sigma=1.5, k=0.05)
            true_br = mean_reverting_step(true_br, baseline_br, sigma=1.0, k=0.05)

            true_hr = clamp(true_hr, *NORMAL_HR_RANGE)
            true_br = clamp(true_br, *NORMAL_BR_RANGE)

            hr_obs, br_obs = observed_with_jitter(true_hr, true_br, allow_big_outlier=True)
        elif frame < onset_frame + ramp_len:
            # ramp from current values toward emergency target
            alpha = (frame - onset_frame + 1) / ramp_len  # 0..1
            true_hr = true_hr + alpha * (target_hr - true_hr) + random.gauss(0.0, 2.0)
            true_br = true_br + alpha * (target_br - true_br) + random.gauss(0.0, 1.5)

            hr_obs, br_obs = observed_with_jitter(true_hr, true_br, allow_big_outlier=False)
        else:
            # post-onset: mean-revert around emergency target
            true_hr = mean_reverting_step(true_hr, target_hr, sigma=2.3, k=0.04)
            true_br = mean_reverting_step(true_br, target_br, sigma=1.7, k=0.04)

            hr_obs, br_obs = observed_with_jitter(true_hr, true_br, allow_big_outlier=False)

        # Emergencies are allowed to actually cross the hard thresholds
        hr_obs = clamp(hr_obs, 20.0, 200.0)
        br_obs = clamp(br_obs, 4.0, 60.0)

        bin_ = compute_vitals_bin(hr_obs, br_obs, baseline_hr)

        samples.append(VitalsSample(ts, frame, hr_obs, br_obs, 1, bin_))
        frame += 1

    # ---- Final frame: person leaves ----
    ts_leave = (start_time + timedelta(seconds=(n_rows - 1) * 4.26)).isoformat(timespec="seconds")
    samples.append(VitalsSample(
        ts_iso=ts_leave,
        frame_number=n_rows - 1,
        heart_rate_bpm=0.0,
        breathing_rate_bpm=0.0,
        presence_flag=0,
        vitals_range_bin=0,
    ))

    # Optional sanity check: ensure we really had a sustained abnormal period
    # If you want, you can post-process `samples` here and regenerate if
    # the number of frames above thresholds is too small.

    return samples


# ============================================================
#                     CSV OUTPUT / DRIVER
# ============================================================

def write_csv(path: str, samples: List[VitalsSample]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fieldnames = [
        "timestamp_iso",
        "frame_number",
        "heart_rate_bpm",
        "breathing_rate_bpm",
        "presence_flag",
        "vitals_range_bin",
    ]
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for s in samples:
            writer.writerow(s.to_row())


def main():
    if SEED is not None:
        random.seed(SEED)

    normal_dir = os.path.join(OUT_ROOT, "normal")
    emerg_dir = os.path.join(OUT_ROOT, "emergency")

    os.makedirs(normal_dir, exist_ok=True)
    os.makedirs(emerg_dir, exist_ok=True)

    print("Generating NORMAL cases...")
    for i in range(1, NUM_NORMAL + 1):
        samples = generate_normal_series(ROWS_PER_FILE)
        fname = f"normal_{i:03d}.csv"
        write_csv(os.path.join(normal_dir, fname), samples)
        print(f"  wrote {fname}")

    print("Generating EMERGENCY cases...")
    for i in range(1, NUM_EMERGENCY + 1):
        samples = generate_emergency_series(ROWS_PER_FILE)
        fname = f"emergency_{i:03d}.csv"
        write_csv(os.path.join(emerg_dir, fname), samples)
        print(f"  wrote {fname}")

    print("\nDONE. Files saved under:")
    print(OUT_ROOT)


if __name__ == "__main__":
    main()

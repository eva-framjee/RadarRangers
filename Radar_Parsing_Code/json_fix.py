# json_fix.py – minimal stub for Industrial Visualizer scripts

import json

# TI code expects this to exist
if not hasattr(json, "fallback_table"):
    json.fallback_table = {}
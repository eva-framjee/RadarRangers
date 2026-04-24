import threading
import read_vitals

def run_vitals_thread(on_vitals):
    """
    Starts a background thread that runs read_vitals.run_vitals_loop()
    and forwards HR/BR to on_vitals(hr, br, presence_flag)
    """

    def loop():
        def cb(hr, br, presence_flag, frame_number=None, vitals_range_bin=None, ai_state=None):
            # Keep it simple for BLE layer:
            on_vitals(hr, br, presence_flag)

        # log_csv=False so you don't spam CSV while debugging BLE (set True if you want)
        read_vitals.run_vitals_loop(cb, log_csv=False)

    t = threading.Thread(target=loop, daemon=True)
    t.start()
    return t

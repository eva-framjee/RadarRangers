import serial
import time

# ====== EDIT THESE ======
PORT = "COM5"              # same port used by Industrial Visualizer
START_BAUD = 115200        # initial baud (default CLI baud for IWRL6432 demos)
CFG_FILE_PATH = "Vital_Signs_With_Tracking_BOOST.cfg"
# ========================


def send_cfg(ser: serial.Serial, cfg_path: str):
    print(f"[CFG] Sending configuration from {cfg_path}")
    with open(cfg_path, "r") as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith("%"):
                continue

            # --- Special handling for baudRate command ---
            if stripped.lower().startswith("baudrate"):
                # send the command at the *current* baud
                cmd = stripped + "\n"
                ser.write(cmd.encode("utf-8"))
                ser.flush()
                print(f"[CFG] --> {stripped}")

                # parse the new baud from the line
                parts = stripped.split()
                if len(parts) >= 2:
                    new_baud = int(parts[1])
                    # give the radar a moment to switch
                    time.sleep(0.1)
                    # now switch the host side to the same baud
                    ser.baudrate = new_baud
                    print(f"[CFG] Switched host baud to {new_baud}")
                    # tiny delay for stability
                    time.sleep(0.1)
                else:
                    print("[CFG] WARNING: baudRate line without value?")
                continue

            # --- Normal command ---
            cmd = stripped + "\n"
            ser.write(cmd.encode("utf-8"))
            ser.flush()
            print(f"[CFG] --> {stripped}")
            time.sleep(0.05)

    print("[CFG] Done sending cfg, waiting for radar to start...")
    time.sleep(1.0)


def main():
    print(f"[SER] Opening {PORT} @ {START_BAUD}")
    ser = serial.Serial(PORT, START_BAUD, timeout=0.1)

    try:
        # 1) Send cfg over the same port, with baud switching handled
        send_cfg(ser, CFG_FILE_PATH)

        # 2) Clear any leftover text/echo in the RX buffer
        ser.reset_input_buffer()
        print("[SER] Cleared input buffer. Now reading raw data...")

        # 3) Read and show raw bytes (this is where you see the 'buffer')
        while True:
            data = ser.read(4096)
            if data:
                # show first 32 bytes as hex so we can check for magic word 0201040306050807
                print("RAW:", data[:32].hex(), "len=", len(data))
            time.sleep(0.01)

    except KeyboardInterrupt:
        print("\n[MAIN] Stopping.")
    finally:
        ser.close()
        print("[SER] Port closed.")


if __name__ == "__main__":
    main()

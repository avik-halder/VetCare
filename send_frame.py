from picamera2 import Picamera2
import cv2
import requests
import time
from datetime import datetime

url = "https://127.0.0.1:8000/upload-frame"  # Replace with your backend URL

print("📸 Initializing Pi Camera...")
picam2 = Picamera2()
picam2.start()
time.sleep(2)

print("✅ Camera ready. Sending frames...")

frame_count = 0

while True:
    frame = picam2.capture_array()
    frame_count += 1
    timestamp = datetime.now().strftime('%H:%M:%S')

    if frame is None or frame.size == 0:
        print(f"⚠️ [{timestamp}] Frame {frame_count} capture failed — skipping")
        time.sleep(1)
        continue

    success, img_encoded = cv2.imencode('.jpg', frame)
    if not success:
        print(f"⚠️ [{timestamp}] Frame {frame_count} JPEG encoding failed — skipping")
        time.sleep(1)
        continue

    files = {'file': ('frame.jpg', img_encoded.tobytes(), 'image/jpeg')}
    
    

    try:
        response = requests.post(url, files=files, timeout=2)
        print(f"📤 [{timestamp}] Frame {frame_count} sent — Status: {response.status_code}")
    except Exception as e:
        print(f"❌ [{timestamp}] Upload failed: {e}")

    time.sleep(1)  # Send 1 frame per second

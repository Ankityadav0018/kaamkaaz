import json
import os

new_strings = {
    "micPermissionDenied": "Microphone permission not granted",
    "listeningSpeakNow": "Listening... speak now"
}

en_json_path = '/Users/ankityadav/lpu/rozgar/app/assets/languages/en.json'
with open(en_json_path, 'r') as f:
    data = json.load(f)

for k, v in new_strings.items():
    data[k] = v

with open(en_json_path, 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Added mic keys")

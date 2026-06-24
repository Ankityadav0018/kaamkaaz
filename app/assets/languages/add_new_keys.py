import json
import os
from deep_translator import GoogleTranslator

LANGUAGES = {
    'hi': 'hi',
    'pa': 'pa',
    'bgc': 'hi',
    'raj': 'hi',
    'mr': 'mr',
    'gu': 'gu',
    'bn': 'bn',
    'ta': 'ta',
    'te': 'te',
    'kn': 'kn',
    'ml': 'ml',
    'or': 'or',
    'ur': 'ur',
}

NEW_KEYS = {
    "applied": "APPLIED",
    "applyNow": "APPLY NOW",
    "fillInWhatMatters": "Fill in only what matters",
    "selectVehicleType": "Select vehicle type",
    "selectLicenseType": "Select license type",
    "bikeMotorcycle": "Bike / Motorcycle",
    "autoRickshaw": "Auto Rickshaw",
    "car": "Car",
    "suvMuv": "SUV / MUV",
    "vanTraveller": "Van / Traveller",
    "truck": "Truck",
    "bus": "Bus",
    "tractor": "Tractor",
    "anyVehicle": "Any Vehicle",
    "mcwgMotorcycle": "MCWG – Motorcycle",
    "lmvCar": "LMV – Car",
    "lmvTrTaxi": "LMV-TR – Taxi / Van",
    "hmvTruck": "HMV – Truck",
    "htvBus": "HTV – Bus",
    "anyValidLicense": "Any valid license",
    "noLicenseReq": "No license required",
    "withinCity": "Within city",
    "betweenCities": "Between cities",
    "longDistance": "Long distance",
    "vehicleTypeReq": "Vehicle Type Required",
    "licenseTypeReq": "License Type Required",
    "tripTypeReq": "Trip Type"
}

def translate_and_update():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    en_path = os.path.join(base_dir, 'en.json')
    with open(en_path, 'r', encoding='utf-8') as f:
        en_data = json.load(f)
    
    for k, v in NEW_KEYS.items():
        if k not in en_data:
            en_data[k] = v
            
    with open(en_path, 'w', encoding='utf-8') as f:
        json.dump(en_data, f, ensure_ascii=False, indent=2)
    print("Updating en.json...")

    for lang_code, trans_code in LANGUAGES.items():
        print(f"Updating {lang_code}.json...")
        file_path = os.path.join(base_dir, f"{lang_code}.json")
        
        if not os.path.exists(file_path):
            continue
            
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        updated = False
        translator = GoogleTranslator(source='en', target=trans_code)
        for k, v in NEW_KEYS.items():
            if k not in data:
                try:
                    if trans_code == 'en':
                        translation = v
                    else:
                        translation = translator.translate(v)
                    data[k] = translation
                    updated = True
                    print(f"  Translated: {v} -> {translation}")
                except Exception as e:
                    print(f"  Error translating {v} to {lang_code}: {e}")
                    data[k] = v
                    updated = True
                    
        if updated:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    translate_and_update()
    print("Done!")

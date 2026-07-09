#!/usr/bin/env python3
import json
import os
import re
from deep_translator import GoogleTranslator

LANGUAGES = {
    'hi': 'hi',
    'pa': 'pa',
    'bgc': 'hi', # Haryanvi falls back to Hindi for translation tool
    'raj': 'hi', # Rajasthani falls back to Hindi for translation tool
    'mr': 'mr',
    'gu': 'gu',
    'bn': 'bn',
    'ta': 'ta',
    'te': 'te',
    'kn': 'kn',
    'ml': 'ml',
    'or': 'or'
}

NEW_KEYS = {
    "otpLogin": "OTP Login",
    "emailAddress": "Email Address",
    "generalWorker": "General Worker",
    "driver": "Driver",
    "provideDetailToFix": "Please provide as much detail as possible to help us fix it.",
    "emailRequired": "Email is required",
    "invalidEmail": "Enter a valid email",
    "passwordMinLength": "Must be at least 8 characters",
    "passwordUppercase": "Must contain uppercase letter",
    "passwordLowercase": "Must contain lowercase letter",
    "passwordNumber": "Must contain a number",
    "passwordSpecial": "Must contain special character",
    "biometricReason": "Please authenticate to login securely",
    "kaamDeneWala": "Kaam dene wala",
    "failedToSubmitReport": "Failed to submit report"
}

WHITELIST = {
    "EN", "HI", "yourname@gmail.com", "e.g. yourname@gmail.com", "e.g. RAJ4F2", "RAJ4F2", "PB01AB1234",
    "e.g. PB01AB1234", "e.g. Ram Construction", "e.g. Ram Construction Co.", "e.g. Lucknow, Agra district",
    "UPI ID", "JCB / Excavator", "JCB", "SUV", "MUV", "SUV / MUV", "GPS", "FCM", "KYC", "IST", "UIDAI",
    "HTTPS", "OTP", "IST", "© 2026 Kaamkaaz. All rights reserved.", "© 2025 Kaamkaaz | India"
}

def translate_and_update():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 1. Update English en.json with new keys
    en_path = os.path.join(base_dir, 'en.json')
    if os.path.exists(en_path):
        with open(en_path, 'r', encoding='utf-8') as f:
            en_data = json.load(f)
    else:
        en_data = {}
        
    for k, v in NEW_KEYS.items():
        if k not in en_data:
            en_data[k] = v
            
    with open(en_path, 'w', encoding='utf-8') as f:
        json.dump(en_data, f, ensure_ascii=False, indent=2)
    print("Updated en.json with new keys.")

    # 2. Iterate through all other languages
    for lang_code, trans_code in LANGUAGES.items():
        file_path = os.path.join(base_dir, f"{lang_code}.json")
        if not os.path.exists(file_path):
            print(f"File {lang_code}.json not found, skipping.")
            continue
            
        print(f"\nProcessing {lang_code}.json...")
        with open(file_path, 'r', encoding='utf-8') as f:
            lang_data = json.load(f)
            
        updated = False
        translator = GoogleTranslator(source='en', target=trans_code)
        
        # We check every key in en_data to ensure it's in the lang_data and translated
        for key, en_val in en_data.items():
            if not isinstance(en_val, str):
                continue
                
            # If the key is not in the language file, or is equal to the English value
            is_untranslated = (key not in lang_data) or (lang_data[key].strip() == en_val.strip())
            
            # Skip placeholders, numbers, whitelisted items, or empty strings
            is_placeholder = bool(re.match(r'^[\{\}\s\d\-\+\:\,\.\/\@\(\)\_]*$', en_val))
            is_whitelisted = en_val in WHITELIST or key in WHITELIST
            
            if is_untranslated and not is_placeholder and not is_whitelisted and en_val.strip():
                try:
                    translation = translator.translate(en_val)
                    lang_data[key] = translation
                    updated = True
                    print(f"  Translated [{key}]: {en_val} -> {translation}")
                except Exception as e:
                    print(f"  Error translating '{en_val}' to {lang_code}: {e}")
                    if key not in lang_data:
                        lang_data[key] = en_val
                        updated = True
                        
        if updated:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(lang_data, f, ensure_ascii=False, indent=2)
            print(f"Saved changes to {lang_code}.json")

if __name__ == '__main__':
    translate_and_update()
    print("\nTranslation complete!")

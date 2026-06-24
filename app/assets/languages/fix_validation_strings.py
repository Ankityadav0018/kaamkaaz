#!/usr/bin/env python3
import os
import json

LIB_DIR = os.path.join(os.path.dirname(__file__), '../../lib')

FIXES = {
    'screens/auth/add_email_screen.dart': [
        ("return 'Email is required'", "return 'emailRequired'.tr()"),
        ("return 'Enter a valid email address'", "return 'invalidEmail'.tr()"),
    ],
    'screens/auth/forgot_password_screen.dart': [
        ("return 'Email is required'", "return 'emailRequired'.tr()"),
        ("return 'Please enter a valid email'", "return 'invalidEmail'.tr()"),
    ],
    'screens/auth/create_new_password_screen.dart': [
        ("return 'Password is required'", "return 'passwordRequired'.tr()"),
        ("return 'Must be at least 8 characters'", "return 'passwordMinLength'.tr()"),
        ("return 'Must contain at least one uppercase letter'", "return 'passwordUppercase'.tr()"),
        ("return 'Must contain at least one lowercase letter'", "return 'passwordLowercase'.tr()"),
        ("return 'Must contain at least one number'", "return 'passwordNumber'.tr()"),
        ("return 'Must contain at least one special character'", "return 'passwordSpecial'.tr()"),
        ("return 'Please confirm your password'", "return 'confirmPasswordRequired'.tr()"),
        ("return 'Passwords do not match'", "return 'passwordsDoNotMatch'.tr()"),
    ]
}

fixed = 0
for rel_path, replacements in FIXES.items():
    fpath = os.path.join(LIB_DIR, rel_path)
    if not os.path.exists(fpath):
        continue
    
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements:
        content = content.replace(old, new)
        fixed += 1
        
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)

print(f"Replaced {fixed} validation strings in Dart files.")

new_keys = {
    "passwordRequired": "Password is required",
    "confirmPasswordRequired": "Please confirm your password"
}

en_json_path = os.path.join(os.path.dirname(__file__), 'en.json')
with open(en_json_path, 'r', encoding='utf-8') as f:
    en_data = json.load(f)

for k, v in new_keys.items():
    if k not in en_data:
        en_data[k] = v

with open(en_json_path, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)

print("Added missing validation keys to en.json")

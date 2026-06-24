#!/usr/bin/env python3
import os

LIB_DIR = os.path.join(os.path.dirname(__file__), '../../lib')

FIXES = {
    'screens/auth/app_lock_screen.dart': [
        ("Text('Forgot PIN?',", "Text('forgotPin'.tr(),"),
    ],
    'screens/auth/forgot_password_screen.dart': [
        ("Text('Forgot Password',", "Text('forgotPassword'.tr(),"),
        ("Text('Reset Your Password',", "Text('resetYourPassword'.tr(),"),
        ("Text('Enter your registered email and we\\'ll send a reset link.',", "Text('enterRegisteredEmailResetLink'.tr(),"),
        ("Text('Email Address',", "Text('emailAddress'.tr(),"),
        ("label: 'Send Reset Link'", "label: 'sendResetLink'.tr()"),
        ("child: Text('Back to Login',", "child: Text('backToLogin'.tr(),"),
        ("Text('Check Your Email!',", "Text('checkYourEmail'.tr(),"),
        ("label: 'Go to Login'", "label: 'goToLogin'.tr()"),
    ],
    'screens/auth/set_pin_screen.dart': [
        ("Text('PINs do not match. Try again.')", "Text('pinsDoNotMatch'.tr())"),
        ("Text('Finish Setup',", "Text('finishSetup'.tr(),"),
    ],
    'screens/splash_screen.dart': [
        ("Text('CONNECT • WORK • GROW',", "Text('connectWorkGrow'.tr(),"),
    ],
    'widgets/theme_selector_widget.dart': [
        ("Text('App Theme',", "Text('appTheme'.tr(),"),
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

print(f"Replaced strings in {fixed} places.")

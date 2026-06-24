import json

new_strings = {
    "forgotPin": "Forgot PIN?",
    "forgotPassword": "Forgot Password",
    "resetYourPassword": "Reset Your Password",
    "enterRegisteredEmailResetLink": "Enter your registered email and we'll send a reset link.",
    "emailAddress": "Email Address",
    "sendResetLink": "Send Reset Link",
    "backToLogin": "Back to Login",
    "checkYourEmail": "Check Your Email!",
    "goToLogin": "Go to Login",
    "pinsDoNotMatch": "PINs do not match. Try again.",
    "finishSetup": "Finish Setup",
    "connectWorkGrow": "CONNECT • WORK • GROW",
    "appTheme": "App Theme"
}

with open('/Users/ankityadav/lpu/rozgar/app/assets/languages/en.json', 'r') as f:
    data = json.load(f)

for k, v in new_strings.items():
    data[k] = v

with open('/Users/ankityadav/lpu/rozgar/app/assets/languages/en.json', 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Updated en.json with 13 keys")

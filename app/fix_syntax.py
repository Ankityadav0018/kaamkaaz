import re

files = [
    'lib/screens/auth/login_screen.dart',
    'lib/screens/auth/register_screen.dart',
    'lib/screens/auth/forgot_password_screen.dart',
    'lib/screens/auth/verify_otp_screen.dart',
]

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # We want to replace the tail end of the build method
    # It currently ends with extra brackets
    
    content = re.sub(r'\]\,\s*\)\,\s*\)\,\s*\)\,\s*\)\;', r'],\n        ),\n      ),\n    );', content)
    content = re.sub(r'\]\,\s*\)\,\s*\)\,\s*\)\;', r'],\n        ),\n      ),\n    );', content)

    with open(f, 'w') as file:
        file.write(content)


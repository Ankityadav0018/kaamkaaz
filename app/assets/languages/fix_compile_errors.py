#!/usr/bin/env python3
import os
import re

LIB_DIR = os.path.join(os.path.dirname(__file__), '../../lib')

def fix_file(fpath):
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Add import if .tr() is used but import is missing
    if '.tr()' in content and 'package:easy_localization/easy_localization.dart' not in content:
        # Find the last import
        import_idx = content.rfind("import '")
        if import_idx != -1:
            end_idx = content.find(';', import_idx) + 1
            content = content[:end_idx] + "\nimport 'package:easy_localization/easy_localization.dart';" + content[end_idx:]
        else:
            content = "import 'package:easy_localization/easy_localization.dart';\n" + content

    # Remove const before Text('...'.tr())
    # Regex to find: const Text('something'.tr()
    # Or const SnackBar(content: Text('something'.tr()
    
    # Simple replace for the specific known issues
    content = content.replace("const Text('forgotPin'.tr()", "Text('forgotPin'.tr()")
    content = content.replace("const Text('finishSetup'.tr()", "Text('finishSetup'.tr()")
    content = content.replace("const SnackBar(content: Text('pinsDoNotMatch'.tr())", "SnackBar(content: Text('pinsDoNotMatch'.tr())")
    
    # Also remove any trailing const from SnackBar if there is one
    # const SnackBar(content: Text('pinsDoNotMatch'.tr()), backgroundColor: AppColors.danger) -> SnackBar(...)
    
    # We can just use a regex to strip 'const ' when followed by any Widget that has .tr() inside it.
    # A safer manual replace for set_pin_screen.dart:
    content = re.sub(r'const\s+SnackBar\(\s*content:\s*Text\([^)]+\.tr\(\)[^)]*\)',
                     lambda m: m.group(0).replace('const ', ''), content)
    content = re.sub(r'const\s+Text\([^)]+\.tr\(\)[^)]*\)',
                     lambda m: m.group(0).replace('const ', ''), content)

    if content != original:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {fpath}")

for root, dirs, files in os.walk(LIB_DIR):
    for name in files:
        if name.endswith('.dart'):
            fix_file(os.path.join(root, name))

print("Done fixing const and imports.")

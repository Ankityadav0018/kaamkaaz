#!/usr/bin/env python3
import os
import re

LIB_DIR = os.path.join(os.path.dirname(__file__), '../../lib')

def process_file(fpath):
    if 'voice_text_field.dart' in fpath:
        return

    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    
    # Replace TextField( and TextFormField(
    content = re.sub(r'\bTextField\s*\(', 'VoiceTextField(', content)
    content = re.sub(r'\bTextFormField\s*\(', 'VoiceTextField(', content)

    if content != original:
        # Add import
        if 'package:kaamkaaz/widgets/voice_text_field.dart' not in content and 'voice_text_field.dart' not in content:
            # find last import
            last_import_idx = content.rfind("import ")
            if last_import_idx != -1:
                end_idx = content.find(';', last_import_idx)
                if end_idx != -1:
                    content = content[:end_idx+1] + "\nimport 'package:kaamkaaz/widgets/voice_text_field.dart';" + content[end_idx+1:]
            else:
                content = "import 'package:kaamkaaz/widgets/voice_text_field.dart';\n" + content

        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {fpath}")

for root, dirs, files in os.walk(LIB_DIR):
    for f in files:
        if f.endswith('.dart'):
            process_file(os.path.join(root, f))

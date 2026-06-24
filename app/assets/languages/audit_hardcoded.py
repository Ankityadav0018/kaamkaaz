#!/usr/bin/env python3
"""
Audit hardcoded English strings in Dart files that should be localized.
Finds Text('...') and similar that are not using .tr()
"""
import re
import os
import sys

LIB_DIR = os.path.join(os.path.dirname(__file__), '../../lib')
SCREENS_DIR = os.path.join(LIB_DIR, 'screens')
WIDGETS_DIR = os.path.join(LIB_DIR, 'widgets')

# Patterns to detect hardcoded strings in UI
HARDCODED_PATTERNS = [
    # Text('Hardcoded string') — not ending with .tr()
    r'''Text\s*\(\s*['"]([A-Za-z][^'"]{3,})['"]\s*(?!\.tr)''',
    # title: 'Hardcoded'
    r'''title\s*:\s*['"]([A-Za-z][^'"]{3,})['"]\s*(?!\.tr)''',
    # label: 'Hardcoded'
    r'''label\s*:\s*['"]([A-Za-z][^'"]{3,})['"]\s*(?!\.tr)''',
    # hint: 'Hardcoded'
    r'''hint[Tt]ext\s*:\s*['"]([A-Za-z][^'"]{3,})['"]\s*(?!\.tr)''',
    # tooltip: 'Hardcoded'
    r'''tooltip\s*:\s*['"]([A-Za-z][^'"]{3,})['"]\s*(?!\.tr)''',
]

# Strings to ignore (unit values, format strings, identifiers, etc.)
IGNORE_CONTAINS = [
    'assets/', '.png', '.jpg', '.svg', '.gif', '.webp',
    'http', 'https', 'ws://', '/', '_', 'android', 'ios',
    'package:', 'dart:', '#', 'Bearer', 'Content-Type',
    '%Y', '%m', '%d', 'dd MMM', 'MM/dd', 'HH:mm',
    '.tr()', 'LocaleKeys', 'r"', "r'",
]
IGNORE_EXACT = {
    'en', 'hi', 'bn', 'mr', 'gu', 'pa', 'te', 'ta', 'kn', 'ml', 'or', 'ur',
    'bgc', 'raj',
    'OK', 'ok', 'ID', 'UPI', 'GPS', 'KYC', 'OTP',
    'kg', 'km', 'km/h', 'INR', '₹',
}

def should_ignore(s: str) -> bool:
    s = s.strip()
    if not s or len(s) < 3:
        return True
    if s in IGNORE_EXACT:
        return True
    for ign in IGNORE_CONTAINS:
        if ign in s:
            return True
    # Skip if it looks like a variable name / code identifier
    if re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', s) and ' ' not in s:
        return True
    # Skip if it's just numbers/symbols
    if re.match(r'^[\d\s\.\,\:\-\+\%\(\)\[\]\/]+$', s):
        return True
    return False

results = {}

for root_dir in [LIB_DIR]:
    for dirpath, _, filenames in os.walk(root_dir):
        for fname in filenames:
            if not fname.endswith('.dart'):
                continue
            fpath = os.path.join(dirpath, fname)
            rel_path = os.path.relpath(fpath, LIB_DIR)
            
            with open(fpath, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
            
            file_hits = []
            for lineno, line in enumerate(lines, 1):
                # Skip commented lines
                stripped = line.strip()
                if stripped.startswith('//') or stripped.startswith('*'):
                    continue
                # Skip lines already using .tr()
                if '.tr()' in line and 'LocaleKeys' in line:
                    continue
                
                for pattern in HARDCODED_PATTERNS:
                    for m in re.finditer(pattern, line):
                        found = m.group(1)
                        if not should_ignore(found):
                            file_hits.append((lineno, line.strip(), found))
                            break
            
            if file_hits:
                results[rel_path] = file_hits

# Output
total = sum(len(v) for v in results.values())
print(f"\n{'='*70}")
print(f"  HARDCODED STRING AUDIT — {total} potential untranslated strings")
print(f"  in {len(results)} files")
print(f"{'='*70}\n")

for fpath, hits in sorted(results.items()):
    print(f"\n📄 {fpath}  ({len(hits)} issues)")
    for lineno, line, found in hits[:8]:  # cap at 8 per file
        print(f"   L{lineno}: {found!r}")
        print(f"         {line[:100]}")
    if len(hits) > 8:
        print(f"   ... and {len(hits)-8} more")

print(f"\n{'='*70}")
print("Done. Review each file and replace hardcoded strings with LocaleKeys.xxx.tr()")

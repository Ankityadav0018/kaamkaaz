#!/usr/bin/env python3
"""
Fix remaining const context issues and missing easy_localization imports.
"""
import re, os

LIB_DIR = os.path.join(os.path.dirname(__file__), '../../lib')

def fix_file(rel_path, transforms):
    fpath = os.path.join(LIB_DIR, rel_path)
    if not os.path.exists(fpath):
        print(f"NOT FOUND: {rel_path}")
        return
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    for old, new in transforms:
        if old in content:
            content = content.replace(old, new, 1)
        else:
            print(f"  MISS in {rel_path}: {old[:60]!r}")
    if content != original:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ {rel_path}")

def ensure_import(rel_path, import_line):
    """Add import if missing."""
    fpath = os.path.join(LIB_DIR, rel_path)
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    pkg = import_line.split("'")[1]
    if pkg not in content:
        # Insert after first import block
        lines = content.split('\n')
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith('import '):
                insert_at = i + 1
        lines.insert(insert_at, import_line)
        content = '\n'.join(lines)
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  + Added import to {rel_path}")

# ---- Add missing easy_localization imports ----
files_needing_import = [
    'screens/admin/admin_profile_screen.dart',
    'screens/auth/forgot_password_screen.dart',
    'screens/auth/add_email_screen.dart',
]

for f in files_needing_import:
    ensure_import(f, "import 'package:easy_localization/easy_localization.dart';")

# Also ensure LocaleKeys import
files_needing_localekeys = [
    'screens/admin/admin_profile_screen.dart',
    'screens/auth/forgot_password_screen.dart',
    'screens/auth/add_email_screen.dart',
    'screens/chat/chat_list_screen.dart',
]
for f in files_needing_localekeys:
    fpath = os.path.join(LIB_DIR, f)
    with open(fpath, 'r') as rf:
        c = rf.read()
    if 'locale_keys.g.dart' not in c:
        ensure_import(f, "import '../../l10n/locale_keys.g.dart';")

# ---- Fix const context issues ----
# Pattern: const SnackBar(content: Text('key'.tr())) -> SnackBar(content: Text('key'.tr()))
# Pattern: const Text('key'.tr()) -> Text('key'.tr())
# Pattern: const DropdownMenuItem(...Text('key'.tr())) -> DropdownMenuItem(...)

CONST_FIXES = {
    'screens/auth/add_email_screen.dart': [
        ("content: Text('emailSavedSuccess'.tr()),",
         "content: Text(LocaleKeys.emailSavedSuccess.tr()),"),
        ("hintText: 'enterEmailAddress'.tr(),",
         "hintText: LocaleKeys.enterEmailAddress.tr(),"),
    ],
    'screens/auth/register_screen.dart': [
        ("hintText: 'emailExampleHint'.tr(),",
         "hintText: LocaleKeys.emailExampleHint.tr(),"),
        ("hintText: 'referralCodeHint'.tr(),",
         "hintText: LocaleKeys.referralCodeHint.tr(),"),
    ],
    'screens/auth/create_new_password_screen.dart': [
        ("content: Text('passwordUpdatedPleaseLogin'.tr()),",
         "content: Text(LocaleKeys.passwordUpdatedPleaseLogin.tr()),"),
    ],
    'screens/auth/forgot_password_screen.dart': [
        ("hintText: 'emailHintGmail'.tr(),",
         "hintText: LocaleKeys.emailHintGmail.tr(),"),
        ("label: Text('resendLink'.tr())",
         "label: Text(LocaleKeys.resendLink.tr())"),
    ],
    'screens/chat/chat_list_screen.dart': [
        ("child: Text('noMessagesYet'.tr(),",
         "child: Text(LocaleKeys.noMessagesYet.tr(),"),
    ],
    'screens/admin/admin_home_screen.dart': [
        ("hintText: 'enterRejectionReason2'.tr(),",
         "hintText: LocaleKeys.enterRejectionReason2.tr(),"),
        ("DropdownMenuItem(value: 'all', child: Text('allStatus'.tr()))",
         "DropdownMenuItem(value: 'all', child: Text(LocaleKeys.allStatus.tr()))"),
        ("DropdownMenuItem(value: 'all', child: Text('allCategories'.tr()))",
         "DropdownMenuItem(value: 'all', child: Text(LocaleKeys.allCategories.tr()))"),
    ],
    'screens/admin/admin_profile_screen.dart': [
        ("title: Text('adminProfile'.tr(),",
         "title: Text(LocaleKeys.adminProfile.tr(),"),
        ("child: Text('superAdmin'.tr(),",
         "child: Text(LocaleKeys.superAdmin.tr(),"),
        ("title: Text('legalAndInformation'.tr(),",
         "title: Text(LocaleKeys.legalAndInformation.tr(),"),
    ],
    'screens/recruiter/recruiter_applications_screen.dart': [
        ("Text('noApplicationsFound'.tr(), style:",
         "Text(LocaleKeys.noApplicationsFound.tr(), style:"),
    ],
    'screens/worker/job_detail_screen.dart': [
        ("Text('ratingSubmittedTitle'.tr(), style:",
         "Text(LocaleKeys.ratingSubmittedTitle.tr(), style:"),
        ("content: Text('thankYouRatingMsg'.tr())",
         "content: Text(LocaleKeys.thankYouRatingMsg.tr())"),
    ],
}

for rel_path, transforms in CONST_FIXES.items():
    fix_file(rel_path, transforms)

# Also need to strip 'const' from SnackBars/DropdownMenuItems that have .tr() children
REMOVE_CONST_FIXES = {
    'screens/auth/add_email_screen.dart': [
        ("const SnackBar(\n            content: Text(LocaleKeys.emailSavedSuccess.tr()),",
         "SnackBar(\n            content: Text(LocaleKeys.emailSavedSuccess.tr()),"),
    ],
    'screens/auth/create_new_password_screen.dart': [
        ("const SnackBar(\n            content: Text(LocaleKeys.passwordUpdatedPleaseLogin.tr()),",
         "SnackBar(\n            content: Text(LocaleKeys.passwordUpdatedPleaseLogin.tr()),"),
    ],
    'screens/chat/chat_list_screen.dart': [
        ("const Text(LocaleKeys.noMessagesYet.tr(),",
         "Text(LocaleKeys.noMessagesYet.tr(),"),
    ],
    'screens/worker/job_detail_screen.dart': [
        ("const Text(LocaleKeys.ratingSubmittedTitle.tr(),",
         "Text(LocaleKeys.ratingSubmittedTitle.tr(),"),
        ("const Text(LocaleKeys.thankYouRatingMsg.tr())",
         "Text(LocaleKeys.thankYouRatingMsg.tr())"),
    ],
    'screens/recruiter/recruiter_applications_screen.dart': [
        ("const Text(LocaleKeys.noApplicationsFound.tr(),",
         "Text(LocaleKeys.noApplicationsFound.tr(),"),
    ],
}

for rel_path, transforms in REMOVE_CONST_FIXES.items():
    fix_file(rel_path, transforms)

print("\nDone!")

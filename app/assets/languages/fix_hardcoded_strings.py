#!/usr/bin/env python3
"""
Auto-fix all hardcoded strings in Dart files by replacing them with LocaleKeys.xxx.tr()
"""
import re, os

LIB_DIR = os.path.join(os.path.dirname(__file__), '../../lib')

# Each tuple: (file_relative_to_lib, [(old_string, new_expression), ...])
FIXES = {
    'screens/admin/admin_home_screen.dart': [
        ("hintText: 'Search by name...',",
         "hintText: 'searchByNameDots'.tr(),"),
        ("DropdownMenuItem(value: 'all', child: Text('All Status')),",
         "DropdownMenuItem(value: 'all', child: Text('allStatus'.tr())),"),
        ("DropdownMenuItem(value: 'all', child: Text('All Categories')),",
         "DropdownMenuItem(value: 'all', child: Text('allCategories'.tr())),"),
        ("const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold))",
         "Text('updateStatusLabel2'.tr(), style: const TextStyle(fontWeight: FontWeight.bold))"),
        ("hintText: 'Enter rejection reason',",
         "hintText: 'enterRejectionReason2'.tr(),"),
    ],
    'screens/admin/admin_profile_screen.dart': [
        ("title: const Text('Admin Profile',",
         "title: Text('adminProfile'.tr(),"),
        ("child: const Text('SUPER ADMIN',",
         "child: Text('superAdmin'.tr(),"),
        ("title: const Text('Legal & Information',",
         "title: Text('legalAndInformation'.tr(),"),
    ],
    'screens/admin/admin_skill_badge_screen.dart': [
        ('const InputDecoration(hintText: "Enter reason for rejection")',
         'InputDecoration(hintText: \'enterReasonForRejection\'.tr())'),
    ],
    'screens/admin/dispute_management_screen.dart': [
        ("const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold))",
         "Text('updateStatusLabel2'.tr(), style: const TextStyle(fontWeight: FontWeight.bold))"),
        ("label: const Text('UNDER REVIEW', style: TextStyle(fontSize: 12))",
         "label: Text('underReviewLabel'.tr(), style: const TextStyle(fontSize: 12))"),
    ],
    'screens/admin/recruiter_kyc_detail_screen.dart': [
        ("title: const Text('Suspend Recruiter',",
         "title: Text('suspendRecruiter'.tr(),"),
        ("const Text('Please provide a reason (min 10 characters):'",
         "Text('provideReasonMin10'.tr()"),
        ("hintText: 'e.g. Invalid documents provided...',",
         "hintText: 'suspendReasonHint'.tr(),"),
        ("title: const Text('Recruiter KYC Details',",
         "title: Text('recruiterKycDetails'.tr(),"),
        ("const Text('Identity Verification',",
         "Text('identityVerification'.tr(),"),
        (": const Center(child: Text('No image uploaded'))",
         ": Center(child: Text('noImageUploaded'.tr()))"),
    ],
    'screens/admin/recruiter_verification_screen.dart': [
        ("title: const Text('Suspend Recruiter',",
         "title: Text('suspendRecruiter'.tr(),"),
        ("const Text('Please provide a reason (min 10 characters):'",
         "Text('provideReasonMin10'.tr()"),
        ("hintText: 'e.g. Suspicious activity detected...',",
         "hintText: 'suspectActivityHint'.tr(),"),
        ("title: const Text('Recruiter Verification',",
         "title: Text('recruiterVerificationTitle'.tr(),"),
    ],
    'screens/admin/withdrawal_management_screen.dart': [
        ("const SnackBar(content: Text('Processed successfully'))",
         "SnackBar(content: Text('processedSuccessfully'.tr()))"),
        ("title: const Text('Withdrawal Requests'),",
         "title: Text('withdrawalRequests'.tr()),"),
        ("return const Center(child: Text('No withdrawal history found.'));",
         "return Center(child: Text('noWithdrawalHistoryFound'.tr()));"),
    ],
    'screens/admin/worker_kyc_detail_screen.dart': [
        ("title: const Text('Reject KYC',",
         "title: Text('rejectKyc'.tr(),"),
        ("const Text('Please provide a reason (min 10 characters):'",
         "Text('provideReasonAadhaar'.tr()"),
        ("hintText: 'e.g. Aadhaar photo is blurred...',",
         "hintText: 'aadhaarBlurredHint'.tr(),"),
        ("title: const Text('Worker KYC Details',",
         "title: Text('workerKycDetails'.tr(),"),
        ("const Text('Aadhaar Verification',",
         "Text('aadhaarVerification'.tr(),"),
        ("label: const Text('Reject KYC')",
         "label: Text('rejectKyc'.tr())"),
        ("label: const Text('Approve KYC')",
         "label: Text('approveKyc'.tr())"),
        (": const Center(child: Text('No image uploaded'))",
         ": Center(child: Text('noImageUploaded'.tr()))"),
    ],
    'screens/auth/add_email_screen.dart': [
        ("content: Text('Email saved successfully!'),",
         "content: Text('emailSavedSuccess'.tr()),"),
        ("hintText: 'Enter your email address',",
         "hintText: 'enterEmailAddress'.tr(),"),
    ],
    'screens/auth/create_new_password_screen.dart': [
        ("content: Text('Password updated successfully! Please login.'),",
         "content: Text('passwordUpdatedPleaseLogin'.tr()),"),
    ],
    'screens/auth/forgot_password_screen.dart': [
        ("hintText: 'yourname@gmail.com',",
         "hintText: 'emailHintGmail'.tr(),"),
        ("label: const Text('Resend Link')",
         "label: Text('resendLink'.tr())"),
    ],
    'screens/auth/kyc_upload_screen.dart': [
        ("label: 'Licence Front',",
         "label: 'licenceFrontLabel'.tr(),"),
        ("label: 'Licence Back',",
         "label: 'licenceBackLabel'.tr(),"),
    ],
    'screens/auth/register_screen.dart': [
        ("hintText: 'e.g. yourname@gmail.com',",
         "hintText: 'emailExampleHint'.tr(),"),
        ("hintText: 'e.g. RAJ4F2',",
         "hintText: 'referralCodeHint'.tr(),"),
    ],
    'screens/auth/verify_otp_screen.dart': [
        ("content: Text('OTP resent successfully'),",
         "content: Text('otpResentSuccess'.tr()),"),
        ("content: Text('Invalid or expired OTP. Please try again.'),",
         "content: Text('invalidExpiredOtp'.tr()),"),
        ("title: const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.bold))",
         "title: Text('verifyOtpTitle'.tr(), style: const TextStyle(fontWeight: FontWeight.bold))"),
    ],
    'screens/chat/chat_detail_screen.dart': [
        ("hintText: 'Type a message...',",
         "hintText: 'typeAMessage'.tr(),"),
    ],
    'screens/chat/chat_list_screen.dart': [
        ("child: Text('No messages yet',",
         "child: Text('noMessagesYet'.tr(),"),
    ],
    'screens/recruiter/edit_profile_screen.dart': [
        ("const InputDecoration(hintText: 'Enter your email')",
         "InputDecoration(hintText: 'enterYourEmail'.tr())"),
        ("const InputDecoration(hintText: 'Enter phone number')",
         "InputDecoration(hintText: 'enterPhoneNumber'.tr())"),
    ],
    'screens/recruiter/post_job_screen.dart': [
        ("const Text('Vehicle Type Required',",
         "Text('vehicleTypeRequired'.tr(),"),
        ("hint: const Text('Select vehicle type'),",
         "hint: Text('selectVehicleTypeHint'.tr()),"),
        ("const Text('Driving License Required',",
         "Text('drivingLicenseRequired'.tr(),"),
        ("hint: const Text('Select license type'),",
         "hint: Text('selectLicenseType'.tr()),"),
        ("const Text('Minimum Experience',",
         "Text('minimumExperience'.tr(),"),
        ("const Text('Trip Type',",
         "Text('tripType'.tr(),"),
        ("const Text('Shift Timing',",
         "Text('shiftTiming'.tr(),"),
        ("const Text('Perks & Requirements',",
         "Text('perksRequirements'.tr(),"),
    ],
    'screens/recruiter/recruiter_applications_screen.dart': [
        ("Text('No applications found', style:",
         "Text('noApplicationsFound'.tr(), style:"),
    ],
    'screens/shared/report_problem_screen.dart': [
        ("hintText: 'Problem Title (e.g. App crashing on login)',",
         "hintText: 'problemTitleHint'.tr(),"),
        ("hintText: 'Detailed description of the bug...',",
         "hintText: 'detailedDescBug'.tr(),"),
    ],
    'screens/worker/driver_profile_screen.dart': [
        ("hintText: 'Years of experience (0–40)',",
         "hintText: 'yearsOfExpHint'.tr(),"),
        ("label: 'Willing to travel outstation?',",
         "label: 'willingTravelOutstation'.tr(),"),
        ("label: 'I have my own vehicle',",
         "label: 'haveOwnVehicle'.tr(),"),
        ("hintText: 'Vehicle Registration Number (e.g. PB01AB1234)',",
         "hintText: 'vehicleRegHint'.tr(),"),
        ("label: 'Driving Licence (Front)',",
         "label: 'drivingLicenceFront'.tr(),"),
        ("label: 'Driving Licence (Back)',",
         "label: 'drivingLicenceBack'.tr(),"),
        ("label: 'Aadhaar Card (Front)',",
         "label: 'aadhaarCardFront'.tr(),"),
        ("label: 'Passport Size Photo',",
         "label: 'passportSizePhoto'.tr(),"),
    ],
    'screens/worker/edit_profile_screen.dart': [
        ("const InputDecoration(hintText: 'Enter your email')",
         "InputDecoration(hintText: 'enterYourEmail'.tr())"),
        ("const InputDecoration(hintText: 'Enter phone number')",
         "InputDecoration(hintText: 'enterPhoneNumber'.tr())"),
    ],
    'screens/worker/job_detail_screen.dart': [
        ('tooltip: "Report Fake Job",',
         "tooltip: 'reportFakeJobTooltip'.tr(),"),
        ("Text('Rating Submitted', style: TextStyle(fontWeight: FontWeight.bold))",
         "Text('ratingSubmittedTitle'.tr(), style: const TextStyle(fontWeight: FontWeight.bold))"),
        ("content: const Text('Thank you for submitting your rating!')",
         "content: Text('thankYouRatingMsg'.tr())"),
    ],
    'widgets/job_filter_sheet.dart': [
        ("Text('Explore Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))",
         "Text('exploreMode'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))"),
        ("Text('See jobs beyond 50km anywhere', style: TextStyle(fontSize: 12, color: AppColors.textMedium))",
         "Text('exploreModeSub'.tr(), style: const TextStyle(fontSize: 12, color: AppColors.textMedium))"),
    ],
    'widgets/rating_dialog.dart': [
        ("hintText: 'Add a comment (optional)',",
         "hintText: 'addCommentOptionalHint'.tr(),"),
    ],
}

fixed = 0
errors = []

for rel_path, replacements in FIXES.items():
    fpath = os.path.join(LIB_DIR, rel_path)
    if not os.path.exists(fpath):
        errors.append(f"File not found: {rel_path}")
        continue
    
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new, 1)
            fixed += 1
        else:
            errors.append(f"  NOT FOUND in {rel_path}: {old[:60]!r}")
    
    if content != original:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Fixed: {rel_path}")

print(f"\n{'='*60}")
print(f"  Fixed {fixed} hardcoded strings")
if errors:
    print(f"\n⚠️  {len(errors)} strings not found (may already be fixed):")
    for e in errors:
        print(e)

#!/usr/bin/env python3
"""
Add all newly identified hardcoded string keys to all language JSON files.
Keys are added to en.json with English values; other languages get the English
value as fallback (to be translated properly later).
"""
import json, os, sys

TRANS_DIR = os.path.dirname(__file__)

# === NEW KEYS TO ADD ===
# format: key -> English value
NEW_KEYS = {
    # Admin screens
    "enterRejectionReason2": "Enter rejection reason",
    "searchByNameDots": "Search by name...",
    "allStatus": "All Status",
    "allCategories": "All Categories",
    "updateStatusLabel2": "Update Status:",
    "adminProfile": "Admin Profile",
    "superAdmin": "SUPER ADMIN",
    "enterReasonForRejection": "Enter reason for rejection",
    "underReviewLabel": "UNDER REVIEW",
    "suspendRecruiter": "Suspend Recruiter",
    "provideReasonMin10": "Please provide a reason (min 10 characters):",
    "suspendReasonHint": "e.g. Invalid documents provided...",
    "recruiterKycDetails": "Recruiter KYC Details",
    "identityVerification": "Identity Verification",
    "noImageUploaded": "No image uploaded",
    "recruiterVerificationTitle": "Recruiter Verification",
    "suspectActivityHint": "e.g. Suspicious activity detected...",
    "processedSuccessfully": "Processed successfully",
    "withdrawalRequests": "Withdrawal Requests",
    "noWithdrawalHistoryFound": "No withdrawal history found.",
    "rejectKyc": "Reject KYC",
    "provideReasonAadhaar": "Please provide a reason (min 10 characters):",
    "aadhaarBlurredHint": "e.g. Aadhaar photo is blurred...",
    "workerKycDetails": "Worker KYC Details",
    "aadhaarVerification": "Aadhaar Verification",
    "approveKyc": "Approve KYC",
    # Auth screens
    "emailSavedSuccess": "Email saved successfully!",
    "enterEmailAddress": "Enter your email address",
    "passwordUpdatedPleaseLogin": "Password updated successfully! Please login.",
    "emailHintGmail": "yourname@gmail.com",
    "resendLink": "Resend Link",
    "licenceFrontLabel": "Licence Front",
    "licenceBackLabel": "Licence Back",
    "emailExampleHint": "e.g. yourname@gmail.com",
    "referralCodeHint": "e.g. RAJ4F2",
    "otpResentSuccess": "OTP resent successfully",
    "failedResendOtp": "Failed to resend OTP",
    "invalidExpiredOtp": "Invalid or expired OTP. Please try again.",
    "verifyOtpTitle": "Verify OTP",
    # Chat
    "uploadingVoiceMessage": "Uploading voice message...",
    "voiceMessage": "Voice Message",
    "typeAMessage": "Type a message...",
    "noMessagesYet": "No messages yet",
    # Recruiter screens
    "enterYourEmail": "Enter your email",
    "enterPhoneNumber": "Enter phone number",
    "vehicleTypeRequired": "Vehicle Type Required",
    "selectVehicleTypeHint": "Select vehicle type",
    "drivingLicenseRequired": "Driving License Required",
    "selectLicenseType": "Select license type",
    "minimumExperience": "Minimum Experience",
    "tripType": "Trip Type",
    "shiftTiming": "Shift Timing",
    "perksRequirements": "Perks & Requirements",
    "noApplicationsFound": "No applications found",
    # Shared
    "problemTitleHint": "Problem Title (e.g. App crashing on login)",
    "detailedDescBug": "Detailed description of the bug...",
    # Driver profile
    "yearsOfExpHint": "Years of experience (0–40)",
    "willingTravelOutstation": "Willing to travel outstation?",
    "haveOwnVehicle": "I have my own vehicle",
    "vehicleRegHint": "Vehicle Registration Number (e.g. PB01AB1234)",
    "drivingLicenceFront": "Driving Licence (Front)",
    "drivingLicenceBack": "Driving Licence (Back)",
    "aadhaarCardFront": "Aadhaar Card (Front)",
    "passportSizePhoto": "Passport Size Photo",
    # Job detail
    "reportFakeJobTooltip": "Report Fake Job",
    "ratingSubmittedTitle": "Rating Submitted",
    "thankYouRatingMsg": "Thank you for submitting your rating!",
    # Widgets
    "jobColon": "Job",
    "exploreModeSub": "See jobs beyond 50km anywhere",
    "addCommentOptionalHint": "Add a comment (optional)",
}

# Load all language files
lang_files = [f for f in os.listdir(TRANS_DIR) if f.endswith('.json') and f[0].isalpha() and len(f) <= 8]
print(f"Found language files: {lang_files}")

added_count = {lang: 0 for lang in lang_files}

for lang_file in lang_files:
    fpath = os.path.join(TRANS_DIR, lang_file)
    with open(fpath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    is_english = lang_file == 'en.json'
    
    for key, en_value in NEW_KEYS.items():
        if key not in data:
            # For English, use the actual value; for others, use English as fallback
            data[key] = en_value
            added_count[lang_file] += 1
    
    with open(fpath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("\n=== Keys Added Per Language File ===")
for lang, count in added_count.items():
    print(f"  {lang}: +{count} keys")

print(f"\nTotal new keys: {len(NEW_KEYS)}")
print("Done! Now regenerate locale_keys.g.dart and update Dart files.")

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kaamkaaz'**
  String get appName;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get applied;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @postJob.
  ///
  /// In en, this message translates to:
  /// **'Post Job'**
  String get postJob;

  /// No description provided for @myJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get myJobs;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @passwordRequirementWarning.
  ///
  /// In en, this message translates to:
  /// **'Use a strong password: at least 6 characters with a mix of letters and numbers.'**
  String get passwordRequirementWarning;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @applicants.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get applicants;

  /// No description provided for @noJobsNearby.
  ///
  /// In en, this message translates to:
  /// **'No jobs found nearby'**
  String get noJobsNearby;

  /// No description provided for @noApplications.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get noApplications;

  /// No description provided for @noJobsPosted.
  ///
  /// In en, this message translates to:
  /// **'No jobs posted yet'**
  String get noJobsPosted;

  /// No description provided for @myApplications.
  ///
  /// In en, this message translates to:
  /// **'My Applications'**
  String get myApplications;

  /// No description provided for @rateWorker.
  ///
  /// In en, this message translates to:
  /// **'Rate Worker'**
  String get rateWorker;

  /// No description provided for @rateRecruiter.
  ///
  /// In en, this message translates to:
  /// **'Rate Recruiter'**
  String get rateRecruiter;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markCompleted;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Application'**
  String get withdraw;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @jobsDone.
  ///
  /// In en, this message translates to:
  /// **'Jobs Done'**
  String get jobsDone;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your language'**
  String get selectLanguage;

  /// No description provided for @jobDesc.
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get jobDesc;

  /// No description provided for @sitePhotos.
  ///
  /// In en, this message translates to:
  /// **'Site Photos'**
  String get sitePhotos;

  /// No description provided for @workersSoon.
  ///
  /// In en, this message translates to:
  /// **'Workers will apply soon!'**
  String get workersSoon;

  /// No description provided for @tapToPost.
  ///
  /// In en, this message translates to:
  /// **'Tap + to post your first job'**
  String get tapToPost;

  /// No description provided for @expandRadius.
  ///
  /// In en, this message translates to:
  /// **'Try expanding search radius'**
  String get expandRadius;

  /// No description provided for @showingNearby.
  ///
  /// In en, this message translates to:
  /// **'Showing nearby jobs'**
  String get showingNearby;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @welcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get welcomeSub;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @demoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Demo Accounts'**
  String get demoAccounts;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get saved;

  /// No description provided for @workerSince.
  ///
  /// In en, this message translates to:
  /// **'Worker Since'**
  String get workerSince;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP will be sent to your number'**
  String get otpSentTo;

  /// No description provided for @passwordTab.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordTab;

  /// No description provided for @otpTab.
  ///
  /// In en, this message translates to:
  /// **'OTP Login'**
  String get otpTab;

  /// No description provided for @languageTab.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTab;

  /// No description provided for @loginWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Login with Password'**
  String get loginWithPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @referrals.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referrals;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn ₹5'**
  String get referAndEarn;

  /// No description provided for @totalReferred.
  ///
  /// In en, this message translates to:
  /// **'Total Referred'**
  String get totalReferred;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get yourReferralCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @shareOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get shareOnWhatsapp;

  /// No description provided for @referredFriends.
  ///
  /// In en, this message translates to:
  /// **'Referred Friends'**
  String get referredFriends;

  /// No description provided for @haveReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Have a referral code? (Optional)'**
  String get haveReferralCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get codeCopied;

  /// No description provided for @joinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined on: '**
  String get joinedOn;

  /// No description provided for @skillBadges.
  ///
  /// In en, this message translates to:
  /// **'Skill Badges 🏅'**
  String get skillBadges;

  /// No description provided for @myBadges.
  ///
  /// In en, this message translates to:
  /// **'My Badges'**
  String get myBadges;

  /// No description provided for @requestNewBadge.
  ///
  /// In en, this message translates to:
  /// **'Request New Badge'**
  String get requestNewBadge;

  /// No description provided for @selectSkillToVerify.
  ///
  /// In en, this message translates to:
  /// **'Select skill to verify'**
  String get selectSkillToVerify;

  /// No description provided for @uploadDocumentOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload Proof (Optional)'**
  String get uploadDocumentOptional;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @statusPendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get statusPendingBadge;

  /// No description provided for @statusVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified Skill'**
  String get statusVerifiedBadge;

  /// No description provided for @statusRejectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verification Rejected'**
  String get statusRejectedBadge;

  /// No description provided for @alreadyRequested.
  ///
  /// In en, this message translates to:
  /// **'Badge already requested'**
  String get alreadyRequested;

  /// No description provided for @badgeUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Your request is under review'**
  String get badgeUnderReview;

  /// No description provided for @viewProof.
  ///
  /// In en, this message translates to:
  /// **'View Proof'**
  String get viewProof;

  /// No description provided for @verifiedBadgeNote.
  ///
  /// In en, this message translates to:
  /// **'This skill is verified by Kaamkaaz team'**
  String get verifiedBadgeNote;

  /// No description provided for @jobPostingFee.
  ///
  /// In en, this message translates to:
  /// **'Job Posting Fee'**
  String get jobPostingFee;

  /// No description provided for @platformFeeNote.
  ///
  /// In en, this message translates to:
  /// **'Platform fee: ₹29 (one-time)'**
  String get platformFeeNote;

  /// No description provided for @payAndPost.
  ///
  /// In en, this message translates to:
  /// **'Pay ₹29 & Post Job'**
  String get payAndPost;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @paymentId.
  ///
  /// In en, this message translates to:
  /// **'Payment ID: '**
  String get paymentId;

  /// No description provided for @paidBadge.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidBadge;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @retryPayment.
  ///
  /// In en, this message translates to:
  /// **'Retry Payment'**
  String get retryPayment;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search for jobs...'**
  String get searchPlaceholder;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @dailyWage.
  ///
  /// In en, this message translates to:
  /// **'Daily Wage'**
  String get dailyWage;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @jobType.
  ///
  /// In en, this message translates to:
  /// **'Job Type'**
  String get jobType;

  /// No description provided for @urgentOnly.
  ///
  /// In en, this message translates to:
  /// **'Urgent Only'**
  String get urgentOnly;

  /// No description provided for @allJobs.
  ///
  /// In en, this message translates to:
  /// **'All Jobs'**
  String get allJobs;

  /// No description provided for @driverJobsOnly.
  ///
  /// In en, this message translates to:
  /// **'Driver Jobs Only'**
  String get driverJobsOnly;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @noJobsFound.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get noJobsFound;

  /// No description provided for @adjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get adjustFilters;

  /// No description provided for @errSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errSomethingWrong;

  /// No description provided for @recruiterOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Recruiter Onboarding'**
  String get recruiterOnboarding;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name (Optional)'**
  String get businessName;

  /// No description provided for @areaOfOperation.
  ///
  /// In en, this message translates to:
  /// **'Area of Operation'**
  String get areaOfOperation;

  /// No description provided for @purposeNote.
  ///
  /// In en, this message translates to:
  /// **'Purpose of hiring?'**
  String get purposeNote;

  /// No description provided for @submitOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitOnboarding;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountSuspended;

  /// No description provided for @suspendedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get suspendedReason;

  /// No description provided for @recruiterVerificationAlert.
  ///
  /// In en, this message translates to:
  /// **'Recruiters must be verified to post jobs.'**
  String get recruiterVerificationAlert;

  /// No description provided for @adminAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Admin Analytics'**
  String get adminAnalytics;

  /// No description provided for @totalWorkers.
  ///
  /// In en, this message translates to:
  /// **'Total Workers'**
  String get totalWorkers;

  /// No description provided for @totalRecruiters.
  ///
  /// In en, this message translates to:
  /// **'Total Recruiters'**
  String get totalRecruiters;

  /// No description provided for @jobsToday.
  ///
  /// In en, this message translates to:
  /// **'Jobs Today'**
  String get jobsToday;

  /// No description provided for @totalHires.
  ///
  /// In en, this message translates to:
  /// **'Total Hires'**
  String get totalHires;

  /// No description provided for @totalApplications.
  ///
  /// In en, this message translates to:
  /// **'Total Applications'**
  String get totalApplications;

  /// No description provided for @activeDisputes.
  ///
  /// In en, this message translates to:
  /// **'Active Disputes'**
  String get activeDisputes;

  /// No description provided for @registrationTrend.
  ///
  /// In en, this message translates to:
  /// **'Registration Trend'**
  String get registrationTrend;

  /// No description provided for @jobsByCategory.
  ///
  /// In en, this message translates to:
  /// **'Jobs by Category'**
  String get jobsByCategory;

  /// No description provided for @topAreas.
  ///
  /// In en, this message translates to:
  /// **'Top Areas'**
  String get topAreas;

  /// No description provided for @platformHealth.
  ///
  /// In en, this message translates to:
  /// **'Platform Health'**
  String get platformHealth;

  /// No description provided for @kycApprovalTime.
  ///
  /// In en, this message translates to:
  /// **'Avg KYC Approval Time'**
  String get kycApprovalTime;

  /// No description provided for @neverApplied.
  ///
  /// In en, this message translates to:
  /// **'Workers Never Applied'**
  String get neverApplied;

  /// No description provided for @zeroApplicants.
  ///
  /// In en, this message translates to:
  /// **'Jobs with 0 Applicants'**
  String get zeroApplicants;

  /// No description provided for @updatedMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated %s mins ago'**
  String get updatedMinsAgo;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @driverProfile.
  ///
  /// In en, this message translates to:
  /// **'Driver Profile'**
  String get driverProfile;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @totalApplied.
  ///
  /// In en, this message translates to:
  /// **'Total Applied'**
  String get totalApplied;

  /// No description provided for @hired.
  ///
  /// In en, this message translates to:
  /// **'Hired'**
  String get hired;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @lastHired.
  ///
  /// In en, this message translates to:
  /// **'Last Hired: '**
  String get lastHired;

  /// No description provided for @totalTimesHired.
  ///
  /// In en, this message translates to:
  /// **'Total Times Hired: '**
  String get totalTimesHired;

  /// No description provided for @reInvite.
  ///
  /// In en, this message translates to:
  /// **'Re-Invite'**
  String get reInvite;

  /// No description provided for @selectJob.
  ///
  /// In en, this message translates to:
  /// **'Select Job'**
  String get selectJob;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation Sent'**
  String get invitationSent;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get statusWithdrawn;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @disputeBanner.
  ///
  /// In en, this message translates to:
  /// **'Active Dispute Pending'**
  String get disputeBanner;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @raiseDispute.
  ///
  /// In en, this message translates to:
  /// **'Dispute Management'**
  String get raiseDispute;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReview;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get statusDismissed;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @adminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin Note'**
  String get adminNote;

  /// No description provided for @adminNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin note is required'**
  String get adminNoteRequired;

  /// No description provided for @noDisputes.
  ///
  /// In en, this message translates to:
  /// **'No disputes found'**
  String get noDisputes;

  /// No description provided for @markUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get markUnderReview;

  /// No description provided for @paymentNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment not received'**
  String get paymentNotReceived;

  /// No description provided for @workerNoShow.
  ///
  /// In en, this message translates to:
  /// **'Worker did not show up'**
  String get workerNoShow;

  /// No description provided for @wrongJobDesc.
  ///
  /// In en, this message translates to:
  /// **'Wrong job description'**
  String get wrongJobDesc;

  /// No description provided for @workQualityIssue.
  ///
  /// In en, this message translates to:
  /// **'Work quality issue'**
  String get workQualityIssue;

  /// No description provided for @unsafeConditions.
  ///
  /// In en, this message translates to:
  /// **'Unsafe working conditions'**
  String get unsafeConditions;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @myDisputes.
  ///
  /// In en, this message translates to:
  /// **'My Disputes'**
  String get myDisputes;

  /// No description provided for @disputeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Dispute Submitted'**
  String get disputeSubmitted;

  /// No description provided for @disputeSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Our team will review your case and get back to you within 24-48 hours.'**
  String get disputeSuccessMsg;

  /// No description provided for @disputeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category of Dispute'**
  String get disputeCategory;

  /// No description provided for @disputeDesc.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get disputeDesc;

  /// No description provided for @submitDispute.
  ///
  /// In en, this message translates to:
  /// **'Submit Dispute'**
  String get submitDispute;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// No description provided for @driverKycQueue.
  ///
  /// In en, this message translates to:
  /// **'Driver KYC Queue'**
  String get driverKycQueue;

  /// No description provided for @findDrivers.
  ///
  /// In en, this message translates to:
  /// **'Find Drivers'**
  String get findDrivers;

  /// No description provided for @jobsPosted.
  ///
  /// In en, this message translates to:
  /// **'Jobs Posted'**
  String get jobsPosted;

  /// No description provided for @noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'No badges yet'**
  String get noBadgesYet;

  /// No description provided for @pastWorkers.
  ///
  /// In en, this message translates to:
  /// **'Past Workers'**
  String get pastWorkers;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @whatKindOfWork.
  ///
  /// In en, this message translates to:
  /// **'What kind of work?'**
  String get whatKindOfWork;

  /// No description provided for @kycUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Documents'**
  String get kycUploadTitle;

  /// No description provided for @aadhaarFront.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Front Side'**
  String get aadhaarFront;

  /// No description provided for @aadhaarBack.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Back Side'**
  String get aadhaarBack;

  /// No description provided for @livePhoto.
  ///
  /// In en, this message translates to:
  /// **'Live Photo (Selfie)'**
  String get livePhoto;

  /// No description provided for @drivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving Licence'**
  String get drivingLicence;

  /// No description provided for @expYears.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get expYears;

  /// No description provided for @submitKyc.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitKyc;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @aadhaarNotice.
  ///
  /// In en, this message translates to:
  /// **'Your Aadhaar is only used for verification and is never shared with workers'**
  String get aadhaarNotice;

  /// No description provided for @aadhaarFrontPhoto.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card - Front Photo'**
  String get aadhaarFrontPhoto;

  /// No description provided for @aadhaarBackPhoto.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card - Back Photo'**
  String get aadhaarBackPhoto;

  /// No description provided for @liveSelfie.
  ///
  /// In en, this message translates to:
  /// **'Live Selfie'**
  String get liveSelfie;

  /// No description provided for @selfieCaptured.
  ///
  /// In en, this message translates to:
  /// **'Selfie captured'**
  String get selfieCaptured;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @resetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetYourPassword;

  /// No description provided for @enterRegisteredPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered mobile number. We\'ll send you an OTP to reset your password.'**
  String get enterRegisteredPhone;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @enterOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP sent to +91 {phone}'**
  String enterOtpSentTo(String phone);

  /// No description provided for @resendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {timer}'**
  String resendOtpIn(String timer);

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create new password'**
  String get createNewPassword;

  /// No description provided for @newPasswordMustBe6Chars.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be at least 6 characters'**
  String get newPasswordMustBe6Chars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password Reset Successfully!'**
  String get passwordResetSuccess;

  /// No description provided for @canLoginWithNewPassword.
  ///
  /// In en, this message translates to:
  /// **'You can now login with your new password.'**
  String get canLoginWithNewPassword;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @resetLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'Reset link expired'**
  String get resetLinkExpired;

  /// No description provided for @pleaseStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Please start the process again.'**
  String get pleaseStartAgain;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordLink;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @villageCity.
  ///
  /// In en, this message translates to:
  /// **'Village/City'**
  String get villageCity;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @userInformation.
  ///
  /// In en, this message translates to:
  /// **'USER INFORMATION'**
  String get userInformation;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'SKILLS'**
  String get skills;

  /// No description provided for @noSkillsAdded.
  ///
  /// In en, this message translates to:
  /// **'No skills added'**
  String get noSkillsAdded;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteMyAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your profile, documents, and job history. This action cannot be undone.'**
  String get deleteAccountDesc;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete My Account'**
  String get yesDelete;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @namaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste, '**
  String get namaste;

  /// No description provided for @kaamgar.
  ///
  /// In en, this message translates to:
  /// **'Kaamgar'**
  String get kaamgar;

  /// No description provided for @setLocation.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get setLocation;

  /// No description provided for @kycPendingAdminReview.
  ///
  /// In en, this message translates to:
  /// **'KYC PENDING — ADMIN REVIEW'**
  String get kycPendingAdminReview;

  /// No description provided for @verifiedWorker.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED WORKER'**
  String get verifiedWorker;

  /// No description provided for @chatWithRecruiters.
  ///
  /// In en, this message translates to:
  /// **'Chat with Recruiters'**
  String get chatWithRecruiters;

  /// No description provided for @driverKycIncomplete.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Driver KYC Incomplete. Tap to finish.'**
  String get driverKycIncomplete;

  /// No description provided for @driverKycUnderReview.
  ///
  /// In en, this message translates to:
  /// **'⏳ Driver KYC under review...'**
  String get driverKycUnderReview;

  /// No description provided for @driverKycRejected.
  ///
  /// In en, this message translates to:
  /// **'❌ Driver KYC Rejected. Tap to fix.'**
  String get driverKycRejected;

  /// No description provided for @legalAndInfo.
  ///
  /// In en, this message translates to:
  /// **'LEGAL & INFO'**
  String get legalAndInfo;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @communityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Community Guidelines'**
  String get communityGuidelines;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get reportProblem;

  /// No description provided for @kycVerified.
  ///
  /// In en, this message translates to:
  /// **'✅ KYC Verified'**
  String get kycVerified;

  /// No description provided for @kycStatusPrefix.
  ///
  /// In en, this message translates to:
  /// **'⏳ KYC '**
  String get kycStatusPrefix;

  /// No description provided for @recruiter.
  ///
  /// In en, this message translates to:
  /// **'Recruiter'**
  String get recruiter;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'LATEST VERSION INSTALLED ✅'**
  String get latestVersion;

  /// No description provided for @hireVerifiedDrivers.
  ///
  /// In en, this message translates to:
  /// **'Hire verified drivers nearby'**
  String get hireVerifiedDrivers;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get topRated;

  /// No description provided for @bestWorkersNearby.
  ///
  /// In en, this message translates to:
  /// **'Best workers nearby'**
  String get bestWorkersNearby;

  /// No description provided for @rehireTrustedWorkers.
  ///
  /// In en, this message translates to:
  /// **'Rehire your trusted workers'**
  String get rehireTrustedWorkers;

  /// No description provided for @noJobsPostedYet.
  ///
  /// In en, this message translates to:
  /// **'No jobs posted yet'**
  String get noJobsPostedYet;

  /// No description provided for @tapPlusToPost.
  ///
  /// In en, this message translates to:
  /// **'Tap + to post your first job'**
  String get tapPlusToPost;

  /// No description provided for @deleteJob.
  ///
  /// In en, this message translates to:
  /// **'Delete Job?'**
  String get deleteJob;

  /// No description provided for @deleteJobConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this job? This action cannot be undone.'**
  String get deleteJobConfirm;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @jobDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job deleted successfully'**
  String get jobDeletedSuccess;

  /// No description provided for @failedToDeleteJob.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete job'**
  String get failedToDeleteJob;

  /// No description provided for @kycNotApprovedApplied.
  ///
  /// In en, this message translates to:
  /// **'Your basic KYC is not approved yet. Please wait for admin verification.'**
  String get kycNotApprovedApplied;

  /// No description provided for @onlyDriversCanApply.
  ///
  /// In en, this message translates to:
  /// **'Only Drivers can apply for this job.'**
  String get onlyDriversCanApply;

  /// No description provided for @driverKycNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Your Driver KYC is not verified. Please complete it in your profile.'**
  String get driverKycNotVerified;

  /// No description provided for @applyForJob.
  ///
  /// In en, this message translates to:
  /// **'Apply for Job'**
  String get applyForJob;

  /// No description provided for @writeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message to recruiter (optional)'**
  String get writeMessageHint;

  /// No description provided for @appliedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Applied successfully! ✅ Recruiter notified.'**
  String get appliedSuccessfully;

  /// No description provided for @failedToApply.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply'**
  String get failedToApply;

  /// No description provided for @jobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job not found'**
  String get jobNotFound;

  /// No description provided for @wage.
  ///
  /// In en, this message translates to:
  /// **'Wage'**
  String get wage;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @addressNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Address not specified'**
  String get addressNotSpecified;

  /// No description provided for @appliedCount.
  ///
  /// In en, this message translates to:
  /// **'applied'**
  String get appliedCount;

  /// No description provided for @requiredVehicle.
  ///
  /// In en, this message translates to:
  /// **'Required Vehicle'**
  String get requiredVehicle;

  /// No description provided for @mustHaveOwnVehicle.
  ///
  /// In en, this message translates to:
  /// **'Own Vehicle?'**
  String get mustHaveOwnVehicle;

  /// No description provided for @yesRequired.
  ///
  /// In en, this message translates to:
  /// **'Yes, required'**
  String get yesRequired;

  /// No description provided for @noProvidedByRecruiter.
  ///
  /// In en, this message translates to:
  /// **'No, provided by recruiter'**
  String get noProvidedByRecruiter;

  /// No description provided for @outstationRequired.
  ///
  /// In en, this message translates to:
  /// **'Outstation?'**
  String get outstationRequired;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'No, local only'**
  String get localOnly;

  /// No description provided for @requiredSkills.
  ///
  /// In en, this message translates to:
  /// **'Required Skills'**
  String get requiredSkills;

  /// No description provided for @rateRecruiterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How was your experience working for {name}?'**
  String rateRecruiterSubtitle(Object name);

  /// No description provided for @ratingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'🌟 Rating submitted!'**
  String get ratingSubmitted;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open Maps'**
  String get couldNotOpenMaps;

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted ✅'**
  String get applicationSubmitted;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit number'**
  String get phoneHint;

  /// No description provided for @phoneError.
  ///
  /// In en, this message translates to:
  /// **'Enter valid 10-digit number'**
  String get phoneError;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get passwordHint;

  /// No description provided for @passwordError.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get passwordError;

  /// No description provided for @applyForThisJob.
  ///
  /// In en, this message translates to:
  /// **'Apply for this Job'**
  String get applyForThisJob;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @driverRequirements.
  ///
  /// In en, this message translates to:
  /// **'Driver Requirements'**
  String get driverRequirements;

  /// No description provided for @daysWorked.
  ///
  /// In en, this message translates to:
  /// **'Days Worked'**
  String get daysWorked;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

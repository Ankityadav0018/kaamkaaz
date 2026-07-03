class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'https://kaamkaaz-q1ep.onrender.com/api';

  // Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String supabaseVerify = '/auth/supabase-verify';
  static const String adminLogin = '/admin/auth/login';
  static const String adminVerifyOtp = '/admin/auth/verify-otp';
  static const String adminSetupPhone = '/admin/auth/setup-phone';
  static const String supabaseResetPassword = '/auth/supabase-reset-password';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String checkEmail = '/auth/check-email';
  static const String addEmail = '/auth/add-email';
  static const String updateLocation = '/auth/location';
  static const String updateFcmToken = '/users/fcm-token';
  static const String updateKyc = '/auth/kyc';
  static const String deleteAccount = '/auth/delete-account';
  static const String changePassword = '/auth/change-password';

  static const String nearbyJobs = '/jobs/nearby';
  static const String myJobs = '/jobs/my-jobs';
  static const String jobDetail = '/jobs'; // + /:id
  static const String jobStatus = '/jobs'; // + /:id/status
  static const String jobShareText = '/jobs'; // + /:id/share-text

  static const String applications = '/applications';
  static const String myApplications = '/applications/my-applications';
  static const String recruiterAllApplications = '/applications/recruiter/all';
  static const String jobApplications = '/applications/job'; // + /:jobId
  static const String acceptApplication = '/applications'; // + /:id/accept
  static const String rejectApplication = '/applications'; // + /:id/reject
  static const String workerProfileFromApp =
      '/applications'; // + /:id/worker-profile

  static const String notifications = '/notifications';
  static const String markAllRead = '/notifications/read-all';

  static const String adminStats = '/admin/stats';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminUsers = '/admin/users';
  static const String adminKycPending = '/admin/kyc-pending';
  static const String adminJobs = '/admin/jobs';
  static const String adminKycReview = '/admin/kyc'; // + /:id
  static const String adminToggleBlock = '/admin/users'; // + /:userId/block
  static const String adminPendingWithdrawals = '/admin/withdrawals/pending';
  static const String adminWithdrawalHistory = '/admin/withdrawals/history';
  static const String adminProcessWithdrawal =
      '/admin/withdrawals'; // + /:transactionId/process

  static const String socketUrl = 'https://kaamkaaz-q1ep.onrender.com';

  // Driver
  static const String driverProfile = '/driver/profile';
  static const String uploadDriverDoc = '/driver/upload-document';
  static const String nearbyDrivers = '/driver/nearby';
  static const String adminDriverKyc = '/admin/driver-kyc';
  static const String driverKycPending = '/driver/kyc/pending';
  static const String adminDriverKycReview = '/driver/kyc/review'; // + /:userId
  static const String driverPublicProfile = '/driver'; // + /:id

  // Shared
  static const String publicProfile = '/users/public'; // + /:id
  static const String userSearch = '/users/search';
  static const String toggleUrgentAlerts = '/users/toggle-urgent-alerts';

  // Disputes
  static const String disputes = '/disputes';
  static const String myDisputes = '/disputes/my';
  static const String adminDisputes = '/admin/disputes';
  static const String adminDisputeStats = '/admin/disputes/stats';

  // Ratings
  static const String ratings = '/ratings';
  static const String userRatings = '/ratings/user'; // + /:userId

  // Worker
  static const String workerStats = '/worker/stats';
  static const String workerApplications = '/worker/applications';
  // Recruiter
  static const String recruiterStats = '/recruiter/stats';
  static const String healthCheck = '/health';
  static const String pastWorkers = '/recruiter/past-workers';
  static const String reinviteWorker = '/recruiter/reinvite';

  // Referral
  static const String myReferral = '/referral/my-code';
  static const String referralStats = '/referral/stats';
  static const String applyReferral = '/referral/apply';
  static const String referralTransactions = '/referral/transactions';
  static const String withdrawReferral = '/referral/withdraw';
  static const String shareText = '/referral/share-text';

  // Reports
  static const String reports = '/reports';

  // SOS
  static const String triggerSos = '/sos';
  static const String adminSosAlerts = '/admin/sos';  // + /:id for PATCH

  // Chat
  static const String chatInbox = '/chat/inbox';
  static const String chatThread = '/chat'; // + /:jobId/:otherUserId

  // Upload
  static const String uploadSignature = '/upload/signature';

  // Skill Badges
  static const String requestBadge = '/skill-badges/request';
  static const String myBadges = '/skill-badges/my';
  static const String adminPendingBadges = '/skill-badges/admin/pending';
  static const String adminUpdateBadge = '/skill-badges/admin'; // + /:id

  // Recruiter Verification
  static const String recruiterOnboarding = '/recruiter/onboarding';
  static const String recruiterVerificationStatus =
      '/recruiter/verification-status';
  static const String adminPendingRecruiters = '/admin/recruiters/pending';
  static const String adminVerifyRecruiter =
      '/admin/recruiters'; // + /:userId/verify
  static const String adminRecruiterDetails = '/admin/recruiters'; // + /:userId
}

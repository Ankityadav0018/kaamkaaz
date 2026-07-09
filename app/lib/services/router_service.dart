import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/verify_otp_screen.dart';
import '../screens/auth/admin_otp_screen.dart';
import '../screens/auth/admin_phone_setup_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/set_pin_screen.dart';

// TODO: OTP screens temporarily disabled
// import '../screens/auth/otp_screen.dart';
// import '../screens/auth/mobile_input_screen.dart';
import '../screens/auth/kyc_upload_screen.dart';
import '../screens/auth/add_email_screen.dart';
import '../screens/worker/worker_home_screen.dart';
import '../screens/worker/notification_settings_screen.dart';
import '../screens/worker/job_detail_screen.dart';
import '../screens/worker/my_jobs_screen.dart';
import '../screens/worker/worker_applications_screen.dart';
import '../screens/worker/driver_kyc_status_screen.dart';
import '../screens/worker/driver_profile_screen.dart';
import '../screens/recruiter/recruiter_home_screen.dart';
import '../screens/recruiter/post_job_screen.dart';
import '../screens/recruiter/credits_screen.dart';
import '../screens/recruiter/manage_applicants_screen.dart';
import '../screens/recruiter/worker_profile_screen.dart';
import '../screens/recruiter/driver_public_profile_screen.dart';
import '../screens/recruiter/past_workers_screen.dart';
import '../screens/recruiter/find_drivers_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/shared/referral_screen.dart';
import '../screens/admin/driver_kyc_queue_screen.dart';
import '../screens/admin/withdrawal_management_screen.dart';
import '../screens/public_profile_screen.dart';
import '../screens/search_profiles_screen.dart';
import '../screens/worker/worker_profile_screen.dart';
import '../screens/worker/edit_profile_screen.dart';
import '../screens/worker/portfolio_manager_screen.dart';
import '../providers/language_provider.dart';
import '../screens/recruiter/recruiter_profile_screen.dart';
import '../screens/recruiter/edit_profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../models/job_model.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../screens/shared/raise_dispute_screen.dart';
import '../screens/shared/my_disputes_screen.dart';
import '../screens/worker/skill_badge_screen.dart';
import '../screens/shared/report_problem_screen.dart';
import 'package:kaamkaaz/screens/admin/admin_skill_badge_screen.dart';
import 'package:kaamkaaz/screens/admin/dispute_management_screen.dart';
import 'package:kaamkaaz/screens/recruiter/recruiter_onboarding_screen.dart';
import 'package:kaamkaaz/screens/recruiter/verification_pending_screen.dart';
import 'package:kaamkaaz/screens/recruiter/suspended_screen.dart';
import 'package:kaamkaaz/screens/admin/recruiter_verification_screen.dart';
import '../screens/shared/change_password_screen.dart';
import '../services/api_service.dart';
import '../screens/shared/language_selection_screen.dart';
import '../screens/worker/urgent_alert_screen.dart';

import '../screens/admin/worker_kyc_detail_screen.dart';
import '../screens/admin/recruiter_kyc_detail_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/create_new_password_screen.dart';
import '../screens/admin/admin_kyc_screen.dart';
import '../utils/app_keys.dart';
import '../screens/app_tour_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create a provider for shared preferences
final sharedPrefsProvider = Provider<SharedPreferences?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.read(routerNotifierProvider);

  // Global unauthorized handler — only for non-admin routes
  ApiService.onUnauthorized = () {
    final authState = ref.read(authProvider);
    if (!authState.isInitialized || authState.user == null) {
      return; // Prevent showing snackbar during startup or if already logged out
    }
    ref.read(authProvider.notifier).logout();
    AppKeys.messengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('🔑 Session expired. Please login again.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  };

  // Admin session expired — don't log the user out, just show a re-auth prompt
  ApiService.onAdminSessionExpired = () {
    final authState = ref.read(authProvider);
    if (!authState.isInitialized || authState.user == null) return;
    AppKeys.messengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('🔐 Admin session expired. Please log in as admin again.'),
        backgroundColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 5),
      ),
    );
    // Navigate to admin login instead of full sign-out
    AppKeys.rootNavigatorKey.currentContext?.go('/auth/login');
  };

  return GoRouter(
    navigatorKey: AppKeys.rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      if (!authState.isInitialized) return '/splash';

      final user = authState.user;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation.startsWith('/forgot-password');

      final isSplash = state.matchedLocation == '/splash';
      final isKycRoute = state.matchedLocation == '/auth/kyc';
      final isAddEmailRoute = state.matchedLocation == '/auth/add-email';
      final isLanguageRoute = state.matchedLocation == '/language';

      // Force language selection if not selected yet (Removed as per user request)
      // if (!ref.read(languageProvider).hasSelectedLanguage && !isLanguageRoute) {
      //   return '/language';
      // }

      if (isLoggedIn) {
        // Enforce forced PIN setup if user tapped "Forgot PIN" previously
        final prefs = ref.read(sharedPrefsProvider);
        if (prefs?.getBool('needs_pin_setup') == true) {
          if (state.matchedLocation != '/set-pin') return '/set-pin';
          return null; // Stay on set-pin, do not evaluate email/kyc yet
        }

        // 1. Enforce Email Requirement
        if (user.email.isEmpty && !isAddEmailRoute) {
          // If the user tries to logout, we must allow it (logout goes to /auth/login, so it clears user first)
          // Since user is not null here, they are still logged in.
          return '/auth/add-email';
        }

        // If on Add Email screen but email is already provided
        if (isAddEmailRoute && user.email.isNotEmpty) {
          return '/'; 
        }

        // 2. Enforce KYC for workers if not submitted
        if (user.isWorker && user.isKycNotSubmitted && !isAddEmailRoute) {
          if (!isKycRoute) return '/auth/kyc';
          return null; // Already on KYC screen, stay here
        }
        
        // Enforce KYC for recruiters if not submitted
        if (user.isRecruiter && user.isRecruiterNotSubmitted && !isAddEmailRoute) {
          if (state.matchedLocation != '/recruiter/onboarding') return '/recruiter/onboarding';
          return null; // Already on onboarding screen, stay here
        }

        // If on KYC screen but already done (and not rejected), go to home
        if (isKycRoute && !user.isKycNotSubmitted && !user.isKycRejected) {
          final role = user.role;
          if (role == 'worker') return '/worker';
          if (role == 'recruiter') return '/recruiter';
          if (role == 'admin') return '/admin';
        }

        // If on Recruiter Onboarding screen but already done, go to home
        final isOnboardingRoute = state.matchedLocation == '/recruiter/onboarding';
        if (isOnboardingRoute && !user.isRecruiterNotSubmitted && !user.isRecruiterSuspended) {
          return '/recruiter';
        }

        if ((isSplash || isAuthRoute) && !isKycRoute && !isAddEmailRoute) {
          final role = user.role;
          if (role == 'worker') return '/worker';
          if (role == 'recruiter') {
            if (user.isRecruiterSuspended) return '/recruiter/suspended';
            return '/recruiter';
          }
          if (role == 'admin') return '/admin';
        }
      } else {
        // If not logged in, block the security screen too
        final isPublicRoute = state.matchedLocation == '/report-problem' || isLanguageRoute;
        if (!isAuthRoute && !isSplash && !isPublicRoute) {
          return '/auth/login';
        }
        // If on splash but initialization is complete, go to login
        if (isSplash) {
          return '/auth/login';
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (!authState.isInitialized) return '/splash';
          final user = authState.user;
          if (user == null) return '/auth/login';

          final languageState = ref.read(languageProvider);
          if (!languageState.hasSelectedLanguage) return '/language';

          final role = user.role;
          if (role == 'worker') return '/worker';
          if (role == 'recruiter') return '/recruiter';
          if (role == 'admin') return '/admin';
          return '/auth/login';
        },
      ),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/set-pin', builder: (_, __) => const SetPinScreen()),
      GoRoute(
        path: '/tour',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'worker';
          return AppTourScreen(role: role);
        },
      ),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/auth/verify-otp',
        builder: (context, state) =>
            VerifyOtpScreen(email: state.extra as String),
      ),
      GoRoute(
        path: '/auth/admin-verify-otp',
        builder: (context, state) =>
            AdminOtpScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/auth/admin-setup-phone',
        builder: (context, state) => const AdminPhoneSetupScreen(),
      ),
      GoRoute(path: '/auth/add-email', builder: (_, __) => const AddEmailScreen()),
      GoRoute(
          path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/kyc', builder: (_, __) => const KycUploadScreen()),
      // TODO: OTP verification route temporarily disabled
      // GoRoute(
      //     path: '/auth/otp',
      //     builder: (context, state) {
      //       final extra = state.extra as Map<String, dynamic>?;
      //       return OtpScreen(
      //         phoneNumber: extra?['phone'] ?? '',
      //         verificationId: extra?['verificationId'] ?? '',
      //         role: extra?['role'],
      //         name: extra?['name'],
      //       );
      //     }),
      // Email-based forgot password (replaces the old OTP flow)
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/auth/create-new-password',
          builder: (_, __) => const CreateNewPasswordScreen()),
      // Old OTP-based sub-routes removed

      // Worker routes
      GoRoute(
        path: '/worker',
        builder: (_, __) => const WorkerHomeScreen(),
        routes: [
          GoRoute(
              path: 'job/:id',
              builder: (context, state) =>
                  JobDetailScreen(jobId: state.pathParameters['id']!)),
          GoRoute(path: 'my-jobs', builder: (_, __) => const MyJobsScreen()),
          GoRoute(
              path: 'applications',
              builder: (_, __) => const WorkerApplicationsScreen()),
          GoRoute(
              path: 'notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
              path: 'profile', builder: (_, __) => const WorkerProfileScreen()),
          GoRoute(
              path: 'profile/edit',
              builder: (_, __) => const WorkerEditProfileScreen()),
          GoRoute(
              path: 'portfolio',
              builder: (_, __) => const PortfolioManagerScreen()),
          GoRoute(
              path: 'notification-settings',
              builder: (_, __) => const NotificationSettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/urgent-alert',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return UrgentAlertScreen(
            title: extra['title'] as String? ?? 'Urgent Alert',
            body: extra['body'] as String? ?? 'You have a new urgent job alert.',
            jobId: extra['jobId'] as String?,
          );
        },
      ),

      // Recruiter routes
      GoRoute(
        path: '/recruiter',
        builder: (_, __) => const RecruiterHomeScreen(),
        routes: [
          GoRoute(path: 'credits', builder: (_, __) => const CreditsScreen()),
          GoRoute(path: 'post-job', builder: (_, __) => const PostJobScreen()),
          GoRoute(
              path: 'edit-job',
              builder: (context, state) {
                final job = state.extra as JobModel?;
                return PostJobScreen(existingJob: job);
              }),
          GoRoute(
              path: 'applicants/:jobId',
              builder: (context, state) => ManageApplicantsScreen(
                  jobId: state.pathParameters['jobId']!)),
          GoRoute(
              path: 'worker-profile/:appId',
              builder: (context, state) => WorkerPublicProfileScreen(
                  applicationId: state.pathParameters['appId']!)),
          GoRoute(
              path: 'past-workers',
              builder: (_, __) => const PastWorkersScreen()),
          GoRoute(
              path: 'notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
              path: 'profile',
              builder: (_, __) => const RecruiterProfileScreen()),
          GoRoute(
              path: 'profile/edit',
              builder: (_, __) => const RecruiterEditProfileScreen()),
          GoRoute(
              path: 'onboarding',
              builder: (_, __) => const RecruiterOnboardingScreen()),
          GoRoute(
              path: 'verification-pending',
              builder: (_, __) => const VerificationPendingScreen()),
          GoRoute(
              path: 'suspended',
              builder: (context, state) {
                final reason = ref
                    .read(authProvider)
                    .user
                    ?.recruiterVerification?['suspendedReason'];
                return SuspendedScreen(reason: reason);
              }),
        ],
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminHomeScreen(),
        routes: [
          GoRoute(
              path: 'profile', builder: (_, __) => const AdminProfileScreen()),
          GoRoute(
              path: 'kyc-pending', builder: (_, __) => const AdminKycScreen()),
          GoRoute(
              path: 'withdrawals',
              builder: (_, __) => const WithdrawalManagementScreen()),
        ],
      ),

      GoRoute(path: '/referral', builder: (_, __) => const ReferralScreen()),

      // Shared routes
      GoRoute(
          path: '/public-profile/:id',
          builder: (context, state) =>
              PublicProfileScreen(userId: state.pathParameters['id']!)),
      GoRoute(
          path: '/search', builder: (_, __) => const SearchProfilesScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatListScreen()),
      GoRoute(
          path: '/chat/:jobId/:otherUserId',
          builder: (context, state) => ChatDetailScreen(
                jobId: state.pathParameters['jobId']!,
                otherUserId: state.pathParameters['otherUserId']!,
              )),
      GoRoute(
          path: '/chat/group/:jobId',
          builder: (context, state) => ChatDetailScreen(
                jobId: state.pathParameters['jobId']!,
                otherUserId: 'group',
                isGroup: true,
              )),

      // Driver routes
      GoRoute(
          path: '/driver/profile',
          builder: (_, __) => const DriverProfileScreen()),
      GoRoute(
          path: '/driver/kyc-status',
          builder: (_, __) => const DriverKycStatusScreen()),
      GoRoute(
          path: '/driver/find', builder: (_, __) => const FindDriversScreen()),
      GoRoute(
          path: '/driver/public/:driverId',
          builder: (context, state) => DriverPublicProfileScreen(
              driverId: state.pathParameters['driverId']!)),
      GoRoute(
          path: '/admin/driver-kyc',
          builder: (_, __) => const DriverKycQueueScreen()),
      GoRoute(
          path: '/disputes/raise/:jobId',
          builder: (context, state) =>
              RaiseDisputeScreen(jobId: state.pathParameters['jobId']!)),
      GoRoute(
          path: '/disputes/my', builder: (_, __) => const MyDisputesScreen()),
      GoRoute(
          path: '/worker/skill-badges',
          builder: (_, __) => const SkillBadgeScreen()),
      GoRoute(
          path: '/admin/skill-badges',
          builder: (_, __) => const AdminSkillBadgeScreen()),
      GoRoute(
          path: '/admin/disputes',
          builder: (_, __) => const DisputeManagementScreen()),
      GoRoute(
          path: '/admin/recruiters',
          builder: (_, __) => const RecruiterVerificationScreen()),
      GoRoute(
          path: '/admin/worker-kyc-detail',
          builder: (context, state) {
            final worker = state.extra as Map<String, dynamic>;
            return WorkerKYCDetailScreen(worker: worker);
          }),
      GoRoute(
          path: '/admin/recruiter-kyc-detail',
          builder: (context, state) {
            final recruiter = state.extra as Map<String, dynamic>;
            return RecruiterKYCDetailScreen(recruiter: recruiter);
          }),
      GoRoute(
          path: '/language',
          builder: (_, __) => const LanguageSelectionScreen()),
      GoRoute(
          path: '/change-password',
          builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(
          path: '/report-problem',
          builder: (_, __) => const ReportProblemScreen()),

    ],
  );
});

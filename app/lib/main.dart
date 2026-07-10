import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/router_service.dart';
import 'services/logger_service.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_colors.dart';
import 'utils/app_keys.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_lock_provider.dart';
import 'screens/auth/app_lock_screen.dart';
import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/widget_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/ai_assistant_overlay.dart';
import 'widgets/ai_assistant_handle.dart';

class AppInit {
  static late final Future<void> firebaseFuture;
  static late final Future<void> supabaseFuture;
}

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Start heavy initializations concurrently to minimize splash screen time
    final prefsFuture = SharedPreferences.getInstance();
    
    AppInit.firebaseFuture = Firebase.initializeApp().catchError((e) {
      debugPrint('Firebase init failed: $e');
    }).catchError((_) => null); // Return null instead of throwing further
    
    AppInit.supabaseFuture = Supabase.initialize(
      url: 'https://jqukexelzesxdjnocmzp.supabase.co',
      anonKey: 'sb_publishable_Z0anq6GyEQly13Eq_XJgwA_Zj-lUptO',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    ).catchError((_) => null); // Silently fail

    await Future.wait([
      EasyLocalization.ensureInitialized(),
      WidgetService.init(),
      prefsFuture,
    ]);

    // Load saved locale
    final prefs = await prefsFuture;
    // Read from the same key that locale_provider.dart writes to
    final langCode = prefs.getString('selected_language') ?? prefs.getString('app_language') ?? 'en';

    // Initialize notifications without blocking the UI thread
    unawaited(NotificationService.initialize());

    ErrorWidget.builder = (FlutterErrorDetails details) {
      LoggerService.e('Global UI Crash: ${details.exceptionAsString()}\\n${details.stack}');
      return Material(
        color: AppColors.bgLight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.textLight),
                const SizedBox(height: 16),
                const Text(
                  "Couldn't load this right now. Try again.",
                  style: TextStyle(color: AppColors.textMedium, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetyOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    // Force a rebuild / routing reset if possible
                    AppKeys.rootNavigatorKey.currentContext?.go('/');
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    };

    FlutterError.onError = (details) {
      LoggerService.e('FlutterError caught: ${details.exceptionAsString()}\\n${details.stack}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      LoggerService.e('PlatformDispatcher caught: $error\\n$stack');
      return true;
    };

    // Listen to deep links
    final appLinks = AppLinks();

    void handleDeepLink(Uri uri) async {
      final uriString = uri.toString();

      if (uriString.contains('reset-callback') || uriString.contains('type=')) {
        String? accessToken;
        String? refreshToken;

        if (uri.fragment.isNotEmpty) {
          final params = Uri.splitQueryString(uri.fragment);
          accessToken = params['access_token'];
          refreshToken = params['refresh_token'];
        }

        if (accessToken == null) {
          accessToken = uri.queryParameters['access_token'];
          refreshToken = uri.queryParameters['refresh_token'];
        }

        if (accessToken != null) {
          try {
            await AppInit.supabaseFuture; // Ensure Supabase is initialized before setSession
            if (refreshToken != null) {
              await Supabase.instance.client.auth.setSession(
                refreshToken,
                accessToken: accessToken,
              );
            } else {
              await Supabase.instance.client.auth.setSession(accessToken);
            }
          } catch (e) {
            debugPrint('Supabase setSession error on deep link: $e');
          }

          final isRecovery = uriString.contains('type=recovery') ||
              (uriString.contains('reset-callback') &&
                  !uriString.contains('type=magiclink') &&
                  !uriString.contains('type=signup'));

          void navigateWhenReady() {
            if (AppKeys.rootNavigatorKey.currentContext != null) {
              if (isRecovery) {
                AppKeys.rootNavigatorKey.currentContext
                    ?.go('/auth/create-new-password');
              } else {
                AppKeys.rootNavigatorKey.currentContext?.go('/');
              }
            } else {
              Future.delayed(
                  const Duration(milliseconds: 100), navigateWhenReady);
            }
          }

          navigateWhenReady();
        }
      }
    }

    appLinks.uriLinkStream.listen(handleDeepLink);
    appLinks.getInitialLink().then((uri) {
      if (uri != null) handleDeepLink(uri);
    });

    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
          Locale('pa'),
          Locale('bgc'),
          Locale('raj'),
          Locale('mr'),
          Locale('gu'),
          Locale('bn'),
          Locale('ta'),
          Locale('te'),
          Locale('kn'),
          Locale('ml'),
          Locale('or'),
        ],
        path: 'assets/languages',
        startLocale: Locale(langCode),
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
          ],
          child: const KaamkaazApp(),
        ),
      ),
    );
  }, (error, stack) {
    // Handle uncaught errors silently or log to a crashlytics service
  });
}

class KaamkaazApp extends ConsumerStatefulWidget {
  const KaamkaazApp({super.key});

  @override
  ConsumerState<KaamkaazApp> createState() => _KaamkaazAppState();
}

class _KaamkaazAppState extends ConsumerState<KaamkaazApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // Record when app went to background
        ref.read(appLockProvider.notifier).recordBackgrounded();
        break;

      case AppLifecycleState.resumed:
        // Check if the grace period has elapsed and lock if needed
        final isLoggedIn = ref.read(authProvider).user != null;
        if (isLoggedIn) {
          ref.read(appLockProvider.notifier).checkAndLockIfNeeded(isLoggedIn: isLoggedIn);
        }
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => ref.read(appLockProvider.notifier).recordActivity(),
      child: MaterialApp.router(
      title: 'Kaamkaaz',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      // EasyLocalization handles .tr() at its own level above MaterialApp,
      // so bgc/raj still load their own JSON translations correctly.
      // This mapping only affects Flutter built-in delegates (MaterialLocalizations,
      // date pickers etc.) which don't support custom locale codes bgc/raj.
      locale: (['bgc', 'raj'].contains(context.locale.languageCode))
          ? const Locale('hi')
          : context.locale,
      scaffoldMessengerKey: AppKeys.messengerKey,
      builder: (context, child) {
        ErrorWidget.builder = (details) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'We encountered an unexpected error. Please try restarting the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => router.go('/auth/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('goToLogin'.tr(),
                            style: const TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        };

        // Root-level app lock overlay
        return Consumer(
          builder: (context, ref, _) {
            final lockState = ref.watch(appLockProvider);
            final authState = ref.watch(authProvider);
            final isLoggedIn = authState.user != null;
            
            return Stack(
              clipBehavior: Clip.none,
              children: [
                child ?? const SizedBox.shrink(),
                // Show swipeable AI Assistant handle when logged in and not locked
                // Temporarily disabled as per request
                // if (!lockState.isLocked && isLoggedIn) 
                //   AIAssistantHandle(router: router),
                // Show lock screen on top of everything when locked AND user is logged in
                if (lockState.isLocked && isLoggedIn) const Positioned.fill(child: AppLockScreen()),
              ],
            );
          },
        );
      },
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/remember_me_service.dart';
import '../utils/api_config.dart';
import '../utils/app_keys.dart';
import '../services/notification_service.dart';
import '../services/pin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState(
      {this.user,
      this.isLoading = false,
      this.error,
      this.isInitialized = false});

  AuthState copyWith(
      {UserModel? user,
      bool? isLoading,
      String? error,
      bool? isInitialized,
      bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> init() async {
    try {
      // Listen to Supabase auth state changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        if (event == AuthChangeEvent.signedOut) {
          await ApiService.deleteToken();
          state = state.copyWith(clearUser: true);
          SocketService().disconnect();
        } else if (event == AuthChangeEvent.passwordRecovery) {
          // Reliable navigation triggered by Supabase SDK when it successfully processes the recovery link
          void navigateWhenReady() {
            if (AppKeys.rootNavigatorKey.currentContext != null) {
              AppKeys.rootNavigatorKey.currentContext?.go('/auth/create-new-password');
            } else {
              Future.delayed(const Duration(milliseconds: 100), navigateWhenReady);
            }
          }
          navigateWhenReady();
        }
      });

      final token = await ApiService.getToken();
      if (token != null) {
        final user = await AuthService.getMe();
        if (user != null) {
          state = state.copyWith(user: user, isInitialized: true);
          SocketService().connect(user.id);
          _setupPushNotifications();
        } else {
          await ApiService.deleteToken();
          state = state.copyWith(isInitialized: true);
        }
      } else {
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      // SILENT on startup: If it's a session issue during initialization, just clear token and don't set error
      if (e.toString().contains('401') ||
          e.toString().contains('error_') ||
          e.toString().contains('Session')) {
        await ApiService.deleteToken();
      }

      state = state.copyWith(isInitialized: true, error: null);
    }
  }

  Future<void> _setupPushNotifications() async {
    // Initialize FCM Push Notifications
    await NotificationService.setupFCM();
  }

  Future<void> updateFcmToken(String newToken) async {
    try {
      await ApiService.post(ApiConfig.updateFcmToken, {'fcmToken': newToken});
    } catch (e) {
      return;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
    required String aadhaarNumber,
    List<String>? skills,
    String? village,
    String? companyName,
    String? businessArea,
    String? workerType,
    String? referralCode,
    String language = 'hi',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        role: role,
        aadhaarNumber: aadhaarNumber,
        skills: skills,
        village: village,
        companyName: companyName,
        businessArea: businessArea,
        workerType: workerType,
        referralCode: referralCode,
        language: language,
      );
      if (result['success'] == true) {
        state = state.copyWith(user: result['user'], isLoading: false);
        SocketService().connect((result['user'] as UserModel).id);
        _setupPushNotifications();
      } else {
        state = state.copyWith(isLoading: false, error: result['message']);
      }
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  // identifier = phone number (10 digits) OR email address
  Future<Map<String, dynamic>> login(String identifier, String password,
      {bool rememberMe = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.login(identifier, password, rememberMe: rememberMe);
      if (result['success'] == true) {
        if (result['requireAdminOtp'] == true) {
          state = state.copyWith(isLoading: false);
          return result;
        }

        final user = result['user'] as UserModel;

        // Handle "Remember Me" storage using RememberMeService
        try {
          if (rememberMe) {
            await RememberMeService.saveCredentials(
              phoneOrEmail: identifier,
              password: password,
            );
          } else {
            await RememberMeService.clearCredentials();
          }
        } catch (e) {
          debugPrint('RememberMeService error in login: $e');
        }

        state = state.copyWith(user: user, isLoading: false);
        SocketService().connect(user.id);
        _setupPushNotifications();
        
        return result;
      } else {
        state = state.copyWith(isLoading: false, error: result['message']);
        return result;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.adminLogin(email, password);
      state = state.copyWith(isLoading: false, error: result['success'] == true ? null : result['message']);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> adminVerifyOtp(String idToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.adminVerifyOtp(idToken);
      if (result['success'] == true) {
        final user = result['user'] as UserModel;
        state = state.copyWith(user: user, isLoading: false);
        SocketService().connect(user.id);
        _setupPushNotifications();
      } else {
        state = state.copyWith(isLoading: false, error: result['message']);
      }
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> adminSetupPhone(String idToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.adminSetupPhone(idToken);
      if (result['success'] == true) {
        final user = result['user'] as UserModel;
        state = state.copyWith(user: user, isLoading: false);
        SocketService().connect(user.id);
        _setupPushNotifications();
      } else {
        state = state.copyWith(isLoading: false, error: result['message']);
      }
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> requestOTP(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.requestOTP(phone);
      state = state.copyWith(
          isLoading: false,
          error: result['success'] == true ? null : result['message']);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> verifyOTP(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.verifyOTP(phone, otp);
      if (result['success'] == true) {
        state = state.copyWith(user: result['user'], isLoading: false);
        SocketService().connect((result['user'] as UserModel).id);
        _setupPushNotifications();
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> verifyWithBackend(String idToken, String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.verifyWithSupabase(idToken, phone);
      if (result['success'] == true) {
        final user = result['user'] as UserModel;
        
        state = state.copyWith(user: user, isLoading: false);
        SocketService().connect(user.id);
        _setupPushNotifications();
      } else {
        state = state.copyWith(isLoading: false, error: result['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> syncSupabaseSession(Session session) async {
    // We send an empty string for phone if they logged in via email.
    // The backend uses the token to find the user.
    await verifyWithBackend(session.accessToken, session.user.email ?? '');
    if (state.error != null) {
      throw Exception(state.error);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.updateProfile(fields);
      if (result['success'] == true) {
        state = state.copyWith(user: result['user'], isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void updateUserLocal(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> refreshUser() async {
    final user = await AuthService.getMe();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    SocketService().disconnect();

    // Do NOT clear saved credentials on logout, so that "Remember Me" 
    // can pre-fill the fields next time the user arrives at the login screen.

    state = const AuthState(isInitialized: true);
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.post(ApiConfig.deleteAccount, {});
      if (res['success'] == true) {
        await logout();
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: res['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> updateKyc({
    required String aadhaarFront,
    required String aadhaarBack,
    required String livePhoto,
    String? licenceFront,
    String? licenceBack,
    String? aadhaarNumber,
    int? experienceYears,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.updateKyc(
        aadhaarFront: aadhaarFront,
        aadhaarBack: aadhaarBack,
        livePhoto: livePhoto,
        licenceFront: licenceFront,
        licenceBack: licenceBack,
        aadhaarNumber: aadhaarNumber,
        experienceYears: experienceYears,
      );

      if (result['success'] == true) {
        state =
            state.copyWith(user: result['user'] as UserModel, isLoading: false);
      } else {
        state = state.copyWith(error: result['message'], isLoading: false);
      }
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addPortfolioItem({
    required String description,
    String? mediaPath,
    required String mediaType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.addPortfolioItem(
        description: description,
        mediaPath: mediaPath,
        mediaType: mediaType,
      );

      if (result['success'] == true && state.user != null) {
        final updatedUser = UserModel(
          id: state.user!.id,
          name: state.user!.name,
          email: state.user!.email,
          phone: state.user!.phone,
          role: state.user!.role,
          skills: state.user!.skills,
          village: state.user!.village,
          companyName: state.user!.companyName,
          businessArea: state.user!.businessArea,
          language: state.user!.language,
          location: state.user!.location,
          profileImage: state.user!.profileImage,
          rating: state.user!.rating,
          completedJobsCount: state.user!.completedJobsCount,
          experienceDays: state.user!.experienceDays,
          experienceYears: state.user!.experienceYears,
          kycStatus: state.user!.kycStatus,
          kycNote: state.user!.kycNote,
          aadhaarNumber: state.user!.aadhaarNumber,
          aadhaarImage: state.user!.aadhaarImage,
          aadhaarBackImage: state.user!.aadhaarBackImage,
          livePhotoUrl: state.user!.livePhotoUrl,
          isPhoneVerified: state.user!.isPhoneVerified,
          isBlocked: state.user!.isBlocked,
          workerType: state.user!.workerType,
          verifiedSkills: state.user!.verifiedSkills,
          driverProfile: state.user!.driverProfile,
          recruiterVerification: state.user!.recruiterVerification,
          portfolio: result['portfolio'] as List<PortfolioItemModel>,
          createdAt: state.user!.createdAt,
        );
        state = state.copyWith(user: updatedUser, isLoading: false);
      } else {
        state = state.copyWith(error: result['message'], isLoading: false);
      }
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePortfolioItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await AuthService.deletePortfolioItem(itemId);

      if (result['success'] == true && state.user != null) {
        final updatedUser = UserModel(
          id: state.user!.id,
          name: state.user!.name,
          email: state.user!.email,
          phone: state.user!.phone,
          role: state.user!.role,
          skills: state.user!.skills,
          village: state.user!.village,
          companyName: state.user!.companyName,
          businessArea: state.user!.businessArea,
          language: state.user!.language,
          location: state.user!.location,
          profileImage: state.user!.profileImage,
          rating: state.user!.rating,
          completedJobsCount: state.user!.completedJobsCount,
          experienceDays: state.user!.experienceDays,
          experienceYears: state.user!.experienceYears,
          kycStatus: state.user!.kycStatus,
          kycNote: state.user!.kycNote,
          aadhaarNumber: state.user!.aadhaarNumber,
          aadhaarImage: state.user!.aadhaarImage,
          aadhaarBackImage: state.user!.aadhaarBackImage,
          livePhotoUrl: state.user!.livePhotoUrl,
          isPhoneVerified: state.user!.isPhoneVerified,
          isBlocked: state.user!.isBlocked,
          workerType: state.user!.workerType,
          verifiedSkills: state.user!.verifiedSkills,
          driverProfile: state.user!.driverProfile,
          recruiterVerification: state.user!.recruiterVerification,
          portfolio: result['portfolio'] as List<PortfolioItemModel>,
          createdAt: state.user!.createdAt,
        );
        state = state.copyWith(user: updatedUser, isLoading: false);
      } else {
        state = state.copyWith(error: result['message'], isLoading: false);
      }
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

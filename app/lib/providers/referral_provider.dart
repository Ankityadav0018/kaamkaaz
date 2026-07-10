import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import '../models/transaction_model.dart';
import '../models/referred_user_model.dart';
import '../services/socket_service.dart';

class ReferralState {
  final String? referralCode;
  final String? referralLink;
  final double walletBalance; // referral earnings balance (for withdrawal via UPI)
  final double referralEarnings;
  final int referralCount;
  final List<TransactionModel> transactions;
  final List<ReferredUserModel> referredUsers;
  final bool isLoading;
  final String? error;

  ReferralState({
    this.referralCode,
    this.referralLink,
    this.walletBalance = 0.0,
    this.referralEarnings = 0.0,
    this.referralCount = 0,
    this.transactions = const [],
    this.referredUsers = const [],
    this.isLoading = false,
    this.error,
  });

  ReferralState copyWith({
    String? referralCode,
    String? referralLink,
    double? walletBalance,
    double? referralEarnings,
    int? referralCount,
    List<TransactionModel>? transactions,
    List<ReferredUserModel>? referredUsers,
    bool? isLoading,
    String? error,
  }) {
    return ReferralState(
      referralCode: referralCode ?? this.referralCode,
      referralLink: referralLink ?? this.referralLink,
      walletBalance: walletBalance ?? this.walletBalance,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      referralCount: referralCount ?? this.referralCount,
      transactions: transactions ?? this.transactions,
      referredUsers: referredUsers ?? this.referredUsers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
class ReferralNotifier extends StateNotifier<ReferralState> {
  ReferralNotifier() : super(ReferralState()) {
    SocketService().socket?.on('referral_update', (_) {
      fetchMyCode();
      fetchReferralStats();
      fetchTransactions();
    });
  }

  Future<void> fetchMyCode() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get(ApiConfig.myReferral);
      if (res['success'] == true) {
        state = state.copyWith(
          referralCode: res['referralCode'],
          referralLink: res['referralLink'],
          // Backend returns 'referralBalance' (renamed from walletBalance)
          walletBalance: ((res['referralBalance'] ?? res['walletBalance']) as num?)?.toDouble() ?? 0.0,
          referralEarnings: (res['referralEarnings'] as num?)?.toDouble() ?? 0.0,
          referralCount: res['referralCount'] ?? 0,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: res['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchReferralStats() async {
    try {
      final res = await ApiService.get(ApiConfig.referralStats);
      if (res['success'] == true) {
        final List userList = res['referredUsers'] ?? [];
        state = state.copyWith(
          referredUsers:
              userList.map((e) => ReferredUserModel.fromJson(e)).toList(),
          referralCount: res['totalReferrals'] ?? state.referralCount,
          referralEarnings:
              (res['totalEarnings'] as num?)?.toDouble() ?? state.referralEarnings,
          // Backend returns 'referralBalance' (renamed from walletBalance)
          walletBalance:
              ((res['referralBalance'] ?? res['walletBalance']) as num?)?.toDouble() ?? state.walletBalance,
        );
      }
    } catch (e) {
      // Silently fail — stats are supplementary
    }
  }

  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get(ApiConfig.referralTransactions);
      if (res['success'] == true) {
        final List txList = res['transactions'] ?? [];
        state = state.copyWith(
          transactions:
              txList.map((e) => TransactionModel.fromJson(e)).toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: res['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> requestWithdrawal(double amount, String upiId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.post(ApiConfig.withdrawReferral, {
        'amount': amount,
        'upiId': upiId,
      });
      if (res['success'] == true) {
        await fetchMyCode();
        await fetchTransactions();
      } else {
        throw res['message'] ?? 'Withdrawal failed';
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final referralProvider =
    StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  return ReferralNotifier();
});

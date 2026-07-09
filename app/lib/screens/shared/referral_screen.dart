import 'package:intl/intl.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/referral_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/share_service.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(referralProvider.notifier).fetchMyCode();
      ref.read(referralProvider.notifier).fetchReferralStats();
      ref.read(referralProvider.notifier).fetchTransactions();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralProvider);
    final user = ref.watch(authProvider).user;
    final isRecruiter = user?.role == 'recruiter';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.referAndEarnTitle.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
      ),
      body: state.isLoading && state.referralCode == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(referralProvider.notifier).fetchMyCode();
                await ref.read(referralProvider.notifier).fetchReferralStats();
                await ref.read(referralProvider.notifier).fetchTransactions();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReferralCard(state),
                    if (!isRecruiter) ...[
                      const SizedBox(height: 20),
                      _buildWalletCard(state),
                      const SizedBox(height: 20),
                      _buildStatsRow(state),
                      const SizedBox(height: 20),
                      _buildHistoryTabs(state),
                    ] else ...[
                      const SizedBox(height: 20),
                      _buildRecruiterEarningsCard(state),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReferralCard(ReferralState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('inviteFriendsEarn'.tr(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('referralDescription'.tr(),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          // Referral Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(state.referralCode ?? '---',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  onPressed: () {
                    if (state.referralCode != null) {
                      Clipboard.setData(
                          ClipboardData(text: state.referralCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(LocaleKeys.referralCodeCopied.tr())),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Share Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (state.referralCode != null) {
                  final shareText =
                      'Kaamkaaz पर जुड़ो और काम पाओ! मेरा रेफरल कोड: ${state.referralCode}\n\nडाउनलोड करें: ${state.referralLink ?? 'https://kaamkaaz.app'}';
                  ShareService.shareReferralOnWhatsApp(shareText);
                }
              },
              icon: const Icon(Icons.share_rounded, size: 20),
              label: const Text('Share on WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(ReferralState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Referral Earnings',
                      style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('₹${state.walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary)),
                ],
              ),
              const Icon(Icons.savings_rounded,
                  size: 40, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar to ₹150
          if (state.walletBalance < 150) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (state.walletBalance / 150).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${(150 - state.walletBalance).toStringAsFixed(0)} more to unlock withdrawal',
              style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
          const Divider(height: 24),
          ElevatedButton(
            onPressed: state.walletBalance < 150
                ? null
                : () => _showWithdrawDialog(state),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(state.walletBalance < 150
                ? 'Min ₹150 needed to withdraw'
                : 'Withdraw via UPI'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ReferralState state) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.people_rounded,
            iconColor: AppColors.primary,
            value: '${state.referralCount}',
            label: 'Friends Referred',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.currency_rupee_rounded,
            iconColor: AppColors.success,
            value: '₹${state.referralEarnings.toStringAsFixed(0)}',
            label: 'Total Earned',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHistoryTabs(ReferralState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Referrals'),
              Tab(text: 'Transactions'),
            ],
          ),
          SizedBox(
            // Dynamic height based on content
            height: _calculateTabHeight(state),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReferredUsersList(state),
                _buildTransactionsList(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTabHeight(ReferralState state) {
    final referralItems = state.referredUsers.length;
    final txItems = state.transactions.length;
    final maxItems = referralItems > txItems ? referralItems : txItems;
    if (maxItems == 0) return 120;
    return (maxItems * 72.0 + 16).clamp(120.0, 500.0);
  }

  Widget _buildReferredUsersList(ReferralState state) {
    if (state.referredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 40, color: AppColors.textLight.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              const Text('No referrals yet. Share your code!',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: state.referredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final user = state.referredUsers[index];
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          title: Text(user.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(
              'Joined ${DateFormat('dd MMM yyyy').format(user.joinedDate.toLocal())}',
              style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: user.status == 'active'
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.textLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('+₹10',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: user.status == 'active'
                            ? AppColors.success
                            : AppColors.textLight)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList(ReferralState state) {
    if (state.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 40, color: AppColors.textLight.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(LocaleKeys.noTransactionsYet.tr(),
                  style:
                      const TextStyle(color: AppColors.textLight, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: state.transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final tx = state.transactions[index];
        final isCredit = tx.type != 'withdrawal';
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: isCredit
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.danger.withValues(alpha: 0.1),
            child: Icon(
                isCredit ? Icons.add_rounded : Icons.remove_rounded,
                color: isCredit ? AppColors.success : AppColors.danger,
                size: 20),
          ),
          title: Text(tx.description,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
              DateFormat('dd MMM yyyy, hh:mm a')
                  .format(tx.createdAt.toLocal()),
              style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  '${isCredit ? '+' : '-'}₹${tx.amount.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color:
                          isCredit ? AppColors.success : AppColors.danger)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(tx.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tx.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: _getStatusColor(tx.status))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecruiterEarningsCard(ReferralState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Earned',
                      style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('₹${state.referralEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary)),
                ],
              ),
              const Icon(Icons.stars_rounded,
                  size: 40, color: AppColors.primary),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Your referral earnings are automatically added to your Main Wallet!',
            style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(ReferralState state) {
    _amountController.text = state.walletBalance.toStringAsFixed(0);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(LocaleKeys.withdrawFundsTitle.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoiceTextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            VoiceTextField(
              controller: _upiController,
              decoration: InputDecoration(
                  labelText: 'UPI ID (e.g. user@okaxis)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancelBtn'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final amt = double.tryParse(_amountController.text) ?? 0;
              final upi = _upiController.text.trim();
              if (amt < 150) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                    content: Text(LocaleKeys.minWithdrawal.tr())));
                return;
              }
              if (upi.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(LocaleKeys.enterUpiId.tr())));
                return;
              }

              try {
                await ref
                    .read(referralProvider.notifier)
                    .requestWithdrawal(amt, upi);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                      content: Text(LocaleKeys.withdrawalSubmitted.tr()),
                      backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.danger));
                }
              }
            },
            child: Text(LocaleKeys.withdrawBtn.tr()),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
      case 'failed':
        return AppColors.danger;
      default:
        return AppColors.textLight;
    }
  }
}

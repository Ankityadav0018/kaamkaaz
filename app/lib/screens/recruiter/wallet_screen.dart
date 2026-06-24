import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:kaamkaaz/services/wallet_service.dart';
import 'package:kaamkaaz/utils/app_colors.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLoadingMore = false;
  List<dynamic> _transactions = [];
  late Razorpay _razorpay;
  int _balance = 0;
  int _currentPage = 1;
  int _totalPages = 1;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _fetchHistory(_currentPage + 1);
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _scrollController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final data = await WalletService.getWallet();
      if (mounted) {
        setState(() {
          _balance = (data['data']?['balance_paise'] as num?)?.toInt() ?? 0;
          _hasError = false;
        });
      }
      await _fetchHistory(1);
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchHistory(int page) async {
    if (page == 1) {
      setState(() => _transactions = []);
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final res = await WalletService.getTransactionHistory(page);
      if (res['success'] == true) {
        setState(() {
          _currentPage = res['page'];
          _totalPages = res['totalPages'];
          _transactions.addAll(res['data'] ?? []);
        });
      }
    } catch (e) {
      // Ignore pagination errors to keep UI intact
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _initiateTopup(int amountInRupees) async {
    HapticFeedback.mediumImpact();
    if (amountInRupees < 10 || amountInRupees > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LocaleKeys.invalidTopupAmount.tr()),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    try {
      final res = await WalletService.initiateTopup(amountInRupees * 100);
      var options = {
        'key': res['razorpay_key_id'],
        'amount': res['amount'],
        'name': 'KaamKaaz Wallet',
        'description': 'Premium Wallet Top-up',
        'order_id': res['order_id'],
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#1565C0'}
      };
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await WalletService.verifyTopup(
        response.orderId ?? '',
        response.paymentId ?? '',
        response.signature ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(LocaleKeys.topupSuccessUpdated.tr())),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(LocaleKeys.topupSuccessProcessing.tr())),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }

    if (mounted) {
      _fetchData();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text('${LocaleKeys.topupFailed.tr()} ${response.message}')),
        ],
      ),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    await _fetchData(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          LocaleKeys.myWallet.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_hasError) {
      return Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    size: 56, color: AppColors.danger),
              ),
              const SizedBox(height: 24),
              Text(
                LocaleKeys.failedToLoadWalletData.tr(),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(LocaleKeys.retryBtn.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              )
            ],
          ),
        ),
      );
    }

    return AnimatedOpacity(
      opacity: _isLoading ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 500),
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      _buildBalanceCard(),
                      const SizedBox(height: 32),
                      _buildTopupSection(),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            LocaleKeys.transactionHistory.tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.textDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (_transactions.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 64,
                            color: AppColors.textLight.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(LocaleKeys.noTransactionsYet.tr(),
                            style: const TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _transactions.length) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)),
                          );
                        }
                        return _buildTransactionItem(_transactions[index]);
                      },
                      childCount:
                          _transactions.length + (_isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

  Widget _buildBalanceCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Base Gradient
            Container(
              width: double.infinity,
              height: 200,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
            ),
            // Decorative Circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -20,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocaleKeys.availableBalance.tr().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: _balance / 100),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 8, right: 4),
                            child: Text(
                              '₹',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            value.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.shield_rounded,
                          color: Colors.greenAccent.shade400, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        LocaleKeys.secureWallet.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.addMoney.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _topupButton(100)),
            const SizedBox(width: 12),
            Expanded(child: _topupButton(500)),
            const SizedBox(width: 12),
            Expanded(child: _topupButton(1000)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              TextField(
                controller: _customAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBg,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded,
                      color: AppColors.textMedium, size: 20),
                  hintText: LocaleKeys.customAmountHint.tr(),
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final val = int.tryParse(_customAmountController.text);
                    if (val != null && val > 0) {
                      _initiateTopup(val);
                      _customAmountController.clear();
                      FocusScope.of(context).unfocus();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    LocaleKeys.addBtn.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topupButton(int amount) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _initiateTopup(amount),
        borderRadius: BorderRadius.circular(16),
        highlightColor: AppColors.primary.withValues(alpha: 0.1),
        splashColor: AppColors.primary.withValues(alpha: 0.2),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '+ ₹$amount',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final isCredit = tx['type'] == 'CREDIT';
    final isReferral = tx['source'] == 'REFERRAL_BONUS';
    final amount = (tx['amount_rupees'] as num?)?.toDouble() ?? 0.0;
    final balanceAfter =
        (tx['balance_after_rupees'] as num?)?.toDouble() ?? 0.0;
    final dateStr =
        tx['created_at']?.toString() ?? DateTime.now().toIso8601String();
    final date =
        DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now().toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCredit
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isReferral
                ? Icons.card_giftcard_rounded
                : (isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded),
            color: isCredit ? AppColors.success : AppColors.danger,
            size: 20,
          ),
        ),
        title: Text(
          tx['description'] ??
              (isCredit
                  ? LocaleKeys.walletTopup.tr()
                  : LocaleKeys.deduction.tr()),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(date),
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500),
          ),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'} ₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isCredit ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${LocaleKeys.bal.tr()} ₹${balanceAfter.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }
}

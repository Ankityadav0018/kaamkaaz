import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:kaamkaaz/services/credits_service.dart';
import 'package:kaamkaaz/utils/app_colors.dart';

// Credit pack model
class _CreditPack {
  final String id;
  final String name;
  final int priceRupees;
  final int credits;
  final String description;
  final IconData icon;
  final Color color;
  const _CreditPack({
    required this.id,
    required this.name,
    required this.priceRupees,
    required this.credits,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Hardcoded packs matching backend CREDIT_PACKS constants
const _packs = [
  _CreditPack(
    id: 'pack_starter_100',
    name: 'Starter Pack',
    priceRupees: 100,
    credits: 7,
    description: '7 job posting credits',
    icon: Icons.bolt_rounded,
    color: Color(0xFF64B5F6),
  ),
  _CreditPack(
    id: 'pack_standard_250',
    name: 'Standard Pack',
    priceRupees: 250,
    credits: 20,
    description: '20 job posting credits',
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFF7C3AED),
  ),
  _CreditPack(
    id: 'pack_pro_500',
    name: 'Pro Pack',
    priceRupees: 500,
    credits: 50,
    description: '50 job posting credits',
    icon: Icons.diamond_rounded,
    color: Color(0xFFF59E0B),
  ),
];

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLoadingMore = false;
  List<dynamic> _transactions = [];
  late Razorpay _razorpay;
  int _creditsBalance = 0;
  int _currentPage = 1;
  int _totalPages = 1;

  String? _pendingPackId;

  final ScrollController _scrollController = ScrollController();

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
      final data = await CreditsService.getCredits();
      if (mounted) {
        setState(() {
          _creditsBalance = (data['data']?['credits_balance'] as num?)?.toInt() ?? 0;
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
      final res = await CreditsService.getCreditHistory(page);
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

  Future<void> _initiatePurchase(_CreditPack pack) async {
    HapticFeedback.mediumImpact();
    try {
      final res = await CreditsService.initiatePurchase(pack.id);
      _pendingPackId = pack.id;
      var options = {
        'key': res['razorpay_key_id'],
        'amount': res['amount_paise'],
        'name': 'KaamKaaz Job Credits',
        'description': '${pack.credits} Job Posting Credits',
        'order_id': res['order_id'],
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#1565C0'}
      };
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await CreditsService.verifyPurchase(
        response.orderId ?? '',
        response.paymentId ?? '',
        response.signature ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Credits added to your account!')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Purchase successful! Credits updating...')),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }

    if (mounted) {
      _fetchData();
    }
    _pendingPackId = null;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _pendingPackId = null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text('Purchase failed: ${response.message}')),
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
        title: const Text(
          'My Credits',
          style: TextStyle(
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
                child: const Icon(Icons.credit_card_off_rounded,
                    size: 56, color: AppColors.danger),
              ),
              const SizedBox(height: 24),
              const Text(
                'Failed to load credits',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                    const SizedBox(height: 24),
                    _buildClosedLoopNotice(),
                    const SizedBox(height: 24),
                    _buildPacksSection(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Credit History',
                          style: TextStyle(
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
                      const Text('No transactions yet',
                          style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _transactions.length) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary)),
                        );
                      }
                      return _buildTransactionItem(_transactions[index]);
                    },
                    childCount: _transactions.length + (_isLoadingMore ? 1 : 0),
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
              height: 190,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
            ),
            // Decorative circles
            Positioned(
              top: -40, right: -40,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -60, left: -20,
              child: Container(
                width: 180, height: 180,
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
                      const Text(
                        'CREDITS AVAILABLE',
                        style: TextStyle(
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
                        child: const Icon(Icons.confirmation_number_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: _creditsBalance),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$value',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10, left: 8),
                            child: Text(
                              'credits',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lock_rounded,
                          color: Colors.greenAccent.shade400, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'Valid only for job posting on KaamKaaz',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
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

  Widget _buildClosedLoopNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Credits are non-refundable and can only be used for posting urgent jobs on KaamKaaz.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF15803D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buy Credits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose a credit pack to post urgent jobs',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 16),
        ..._packs.map((pack) => _buildPackCard(pack)),
      ],
    );
  }

  Widget _buildPackCard(_CreditPack pack) {
    final isStandard = pack.id == 'pack_standard_250';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _initiatePurchase(pack),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isStandard ? AppColors.primary : const Color(0xFFE2E8F0),
                width: isStandard ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isStandard ? 0.06 : 0.02),
                  blurRadius: isStandard ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: pack.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(pack.icon, color: pack.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pack.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (isStandard) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'POPULAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pack.credits} job posting credits',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${pack.priceRupees}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: pack.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${(pack.priceRupees / pack.credits).toStringAsFixed(1)}/credit',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
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
    final credits = (tx['credits'] as num?)?.toInt() ?? 0;
    final creditsAfter = (tx['credits_after'] as num?)?.toInt() ?? 0;
    final dateStr = tx['created_at']?.toString() ?? DateTime.now().toIso8601String();
    final date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now().toLocal();

    String sourceLabel;
    switch (tx['source']) {
      case 'CREDIT_PACK_PURCHASE':
        sourceLabel = 'Credit Pack Purchase';
        break;
      case 'JOB_POST_DEDUCTION':
        sourceLabel = 'Job Posting';
        break;
      case 'JOB_POST_REFUND':
        sourceLabel = 'Job Posting Refund';
        break;
      case 'REFERRAL_BONUS':
        sourceLabel = 'Referral Bonus';
        break;
      default:
        sourceLabel = isCredit ? 'Credits Added' : 'Credits Used';
    }

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
                    ? Icons.confirmation_number_rounded
                    : Icons.work_outline_rounded),
            color: isCredit ? AppColors.success : AppColors.danger,
            size: 20,
          ),
        ),
        title: Text(
          tx['description'] ?? sourceLabel,
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
              '${isCredit ? '+' : '-'}$credits credit${credits != 1 ? 's' : ''}',
              style: TextStyle(
                color: isCredit ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Balance: $creditsAfter',
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

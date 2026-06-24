import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import '../../utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class WithdrawalManagementScreen extends StatefulWidget {
  const WithdrawalManagementScreen({super.key});

  @override
  State<WithdrawalManagementScreen> createState() =>
      _WithdrawalManagementScreenState();
}

class _WithdrawalManagementScreenState extends State<WithdrawalManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pending = [];
  List<dynamic> _history = [];
  bool _isLoadingPending = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPending();
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPending() async {
    setState(() => _isLoadingPending = true);
    try {
      final res = await ApiService.get(ApiConfig.adminPendingWithdrawals);
      if (mounted) {
        setState(() {
          _pending = res['data'] ?? [];
          _isLoadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final res = await ApiService.get(ApiConfig.adminWithdrawalHistory);
      if (mounted) {
        setState(() {
          _history = res['data'] ?? [];
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _process(String id, String status, String note) async {
    try {
      final res = await ApiService.post(
          '${ApiConfig.adminProcessWithdrawal}/$id/process', {
        'status': status,
        'adminNote': note,
      });
      if (res['success'] == true) {
        _fetchPending();
        _fetchHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('processedSuccessfully'.tr())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('withdrawalRequests'.tr()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_isLoadingPending) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pending.isEmpty) {
      return Center(child: Text('noPendingWithdrawals'.tr()));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pending.length,
      itemBuilder: (context, index) {
        return _buildWithdrawalCard(_pending[index], isHistory: false);
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return Center(child: Text('noWithdrawalHistoryFound'.tr()));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return _buildWithdrawalCard(_history[index], isHistory: true);
      },
    );
  }

  Widget _buildWithdrawalCard(dynamic w, {required bool isHistory}) {
    final user = w['userId'] ?? {};
    final num currentWalletBalance = user['walletBalance'] ?? 0;
    final num requestedAmount = w['amount'] ?? 0;
    final num availableBalanceBefore = currentWalletBalance + requestedAmount;
    final String upiId = w['upiId'] ??
        w['description']?.toString().replaceAll('Withdrawal request to ', '') ??
        'N/A';
    final String status = w['status'] ?? 'unknown';

    Color statusColor = Colors.orange;
    String statusText = 'PENDING';
    if (status == 'completed') {
      statusColor = AppColors.success;
      statusText = 'COMPLETED';
    } else if (status == 'rejected' || status == 'failed') {
      statusColor = AppColors.danger;
      statusText = status.toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (user['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'User',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87),
                      ),
                      Text(
                        user['phone'] ?? 'N/A',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.8),
            Row(
              children: [
                if (!isHistory) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${availableBalanceBefore.toStringAsFixed(1)}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Withdraw Amount',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${requestedAmount.toStringAsFixed(1)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
                if (!isHistory) ...[
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remaining Balance',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${currentWalletBalance.toStringAsFixed(1)}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'UPI ID:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SelectableText(
                          upiId,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text(
                        'Requested: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(w['createdAt']).toLocal())}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (isHistory && w['updatedAt'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.update_rounded,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          'Processed: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(w['updatedAt']).toLocal())}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!isHistory) ...[
              const Divider(height: 24, thickness: 0.8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showProcessDialog(w['_id'], 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(
                            color: AppColors.danger, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text(
                        'Reject & Refund',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showProcessDialog(w['_id'], 'completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text(
                        'Approve Transfer',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showProcessDialog(String id, String status) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'completed'
            ? 'Approve Withdrawal'
            : 'Reject Withdrawal'),
        content: VoiceTextField(
          controller: noteController,
          decoration: const InputDecoration(
              labelText: 'Admin Note (Optional)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancelBtn'.tr())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _process(id, status, noteController.text);
            },
            child: Text('submitBtn'.tr()),
          ),
        ],
      ),
    );
  }
}

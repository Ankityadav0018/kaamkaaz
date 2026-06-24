import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class DisputeManagementScreen extends StatefulWidget {
  const DisputeManagementScreen({super.key});

  @override
  State<DisputeManagementScreen> createState() =>
      _DisputeManagementScreenState();
}

class _DisputeManagementScreenState extends State<DisputeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _stats = {
    'open': 0,
    'under_review': 0,
    'resolved': 0,
    'dismissed': 0
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    final res = await ApiService.get(ApiConfig.adminDisputeStats);
    if (mounted && res['success'] == true) {
      setState(() {
        _stats = Map<String, int>.from(res['data']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.raiseDispute.tr()),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: '${LocaleKeys.statusOpen.tr()} (${_stats['open']})'),
            Tab(
                text:
                    '${LocaleKeys.statusUnderReview.tr()} (${_stats['under_review']})'),
            Tab(
                text:
                    '${LocaleKeys.statusResolved.tr()} (${_stats['resolved']})'),
            Tab(
                text:
                    '${LocaleKeys.statusDismissed.tr()} (${_stats['dismissed']})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DisputeListView(status: 'open', onAction: _fetchStats),
          DisputeListView(status: 'under_review', onAction: _fetchStats),
          DisputeListView(status: 'resolved', onAction: _fetchStats),
          DisputeListView(status: 'dismissed', onAction: _fetchStats),
        ],
      ),
    );
  }
}

class DisputeListView extends StatefulWidget {
  final String status;
  final VoidCallback onAction;
  const DisputeListView(
      {super.key, required this.status, required this.onAction});

  @override
  State<DisputeListView> createState() => _DisputeListViewState();
}

class _DisputeListViewState extends State<DisputeListView> {
  List<dynamic> _disputes = [];
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _fetchDisputes();
  }

  Future<void> _fetchDisputes() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(
          '${ApiConfig.adminDisputes}?status=${widget.status}');
      if (mounted) {
        setState(() {
          _disputes = res['data'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String disputeId, String newStatus) async {
    final TextEditingController noteController = TextEditingController();

    if (newStatus == 'resolved' || newStatus == 'dismissed') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(newStatus == 'resolved'
              ? LocaleKeys.resolve.tr()
              : LocaleKeys.dismiss.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LocaleKeys.adminNoteRequired.tr()),
              const SizedBox(height: 15),
              VoiceTextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: LocaleKeys.adminNote.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(LocaleKeys.cancel.tr())),
            ElevatedButton(
              onPressed: () {
                if (noteController.text.length >= 10) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(LocaleKeys.confirm.tr()),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _processing = true);
    try {
      final res =
          await ApiService.patch('${ApiConfig.adminDisputes}/$disputeId', {
        'status': newStatus,
        'adminNote': noteController.text.isNotEmpty
            ? noteController.text
            : 'Processing dispute',
      });

      if (res['success'] == true && mounted) {
        _fetchDisputes();
        widget.onAction();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _buildDisputeDetailRow(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMedium)),
              const SizedBox(height: 4),
              Text(content,
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_disputes.isEmpty)
          Center(
            child: Text(LocaleKeys.noDisputes.tr(),
                style: const TextStyle(color: AppColors.textLight)),
          )
        else
          RefreshIndicator(
            onRefresh: _fetchDisputes,
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _disputes.length,
              itemBuilder: (context, index) {
                final dispute = _disputes[index];
                final raiser = dispute['raisedBy'] ?? {};
                final against = dispute['againstUserId'] ?? {};
                final job = dispute['jobId'] ?? {};
                final date = DateTime.parse(dispute['createdAt']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: widget.status == 'resolved' ? AppColors.success.withValues(alpha: 0.1) : (widget.status == 'open' ? AppColors.danger.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1)),
                      child: Icon(Icons.gavel_rounded, color: widget.status == 'resolved' ? AppColors.success : (widget.status == 'open' ? AppColors.danger : AppColors.warning), size: 20),
                    ),
                    title: Text(
                      (dispute['category'] as String?)?.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ') ?? 'Dispute',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal())} • ${widget.status.toUpperCase().replaceAll('_', ' ')}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDisputeDetailRow(Icons.work_rounded, 'Job Details', 
                              'Title: ${job['title'] ?? 'N/A'}\n'
                              'Category: ${job['category'] ?? 'N/A'}\n'
                              'Wage: ₹${job['wage'] ?? 'N/A'} / ${job['wageType'] ?? 'N/A'}'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDisputeDetailRow(Icons.person_rounded, 'From (Raiser)', 
                                    'Name: ${raiser['name'] ?? 'N/A'}\n'
                                    'Role: ${(raiser['role'] ?? 'Unknown').toUpperCase()}\n'
                                    'Phone: ${raiser['phone'] ?? 'N/A'}'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildDisputeDetailRow(Icons.person_outline_rounded, 'Against', 
                                    'Name: ${against['name'] ?? 'N/A'}\n'
                                    'Role: ${(against['role'] ?? 'Unknown').toUpperCase()}\n'
                                    'Phone: ${against['phone'] ?? 'N/A'}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDisputeDetailRow(Icons.info_outline_rounded, 'Dispute Description', 
                              '${dispute['description'] ?? 'No description'}'),
                              
                            if (dispute['adminNote'] != null) ...[
                              const SizedBox(height: 12),
                              _buildDisputeDetailRow(Icons.admin_panel_settings_rounded, 'Admin Note', 
                                '${dispute['adminNote']}'),
                            ],

                            if (widget.status == 'open' ||
                                widget.status == 'under_review') ...[
                              const Divider(height: 32),
                              Text('updateStatusLabel2'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (widget.status == 'open')
                                    ActionChip(
                                      label: Text('underReviewLabel'.tr(), style: const TextStyle(fontSize: 12)),
                                      onPressed: () => _updateStatus(dispute['_id'], 'under_review'),
                                    ),
                                  ActionChip(
                                    label: const Text('RESOLVE', style: TextStyle(fontSize: 12, color: Colors.white)),
                                    onPressed: () => _updateStatus(dispute['_id'], 'resolved'),
                                    backgroundColor: AppColors.success,
                                  ),
                                  ActionChip(
                                    label: const Text('DISMISS', style: TextStyle(fontSize: 12, color: Colors.white)),
                                    onPressed: () => _updateStatus(dispute['_id'], 'dismissed'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_processing)
          Container(
            color: Colors.black26,
            child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
      ],
    );
  }
}


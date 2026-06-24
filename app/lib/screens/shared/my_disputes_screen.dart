import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import '../../widgets/brand_logo.dart';

class MyDisputesScreen extends StatefulWidget {
  const MyDisputesScreen({super.key});

  @override
  State<MyDisputesScreen> createState() => _MyDisputesScreenState();
}

class _MyDisputesScreenState extends State<MyDisputesScreen> {
  List<dynamic> _disputes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDisputes();
  }

  Future<void> _fetchDisputes() async {
    setState(() => _loading = true);
    final res = await ApiService.get(ApiConfig.myDisputes);
    if (mounted) {
      setState(() {
        _disputes = res['data'] ?? [];
        _loading = false;
      });
    }
  }

  String _getCategoryLabel(String id) {
    switch (id) {
      case 'payment_not_received':
        return LocaleKeys.paymentNotReceived.tr();
      case 'worker_no_show':
        return LocaleKeys.workerNoShow.tr();
      case 'wrong_job_description':
        return LocaleKeys.wrongJobDesc.tr();
      case 'work_quality_issue':
        return LocaleKeys.workQualityIssue.tr();
      case 'unsafe_conditions':
        return LocaleKeys.unsafeConditions.tr();
      case 'unprofessional_behavior':
        return 'Unprofessional Behavior';
      case 'property_damage':
        return 'Property Damage';
      default:
        return LocaleKeys.otherText.tr();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open':
        return LocaleKeys.statusOpen.tr();
      case 'under_review':
        return LocaleKeys.statusUnderReview.tr();
      case 'resolved':
        return LocaleKeys.statusResolved.tr();
      case 'dismissed':
        return LocaleKeys.statusDismissed.tr();
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: Text(LocaleKeys.myDisputes.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _disputes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🤝', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 15),
                      Text(LocaleKeys.noDisputes.tr(),
                          style: const TextStyle(
                              fontSize: 18, color: AppColors.textMedium)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDisputes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _disputes.length,
                    itemBuilder: (context, index) {
                      final dispute = _disputes[index];
                      final job = dispute['jobId'] ?? {};
                      final against = dispute['againstUserId'] ?? {};
                      final status = dispute['status'];
                      final date = DateTime.parse(dispute['createdAt']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        AppColors.getCategoryEmoji(
                                                    job['category'] ?? '') ==
                                                'logo'
                                            ? const BrandLogo(
                                                size: 18, borderRadius: 4)
                                            : Text(
                                                AppColors.getCategoryEmoji(
                                                    job['category'] ?? ''),
                                                style: const TextStyle(
                                                    fontSize: 18)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            job['title'] ?? 'Job',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _getStatusColor(status)),
                                    ),
                                    child: Text(
                                      _getStatusLabel(status),
                                      style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                  '${LocaleKeys.raiseDispute.tr()}: ${_getCategoryLabel(dispute['category'])}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                  LocaleKeys.against
                                      .tr(args: [against['name'] ?? 'Unknown']),
                                  style: const TextStyle(
                                      color: AppColors.textMedium)),
                              const SizedBox(height: 4),
                              Text(
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(date.toLocal()),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight)),
                              const Divider(height: 24),
                              Text(dispute['description'],
                                  style: const TextStyle(fontSize: 14)),
                              if (dispute['adminNote'] != null) ...[
                                const SizedBox(height: 15),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                    border: const Border(
                                        left: BorderSide(
                                            color: AppColors.primary,
                                            width: 4)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(LocaleKeys.adminNote.tr(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: AppColors.primary)),
                                      const SizedBox(height: 4),
                                      Text(dispute['adminNote'],
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

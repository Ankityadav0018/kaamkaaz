import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/applicant_card_widget.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../providers/application_provider.dart';

class RecruiterApplicationsScreen extends ConsumerStatefulWidget {
  const RecruiterApplicationsScreen({super.key});

  @override
  ConsumerState<RecruiterApplicationsScreen> createState() => _RecruiterApplicationsScreenState();
}

class _RecruiterApplicationsScreenState extends ConsumerState<RecruiterApplicationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() => _fetchApps());
  }

  void _fetchApps() {
    ref.read(applicationProvider.notifier).fetchRecruiterApplications();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(applicationProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.applicants.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: LocaleKeys.pending.tr()),
            Tab(text: LocaleKeys.accepted.tr()),
            Tab(text: LocaleKeys.completed.tr()),
            Tab(text: LocaleKeys.rejected.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppList(appState.recruiterApplications, appState.isLoading, 'applied'),
          _buildAppList(appState.recruiterApplications, appState.isLoading, 'accepted'),
          _buildAppList(appState.recruiterApplications, appState.isLoading, 'completed'),
          _buildAppList(appState.recruiterApplications, appState.isLoading, 'rejected'),
        ],
      ),
    );
  }

  Widget _buildAppList(List<dynamic> apps, bool isLoading, String expectedStatus) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = apps.where((a) {
      String effectiveStatus = a.status;
      if (a.job?.status == 'completed') {
        effectiveStatus = 'completed';
      }
      return effectiveStatus == expectedStatus;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded, size: 60, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(LocaleKeys.noApplicationsFound.tr(), style: const TextStyle(color: AppColors.textMedium)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchApps(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final app = filtered[index];
          return ApplicantCardWidget(
            application: app,
            onAccept: expectedStatus == 'applied'
                ? () => ref.read(applicationProvider.notifier).accept(app.id)
                : null,
            onReject: expectedStatus == 'applied'
                ? () => ref.read(applicationProvider.notifier).reject(app.id)
                : null,
          );
        },
      ),
    );
  }
}

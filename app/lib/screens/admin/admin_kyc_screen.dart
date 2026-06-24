import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/worker_model.dart';
import '../../providers/admin_kyc_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminKycScreen extends ConsumerStatefulWidget {
  const AdminKycScreen({super.key});

  @override
  ConsumerState<AdminKycScreen> createState() => _AdminKycScreenState();
}

class _AdminKycScreenState extends ConsumerState<AdminKycScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });

    // Initialize all three on screen load - STEP 7
    _loadDrivers();
    _loadRecruiters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == 0) ref.read(adminKycProvider.notifier).fetchKycQueue();
    if (index == 1) _loadDrivers();
    if (index == 2) _loadRecruiters();
  }

  Future<void> _loadDrivers() async {
    // Implementation for drivers
  }

  Future<void> _loadRecruiters() async {
    // Implementation for recruiters
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('kycManagement'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Workers'),
            Tab(text: 'Drivers'),
            Tab(text: 'Recruiters'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkersTab(),
          Center(child: Text('driversList'.tr())),
          Center(child: Text('recruitersList'.tr())),
        ],
      ),
    );
  }

  // STEP 2 — Fix the Workers list UI
  Widget _buildWorkersTab() {
    final kycState = ref.watch(adminKycProvider);

    if (kycState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kycState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('errorPrefix'.tr(args: [kycState.error.toString()]), 
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(adminKycProvider.notifier).fetchKycQueue(),
              child: Text('retryBtn'.tr()),
            ),
          ],
        ),
      );
    }

    if (kycState.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('noPendingKycReq'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminKycProvider.notifier).fetchKycQueue(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kycState.users.length,
        itemBuilder: (context, index) {
          final user = kycState.users[index];
          return _buildWorkerCard(user);
        },
      ),
    );
  }

  // STEP 3 — Fix the Worker Card widget
  Widget _buildWorkerCard(WorkerModel worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to detail screen
          context.push(
            '/admin/worker-kyc-detail',
            extra: worker.toJson(), // Convert to map if needed by detail screen
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selfie/Profile photo
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    (worker.selfieUrl != null && worker.selfieUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(worker.selfieUrl!)
                        : null,
                child: (worker.selfieUrl == null || worker.selfieUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 30, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),

              // Worker info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name ?? 'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker.phone ?? '',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Submitted: ${_formatDate(worker.kycSubmittedAt)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ]),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/api_config.dart';
import '../../widgets/brand_logo.dart';
import 'analytics_screen.dart';
import '../../providers/notification_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _currentIndex = 1; // Start on Dashboard
  Map<String, dynamic> _stats = {};
  List<dynamic> _pendingKyc = [];
  List<dynamic> _pendingRecruiters = [];
  List<dynamic> _driverKyc = [];
  List<dynamic> _allUsers = [];
  List<dynamic> _allJobs = [];
  List<dynamic> _allReports = [];
  List<dynamic> _sosAlerts = [];
  bool _loading = true;
  bool _processing = false;
  String _userFilter = 'all';
  String _searchQuery = '';
  String _kycFilter = 'worker';
  String _reportStatusFilter = 'all';
  String _reportCategoryFilter = 'all';

  void setProcessing(bool val) {
    if (mounted) setState(() => _processing = val);
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
    Future.microtask(
        () => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        ApiService.get(ApiConfig.adminStats),
        ApiService.get(ApiConfig.adminKycPending),
        ApiService.get(ApiConfig.adminUsers),
        ApiService.get(ApiConfig.adminJobs),
        ApiService.get(ApiConfig.driverKycPending),
        ApiService.get(ApiConfig.adminPendingRecruiters),
        ApiService.get(ApiConfig.reports),
        ApiService.get(ApiConfig.adminSosAlerts),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0]['data'] ?? {};
          _pendingKyc = results[1]['data'] ?? [];
          _allUsers = results[2]['data'] ?? [];
          _allJobs = results[3]['data'] ?? [];
          _driverKyc = results[4]['data'] ?? [];
          _pendingRecruiters = results[5]['data'] ?? [];
          _allReports = results[6]['data'] ?? [];
          _sosAlerts = results[7]['data'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        LoggerService.e('Admin Dashboard Load Error: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('errorLoadingData'.tr()),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _review(BuildContext context, String userId, String status,
      {String? note}) async {
    setState(() => _processing = true);
    try {
      final res = await ApiService.put('${ApiConfig.adminKycReview}/$userId',
          {'status': status, if (note != null) 'note': note});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Success'),
          backgroundColor:
              status == 'approved' ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
        _loadAll();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showRejectDialog(BuildContext context, dynamic user) async {
    final ctrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('rejectReason'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: VoiceTextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: LocaleKeys.enterRejectionReason2.tr(),
            filled: true,
            fillColor: AppColors.inputBg,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancelBtn'.tr())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _review(context, user['_id'], 'rejected', note: ctrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('rejectBtn'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJob(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('deleteJobQ'.tr()),
        content: const Text(
            'This action cannot be undone. All applications for this job will also be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancelBtn'.tr())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('deleteBtn'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      final res = await ApiService.delete('${ApiConfig.jobDetail}/$jobId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Job deleted'),
          backgroundColor: AppColors.success,
        ));
        _loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showImagePreview(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) =>
                        Center(child: Text('failedLoadImage'.tr())),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 1) {
          setState(() => _currentIndex = 1);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.bgLight,
            body: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : IndexedStack(
                    index: _currentIndex,
                    children: [
                      RefreshIndicator(
                          onRefresh: _loadAll, child: const AnalyticsScreen()),
                      RefreshIndicator(
                          onRefresh: _loadAll, child: _buildDashboard()),
                      _buildKYCPage(),
                      _buildUsersPage(),
                      _buildJobsPage(),
                      _buildReportsPage(),
                      _buildSosPage(),
                    ],
                  ),
            bottomNavigationBar: Container(
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) {
                    setState(() => _currentIndex = i);
                  },
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textLight,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(_currentIndex == 0
                          ? Icons.analytics_rounded
                          : Icons.analytics_outlined),
                      label: 'Analytics',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(_currentIndex == 1
                          ? Icons.dashboard_rounded
                          : Icons.dashboard_outlined),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        isLabelVisible: (_pendingKyc.length +
                                _driverKyc.length +
                                _pendingRecruiters.length) >
                            0,
                        label: Text(
                            '${_pendingKyc.length + _driverKyc.length + _pendingRecruiters.length}'),
                        child: Icon(_currentIndex == 2
                            ? Icons.verified_user_rounded
                            : Icons.verified_user_outlined),
                      ),
                      label: 'KYC',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(_currentIndex == 3
                          ? Icons.people_rounded
                          : Icons.people_outlined),
                      label: 'Users',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(_currentIndex == 4
                          ? Icons.work_rounded
                          : Icons.work_outlined),
                      label: 'Jobs',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(_currentIndex == 5
                          ? Icons.bug_report_rounded
                          : Icons.bug_report_outlined),
                      label: 'Reports',
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        isLabelVisible: _sosAlerts.where((a) => a['status'] == 'pending').isNotEmpty,
                        label: Text('${_sosAlerts.where((a) => a['status'] == 'pending').length}'),
                        backgroundColor: AppColors.danger,
                        child: Icon(_currentIndex == 6
                            ? Icons.sos_rounded
                            : Icons.sos_outlined,
                            color: _currentIndex == 6 ? AppColors.danger : null),
                      ),
                      label: 'SOS',
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_processing)
            Container(
              color: Colors.black26,
              child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final user = ref.watch(authProvider).user;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.95), AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (user?.name ?? 'Admin').split(' ')[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Admin Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'System Administrator',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.language_rounded, color: Colors.white, size: 24),
                      onPressed: () => context.push('/language'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                      onPressed: () => context.push('/admin/profile'),
                    ),
                    const SizedBox(width: 4),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        if (ref.watch(notificationProvider).unreadCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('platformStatus'.tr(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard('👷', '${_stats['workers'] ?? 0}', 'Workers',
                              const Color(0xFFE65100).withValues(alpha: 0.08)),
                          const SizedBox(width: 12),
                          _statCard(
                              'logo',
                              '${_stats['recruiters'] ?? 0}',
                              'Recruiters',
                              AppColors.primary.withValues(alpha: 0.08)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard('📝', '${_stats['jobs'] ?? 0}', 'Active Jobs',
                              const Color(0xFF2E7D32).withValues(alpha: 0.08)),
                          const SizedBox(width: 12),
                          _statCard(
                              '📋',
                              '${_stats['applications'] ?? 0}',
                              'Apps',
                              const Color(0xFF1565C0).withValues(alpha: 0.08)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard('🚗', '${_driverKyc.length}', 'Driver KYC',
                              const Color(0xFF00ACC1).withValues(alpha: 0.08)),
                          const SizedBox(width: 10),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('quickActions'.tr(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _actionCard('📋', 'Review KYC',
                                '${_stats['totalPendingKyc'] ?? _stats['pendingKyc'] ?? 0} pending',
                                () {
                          context.push('/admin/kyc-pending');
                        })),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _actionCard('👥', 'Manage Users',
                                '${(_stats['workers'] ?? 0) + (_stats['recruiters'] ?? 0)} total',
                                () {
                          setState(() => _currentIndex = 3);
                        })),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _actionCard(
                        '🚗',
                        'Driver KYC Queue',
                        '${_driverKyc.length} pending docs',
                        () => context.push('/admin/driver-kyc')),
                    const SizedBox(height: 12),
                    _actionCard(
                        '🏗️',
                        'Recruiter KYC',
                        '${_pendingRecruiters.length} pending',
                        () => context.push('/admin/recruiters')),
                    const SizedBox(height: 12),
                    _actionCard(
                        '🏅',
                        'Skill Badge Requests',
                        'Verify worker skills',
                        () => context.push('/admin/skill-badges')),
                    const SizedBox(height: 12),
                    _actionCard(
                        '⚖️',
                        'Dispute Management',
                        'Resolve job conflicts',
                        () => context.push('/admin/disputes')),
                    const SizedBox(height: 12),
                    _actionCard(
                        '💳',
                        'Withdrawal Queue',
                        'Process user transactions',
                        () => context.push('/admin/withdrawals')),
                    const SizedBox(height: 12),
                    _actionCard('🪲', 'Report Problem', 'Report app glitch/bug',
                        () => context.push('/report-problem')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKYCPage() {
    final filteredKyc =
        _pendingKyc.where((u) => u['role'] == 'worker').toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('kycAndVerification'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _loadAll)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  _kycFilterChip('Workers', 'worker', filteredKyc.length),
                  const SizedBox(width: 8),
                  _kycFilterChip('Drivers', 'driver', _driverKyc.length),
                  const SizedBox(width: 8),
                  _kycFilterChip(
                      'Recruiters', 'recruiter', _pendingRecruiters.length),
                ],
              ),
            ),
            Expanded(
              child: _kycFilter == 'driver'
                  ? ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _driverKyc.length,
                      itemBuilder: (_, i) => _KycMiniCard(
                        user: _driverKyc[i],
                        onAction: _loadAll,
                        onApprove: (id) => _review(context, id, 'approved'),
                        onReject: (id) =>
                            _showRejectDialog(context, _driverKyc[i]),
                        onPreview: (url, title) =>
                            _showImagePreview(context, url, title),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredKyc.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () async {
                          final result = await context.push(
                              '/admin/worker-kyc-detail',
                              extra: filteredKyc[i]);
                          if (result == true) _loadAll();
                        },
                        child: _KycCard(
                          user: filteredKyc[i],
                          onAction: _loadAll,
                          onApprove: (id) => _review(context, id, 'approved'),
                          onReject: (id) =>
                              _showRejectDialog(context, filteredKyc[i]),
                          onPreview: (url, title) =>
                              _showImagePreview(context, url, title),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kycFilterChip(String label, String value, int count) {
    final active = _kycFilter == value;
    final color = value == 'driver'
        ? AppColors.driving
        : (value == 'worker' ? AppColors.warning : AppColors.primary);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (value == 'recruiter') {
            context.push('/admin/recruiters');
          } else {
            setState(() => _kycFilter = value);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? color : AppColors.inputBg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: Text(label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textMedium,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersPage() {
    final currentUser = ref.watch(authProvider).user;
    final filtered = _allUsers.where((u) {
      // 1. Do not show current admin
      if (u['_id'] == currentUser?.id) return false;
      // 2. Role filter
      if (_userFilter != 'all' && u['role'] != _userFilter) return false;
      // 3. Search query
      if (_searchQuery.isNotEmpty &&
          !(u['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('userManagement'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _loadAll)
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: VoiceTextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'searchByNameDots'.tr(),
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.inputBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _userFilter,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('allFilter'.tr())),
                    DropdownMenuItem(value: 'worker', child: Text('workersFilter'.tr())),
                    DropdownMenuItem(
                        value: 'recruiter', child: Text('recruitersFilter'.tr())),
                  ],
                  onChanged: (v) => setState(() => _userFilter = v!),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (_, i) =>
                    _UserCard(user: filtered[i], onAction: _loadAll),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsPage() {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('jobAudits'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _loadAll)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: _allJobs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 64, borderRadius: 16),
                    const SizedBox(height: 16),
                    Text('noJobsAudit'.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('refreshAudit'.tr(),
                        style: const TextStyle(color: AppColors.textLight)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: _loadAll, child: Text('refreshBtn'.tr())),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _allJobs.length,
                itemBuilder: (_, i) {
                  final job = _allJobs[i];
                  final recruiter = job['recruiterId'] ?? {};

                  Color statusColor;
                  switch (job['status']) {
                    case 'open':
                      statusColor = AppColors.success;
                      break;
                    case 'assigned':
                      statusColor = AppColors.info;
                      break;
                    case 'completed':
                      statusColor = AppColors.accent;
                      break;
                    case 'cancelled':
                      statusColor = AppColors.danger;
                      break;
                    default:
                      statusColor = AppColors.textLight;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.1),
                        child: Text(job['category']?[0]?.toUpperCase() ?? 'J',
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(job['title'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'By ${recruiter['name'] ?? 'Unknown Recruiter'} • ${job['category']}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(job['status']?.toUpperCase() ?? 'OPEN',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusColor)),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Description: ${job['description'] ?? 'No description'}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMedium)),
                              const SizedBox(height: 8),
                              Text(LocaleKeys.wageDisplay.tr(namedArgs: {'wage': job['wage'].toString(), 'type': job['wageType'].toString()}),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                  'Location: ${job['location']?['address'] ?? 'N/A'}',
                                  softWrap: true,
                                  style: const TextStyle(fontSize: 13)),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _deleteJob(job['_id']),
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18),
                                    label: Text('deleteJobBtn'.tr()),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.danger),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _statCard(String emoji, String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            emoji == 'logo'
                ? const BrandLogo(size: 24, borderRadius: 6)
                : Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text(count,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
      String emoji, String title, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0DA), width: 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.3)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textLight)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsPage() {
    final filteredReports = _allReports.where((r) {
      // Status filter
      if (_reportStatusFilter != 'all' && r['status'] != _reportStatusFilter) return false;
      
      // Category filter (if job populated)
      if (_reportCategoryFilter != 'all') {
        final job = r['jobId'];
        if (job == null || (job is Map && job['category'] != _reportCategoryFilter)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('bugReportsTitle'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _loadAll)
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _reportStatusFilter,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      labelText: 'Status',
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(LocaleKeys.allStatus.tr())),
                      const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      const DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    ],
                    onChanged: (v) => setState(() => _reportStatusFilter = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _reportCategoryFilter,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      labelText: 'Category',
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(LocaleKeys.allCategories.tr())),
                      const DropdownMenuItem(value: 'construction', child: Text('Construction')),
                      const DropdownMenuItem(value: 'plumbing', child: Text('Plumbing')),
                      const DropdownMenuItem(value: 'electrical', child: Text('Electrical')),
                      const DropdownMenuItem(value: 'farming', child: Text('Farming')),
                      const DropdownMenuItem(value: 'driver', child: Text('Driver')),
                    ],
                    onChanged: (v) => setState(() => _reportCategoryFilter = v!),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              child: filteredReports.isEmpty
                  ? Center(child: Text('noReportsYet'.tr()))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredReports.length,
                      itemBuilder: (_, i) {
                        final report = filteredReports[i];
                        final user = report['userId'] ?? {};
                        final recruiter = report['reportedUserId'] ?? {};
                        final job = report['jobId'] ?? {};
                        
                        // Parse timestamp
                        final createdAt = report['createdAt'] != null
                            ? DateTime.tryParse(report['createdAt'])?.toLocal()
                            : null;
                        final dateStr = createdAt != null 
                            ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}' 
                            : 'Unknown Date';

                        Color statusColor;
                        switch (report['status']) {
                          case 'pending':
                            statusColor = AppColors.warning;
                            break;
                          case 'investigating':
                            statusColor = AppColors.info;
                            break;
                          case 'resolved':
                            statusColor = AppColors.success;
                            break;
                          default:
                            statusColor = AppColors.textLight;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withValues(alpha: 0.1),
                              child: Icon(Icons.report_problem_rounded, color: statusColor, size: 20),
                            ),
                            title: Text(report['reason'] ?? report['title'] ?? 'Report',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '$dateStr • ${report['status'].toUpperCase()}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildReportDetailRow(Icons.work_rounded, 'Job Details', 
                                      'Title: ${job['title'] ?? report['jobTitle'] ?? 'N/A'}\n'
                                      'Category: ${job['category'] ?? 'N/A'}\n'
                                      'Wage: ₹${job['wage'] ?? 'N/A'} / ${job['wageType'] ?? 'N/A'}\n'
                                      'Location: ${job['location']?['address'] ?? 'N/A'}'),
                                    const SizedBox(height: 12),
                                    _buildReportDetailRow(Icons.person_rounded, 'Worker Details (Reporter)', 
                                      'Name: ${user['name'] ?? report['workerName'] ?? 'N/A'}\n'
                                      'Phone: ${user['phone'] ?? 'N/A'}\n'
                                      'Email: ${user['email'] ?? 'N/A'}'),
                                    const SizedBox(height: 12),
                                    _buildReportDetailRow(Icons.business_center_rounded, 'Recruiter Details (Reported)', 
                                      'Name: ${recruiter['name'] ?? report['recruiterName'] ?? 'N/A'}\n'
                                      'Phone: ${recruiter['phone'] ?? 'N/A'}\n'
                                      'Email: ${recruiter['email'] ?? 'N/A'}'),
                                    const SizedBox(height: 12),
                                    _buildReportDetailRow(Icons.info_outline_rounded, 'Report Reason', 
                                      '${report['reason'] ?? 'N/A'}\nDescription: ${report['description'] ?? 'No description'}'),
                                      
                                    if (report['screenshot'] != null) ...[
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () => _showImagePreview(context,
                                            report['screenshot'], 'Screenshot'),
                                        child: Container(
                                          height: 120,
                                          width: 200,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: report['screenshot'],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Divider(height: 32),
                                    Text('updateStatusLabel2'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        'pending',
                                        'resolved',
                                      ].map((s) => ActionChip(
                                        label: Text(s.toUpperCase(), style: TextStyle(
                                          fontSize: 12,
                                          color: s == report['status'] ? Colors.white : Colors.black,
                                        )),
                                        onPressed: () => _updateReportStatus(report['_id'], s),
                                        backgroundColor: s == report['status']
                                            ? AppColors.primary
                                            : AppColors.inputBg,
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDetailRow(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textMedium),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark)),
            ],
          ),
        )
      ],
    );
  }

  Future<void> _updateSosStatus(String alertId, String status) async {
    setState(() => _processing = true);
    try {
      await ApiService.patch('${ApiConfig.adminSosAlerts}/$alertId', {'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('sosMarked'.tr(args: [status])),
          backgroundColor: status == 'resolved' ? AppColors.success : AppColors.warning,
        ));
        _loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _buildSosPage() {
    final pending = _sosAlerts.where((a) => a['status'] == 'pending').toList();
    final others = _sosAlerts.where((a) => a['status'] != 'pending').toList();
    final all = [...pending, ...others];

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('sosAlertsTitle'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadAll),
        ],
      ),
      body: all.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                  const SizedBox(height: 16),
                  Text('noSosAlerts'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('allWorkersSafe'.tr(), style: const TextStyle(color: AppColors.textLight)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: all.length,
                itemBuilder: (_, i) {
                  final alert = all[i];
                  final isPending = alert['status'] == 'pending';
                  final worker = alert['workerId'] ?? {};
                  final createdAt = alert['createdAt'] != null
                      ? DateTime.tryParse(alert['createdAt'])
                      : null;
                  final timeStr = createdAt != null
                      ? '${createdAt.toLocal().hour.toString().padLeft(2, '0')}:${createdAt.toLocal().minute.toString().padLeft(2, '0')} • ${createdAt.toLocal().day}/${createdAt.toLocal().month}/${createdAt.toLocal().year}'
                      : 'Unknown time';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: isPending ? 3 : 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: isPending ? Border.all(color: AppColors.danger, width: 2) : null,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? AppColors.danger
                                      : alert['status'] == 'acknowledged'
                                          ? AppColors.warning
                                          : AppColors.success,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (alert['status'] as String? ?? 'pending').toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const Spacer(),
                              Text(timeStr, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                                child: Text(
                                  ((worker['name'] ?? alert['workerName'] ?? '?') as String).isNotEmpty
                                      ? (worker['name'] ?? alert['workerName'] ?? '?')[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(worker['name'] ?? alert['workerName'] ?? 'Unknown Worker',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    Text(worker['phone'] ?? alert['workerPhone'] ?? 'No phone',
                                        style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.call_rounded, color: AppColors.success),
                                onPressed: () async {
                                  final phone = worker['phone'] ?? alert['workerPhone'];
                                  if (phone != null) {
                                    final url = Uri.parse('tel:$phone');
                                    if (await canLaunchUrl(url)) launchUrl(url);
                                  }
                                },
                              ),
                            ],
                          ),
                          if (alert['lat'] != null && alert['lng'] != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 16, color: AppColors.danger),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Lat: ${(alert['lat'] as num).toStringAsFixed(5)}, Lng: ${(alert['lng'] as num).toStringAsFixed(5)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final url = Uri.parse('https://maps.google.com/?q=${alert['lat']},${alert['lng']}');
                                    if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                                  },
                                  icon: const Icon(Icons.map_rounded, size: 16),
                                  label: Text('viewMap'.tr(), style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                          if (isPending) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateSosStatus(alert['_id'], 'acknowledged'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.warning,
                                      side: const BorderSide(color: AppColors.warning),
                                      minimumSize: const Size(0, 36),
                                    ),
                                    child: Text('sosAcknowledge'.tr(), style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateSosStatus(alert['_id'], 'resolved'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      minimumSize: const Size(0, 36),
                                    ),
                                    child: Text('sosResolve'.tr(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    setState(() => _processing = true);
    try {
      final res = await ApiService.put(
          '${ApiConfig.reports}/$reportId', {'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Status updated'),
          backgroundColor: AppColors.success,
        ));
        _loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}

class _KycMiniCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onAction;
  final Function(String)? onApprove;
  final Function(String)? onReject;
  final Function(String, String)? onPreview;

  const _KycMiniCard({
    required this.user,
    required this.onAction,
    this.onApprove,
    this.onReject,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailsDialog(context, user),
      child: _KycCard(
        user: user,
        onAction: onAction,
        mini: true,
        onApprove: onApprove,
        onReject: onReject,
        onPreview: onPreview,
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _KycCard(
              user: user,
              onAction: onAction,
              onApprove: onApprove,
              onReject: onReject,
              onPreview: onPreview,
            ),
          ),
        ),
      ),
    );
  }
}

class _KycCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onAction;
  final bool mini;
  final Function(String)? onApprove;
  final Function(String)? onReject;
  final Function(String, String)? onPreview;

  const _KycCard({
    required this.user,
    required this.onAction,
    this.mini = false,
    this.onApprove,
    this.onReject,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final isDriverReview = user['workerType'] == 'driver' &&
        user['driverProfile'] != null &&
        user['driverProfile']['kycStatus'] != null;
    final kycStatus = isDriverReview
        ? user['driverProfile']['kycStatus']
        : (user['kycStatus'] ?? 'pending');
    final isPending = kycStatus == 'pending';
    final isUserDriver = user['role'] == 'driver' ||
        user['isDriver'] == true ||
        user['workerType'] == 'driver';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0DA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (user['name'] != null && user['name'].toString().isNotEmpty)
                      ? user['name'].toString()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? 'Unknown',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2)),
                    Text(user['phone'] ?? 'No phone',
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 12.5)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      width: 1),
                ),
                child: Text(kycStatus.toString().toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          if (!mini) ...[
            const Divider(height: 24),
            _detailRow('Father\'s Name', user['fatherName'] ?? 'N/A'),
            _detailRow('Aadhaar', user['aadhaarNumber'] ?? 'N/A'),
            _detailRow(
                'Skills', (user['skills'] as List?)?.join(', ') ?? 'N/A'),
            if (isUserDriver && user['driverProfile'] != null) ...[
              const SizedBox(height: 8),
              Text('driverDetailsLabel'.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.primary)),
              _detailRow(
                  'License', user['driverProfile']['licenseNumber'] ?? 'N/A'),
              _detailRow(
                  'Vehicle', user['driverProfile']['vehicleType'] ?? 'N/A'),
            ],
            const SizedBox(height: 16),
            Text('documentsLabel'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (user['aadhaarImage'] != null)
                    _docPreview(context, user['aadhaarImage'], 'Aadhaar Front'),
                  if (user['aadhaarBackImage'] != null)
                    _docPreview(
                        context, user['aadhaarBackImage'], 'Aadhaar Back'),
                  if (user['livePhotoUrl'] != null)
                    _docPreview(context, user['livePhotoUrl'], 'Live Photo'),
                  if (isUserDriver &&
                      user['driverProfile']?['licenceFrontUrl'] != null)
                    _docPreview(
                        context,
                        user['driverProfile']['licenceFrontUrl'],
                        'Licence Front'),
                  if (isUserDriver &&
                      user['driverProfile']?['licenceBackUrl'] != null)
                    _docPreview(
                        context,
                        user['driverProfile']['licenceBackUrl'],
                        'Licence Back'),
                ],
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onReject?.call(user['_id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: Text('rejectBtn'.tr()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onApprove?.call(user['_id']),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text('approveBtn'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else if (isUserDriver) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/admin/driver-kyc'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: Text('reviewDriverDocs'.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _docPreview(BuildContext context, String url, String label) {
    return GestureDetector(
      onTap: () => onPreview?.call(url, label),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          color: AppColors.inputBg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              color: Colors.white,
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onAction;
  const _UserCard({required this.user, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isBlocked = user['isBlocked'] == true;
    final kycStatus = user['kycStatus'] ?? 'pending';
    Color kycColor = kycStatus == 'approved'
        ? AppColors.success
        : kycStatus == 'rejected'
            ? AppColors.danger
            : AppColors.warning;

    return GestureDetector(
      onTap: () => _showUserDetails(context, user, kycStatus, kycColor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0DA), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user['profileImage'] != null && user['profileImage'].toString().isNotEmpty
                  ? CachedNetworkImageProvider(user['profileImage'])
                  : null,
              child: user['profileImage'] == null || user['profileImage'].toString().isEmpty
                  ? Text((user['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? 'N/A',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2)),
                  Text(user['phone'] ?? 'N/A',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textLight)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1),
                        ),
                        child: Text(
                            user['role']?.toString().toUpperCase() ?? '',
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.5)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kycColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: kycColor.withValues(alpha: 0.2), width: 1),
                        ),
                        child: Text(kycStatus.toString().toUpperCase(),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: kycColor,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: user['role'] == 'admin'
                  ? null
                  : () async {
                      final state = context
                          .findAncestorStateOfType<_AdminHomeScreenState>();
                      if (state == null) return;
                      state.setProcessing(true);
                      try {
                        final res = await ApiService.put(
                            '${ApiConfig.adminToggleBlock}/${user['_id']}/block',
                            {});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res['message'] ?? 'Status updated'),
                            backgroundColor: AppColors.info,
                            behavior: SnackBarBehavior.floating,
                          ));
                          state._loadAll();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      } finally {
                        state.setProcessing(false);
                      }
                    },
              style: TextButton.styleFrom(
                foregroundColor:
                    isBlocked ? AppColors.success : AppColors.danger,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                  user['role'] == 'admin'
                      ? 'SYSTEM'
                      : (isBlocked ? 'Unblock' : 'Block'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(
      BuildContext context, dynamic user, String kycStatus, Color kycColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: user['profileImage'] != null &&
                                  user['profileImage'].toString().isNotEmpty
                              ? CachedNetworkImageProvider(user['profileImage'])
                              : null,
                          child: user['profileImage'] == null ||
                                  user['profileImage'].toString().isEmpty
                              ? Text((user['name'] ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 32,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['name'] ?? 'N/A',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(user['phone'] ?? 'N/A',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: kycColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(kycStatus.toString().toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: kycColor)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('generalInfo'.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _detailRowLarge('Role',
                        user['role']?.toString().toUpperCase() ?? 'N/A'),
                    _detailRowLarge('Village/City', user['village'] ?? 'N/A'),
                    _detailRowLarge(
                        'Joined On',
                        user['createdAt'] != null
                            ? DateFormat('dd MMM yyyy')
                                .format(DateTime.parse(user['createdAt']).toLocal())
                            : 'N/A'),
                    if (user['role'] == 'worker') ...[
                      _detailRowLarge(
                          'Worker Type',
                          user['workerType']?.toString().toUpperCase() ??
                              'GENERAL'),
                      _detailRowLarge('Skills',
                          (user['skills'] as List?)?.join(', ') ?? 'None'),
                      _detailRowLarge('Experience',
                          '${user['experienceYears'] ?? 0} Years'),
                      _detailRowLarge(
                          'Aadhaar Number', user['aadhaarNumber'] ?? 'N/A'),
                    ] else if (user['role'] == 'recruiter') ...[
                      _detailRowLarge(
                          'Company Name', user['companyName'] ?? 'N/A'),
                      _detailRowLarge(
                          'Business Area', user['businessArea'] ?? 'N/A'),
                    ],
                    const SizedBox(height: 32),
                    Text('kycDocs'.tr(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (user['role'] == 'worker') ...[
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (user['aadhaarImage'] != null &&
                                user['aadhaarImage'].toString().isNotEmpty)
                              _docThumbLarge(context, user['aadhaarImage'],
                                  'Aadhaar Front'),
                            if (user['aadhaarBackImage'] != null &&
                                user['aadhaarBackImage'].toString().isNotEmpty)
                              _docThumbLarge(context, user['aadhaarBackImage'],
                                  'Aadhaar Back'),
                            if (user['livePhotoUrl'] != null &&
                                user['livePhotoUrl'].toString().isNotEmpty)
                              _docThumbLarge(
                                  context, user['livePhotoUrl'], 'Live Photo'),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                          'No KYC documents required for recruiters yet.',
                          style: TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey)),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRowLarge(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _docThumbLarge(BuildContext context, String url, String label) {
    return GestureDetector(
      onTap: () {
        // Find the state to use the _showImagePreview method
        final state = context.findAncestorStateOfType<_AdminHomeScreenState>();
        state?._showImagePreview(context, url, label);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          color: AppColors.inputBg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              color: Colors.white,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

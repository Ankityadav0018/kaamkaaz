import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../providers/stats_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTime? _lastUpdated;
  int _selectedDays = 30;

  String _formatNumber(dynamic n) {
    if (n == null) return '0';
    final formatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0);
    return formatter.format(n is String ? double.tryParse(n) ?? 0 : n);
  }

  String _getUpdatedText() {
    if (_lastUpdated == null) return '';
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inMinutes < 1) return LocaleKeys.justNow.tr();
    return LocaleKeys.updatedMinsAgo.tr(args: [diff.inMinutes.toString()]);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsStatsProvider(_selectedDays));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(analyticsStatsProvider(_selectedDays).future),
        child: analyticsAsync.when(
          loading: () => CustomScrollView(slivers: [
            SliverAppBar(title: Text(LocaleKeys.adminAnalytics.tr())),
            SliverFillRemaining(child: _buildSkeleton())
          ]),
          error: (err, _) => CustomScrollView(slivers: [
            SliverAppBar(title: Text(LocaleKeys.adminAnalytics.tr())),
            SliverFillRemaining(child: Center(child: Text(err.toString())))
          ]),
          data: (data) {
            if (_lastUpdated == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _lastUpdated = DateTime.now());
              });
            }
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Row(
                    children: [
                      Text(LocaleKeys.adminAnalytics.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      const Text('Live', style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [
                    if (_lastUpdated != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(_getUpdatedText(),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textLight)),
                        ),
                      ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _buildDateRangeSelector(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _sectionTitle(LocaleKeys.overview.tr()),
                      _buildOverviewGrid(data),
                      const SizedBox(height: 24),
                      _sectionTitle(LocaleKeys.kycHealth.tr()),
                      _buildKycHealth(data),
                      const SizedBox(height: 24),
                      _sectionTitle(LocaleKeys.registrationTrend.tr()),
                      _buildRegistrationTrendChart(data),
                      const SizedBox(height: 24),
                      _sectionTitle(LocaleKeys.jobsByCategory.tr()),
                      _buildJobsByCategoryChart(data),
                      const SizedBox(height: 24),
                      _sectionTitle(LocaleKeys.topAreas.tr()),
                      _buildTopAreas(data),
                      const SizedBox(height: 24),
                      _sectionTitle(LocaleKeys.platformHealth.tr()),
                      _buildPlatformHealth(data),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
      );

  Widget _buildDateRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _rangeButton('7 Days', 7),
          _rangeButton('30 Days', 30),
          _rangeButton('90 Days', 90),
          _rangeButton('All Time', 3650),
        ],
      ),
    );
  }

  Widget _rangeButton(String label, int days) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDays = days);
        // Reset last updated to show refreshing state
        _lastUpdated = null;
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textMedium, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildOverviewGrid(Map<String, dynamic> data) {
    final o = data['overview'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: [
        _statCard(
            LocaleKeys.totalWorkers.tr(), _formatNumber(o['totalWorkers']), onTap: () => context.push('/admin/users')),
        _statCard(LocaleKeys.totalRecruiters.tr(),
            _formatNumber(o['totalRecruiters']), onTap: () => context.push('/admin/recruiters')),
        _statCard(
            LocaleKeys.jobsToday.tr(), _formatNumber(o['jobsPostedToday']), onTap: () => context.push('/admin/jobs')),
        _statCard(LocaleKeys.totalHires.tr(), _formatNumber(o['totalHires'])),
        _statCard(LocaleKeys.totalApplications.tr(),
            _formatNumber(o['totalApplications'])),
        _statCard(
            LocaleKeys.activeDisputes.tr(), _formatNumber(o['activeDisputes']),
            isDanger: (o['activeDisputes'] ?? 0) > 0),
      ],
    );
  }

  Widget _statCard(String label, String value, {bool isDanger = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDanger
                  ? AppColors.danger.withValues(alpha: 0.3)
                  : Colors.transparent),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color:
                                isDanger ? AppColors.danger : AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                if (isDanger)
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.danger, shape: BoxShape.circle)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycHealth(Map<String, dynamic> data) {
    final k = data['kyc'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _kycCard(LocaleKeys.workers.tr(), k['workersPendingKYC'],
              () => context.push('/admin/kyc-pending')),
          _kycCard(LocaleKeys.drivers.tr(), k['driversPendingKYC'],
              () => context.push('/admin/driver-kyc')),
          _kycCard(
              LocaleKeys.recruiters.tr(),
              k['recruitersPendingVerification'],
              () => context.push('/admin/recruiters')),
          _kycCard(LocaleKeys.verified.tr(), k['workersVerified'], null,
              isVerified: true),
        ],
      ),
    );
  }

  Widget _kycCard(String label, int count, VoidCallback? onTap,
      {bool isVerified = false}) {
    final hasPending = !isVerified && count > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isVerified
              ? AppColors.success.withValues(alpha: 0.05)
              : (hasPending
                  ? Colors.amber.withValues(alpha: 0.1)
                  : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isVerified
                  ? AppColors.success.withValues(alpha: 0.2)
                  : (hasPending
                      ? Colors.amber.withValues(alpha: 0.3)
                      : AppColors.border.withValues(alpha: 0.3))),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium)),
            const SizedBox(height: 6),
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isVerified
                        ? AppColors.success
                        : (hasPending
                            ? Colors.orange[800]
                            : AppColors.textDark))),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationTrendChart(Map<String, dynamic> data) {
    final trend = (data['registrationTrend'] as List);
    if (trend.isEmpty) return const SizedBox();

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final dateStr = trend[spot.x.toInt()]['date'] as String;
                  final date = DateTime.parse(dateStr);
                  final isWorker = spot.barIndex == 0;
                  return LineTooltipItem(
                    '${DateFormat('MMM dd').format(date.toLocal())}\n${isWorker ? 'Workers' : 'Recruiters'}: ${spot.y.toInt()}',
                    TextStyle(color: isWorker ? Colors.tealAccent : Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (val, meta) {
                  if (val.toInt() < 0 || val.toInt() >= trend.length) {
                    return const SizedBox();
                  }
                  final dateStr = trend[val.toInt()]['date'] as String;
                  final date = DateTime.parse(dateStr);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(DateFormat('dd MMM').format(date.toLocal()),
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textLight)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend
                  .asMap()
                  .entries
                  .map((e) => FlSpot(
                      e.key.toDouble(), (e.value['workers'] as int).toDouble()))
                  .toList(),
              isCurved: true,
              color: Colors.teal,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true, color: Colors.teal.withValues(alpha: 0.1)),
            ),
            LineChartBarData(
              spots: trend
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(),
                      (e.value['recruiters'] as int).toDouble()))
                  .toList(),
              isCurved: true,
              color: Colors.deepPurple,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true, color: Colors.deepPurple.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsByCategoryChart(Map<String, dynamic> data) {
    final cats = (data['jobsByCategory'] as List).take(8).toList();
    if (cats.isEmpty) return const SizedBox();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: cats.fold<double>(
                  0,
                  (max, e) => (e['count'] as int) > max
                      ? (e['count'] as int).toDouble()
                      : max) *
              1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${cats[groupIndex]['category']}\n${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) => Text(val.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textLight)),
                reservedSize: 30,
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: cats.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (e.value['count'] as int).toDouble(),
                  color: AppColors.primary,
                  width: 14,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopAreas(Map<String, dynamic> data) {
    final areas = (data['topAreas'] as List);
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: areas.asMap().entries.map((e) {
          final isLast = e.key == areas.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text((e.key + 1).toString(),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold))),
                title: Text(e.value['area'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${LocaleKeys.jobs.tr()}: ${e.value['jobCount']}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(
                        '${LocaleKeys.workers.tr()}: ${e.value['workerCount']}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 70),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlatformHealth(Map<String, dynamic> data) {
    final ph = data['platformHealth'];
    final overview = data['overview'];
    final totalJobs = overview['totalJobsPosted'] as int;
    final zeroApps = ph['jobsWithZeroApplicants'] as int;
    final isAmber = totalJobs > 0 && (zeroApps / totalJobs) > 0.1;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: [
        _healthCard(LocaleKeys.zeroApplicants.tr(),
            ph['jobsWithZeroApplicants'].toString(),
            isAlert: isAmber),
        _healthCard(
            LocaleKeys.neverApplied.tr(), ph['workersNeverApplied'].toString()),
        _healthCard(LocaleKeys.avgAppsPerJob.tr(),
            ph['avgApplicationsPerJob'].toString()),
        _healthCard(
            LocaleKeys.avgKycHrs.tr(), ph['avgKYCApprovalHours'].toString()),
      ],
    );
  }

  Widget _healthCard(String label, String value, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAlert ? Colors.amber[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isAlert
                ? Colors.amber.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isAlert ? Colors.amber[900] : AppColors.textMedium,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isAlert ? Colors.amber[900] : AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: List.generate(
                  6,
                  (_) => Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)))),
            ),
            const SizedBox(height: 24),
            Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 24),
            Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }
}

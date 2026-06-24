import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _masterToggle = true;
  bool _urgentAlertsEnabled = true;
  bool _applicationStatusAlerts = true;
  bool _jobReminders = true;
  List<String> _selectedCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _masterToggle = prefs.getBool('notif_master') ?? true;
      _urgentAlertsEnabled = prefs.getBool('notif_urgent_alerts') ?? true;
      _applicationStatusAlerts = prefs.getBool('notif_app_status') ?? true;
      _jobReminders = prefs.getBool('notif_job_reminders') ?? true;
      _selectedCategories = prefs.getStringList('notif_categories') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleUrgentAlerts(bool val) async {
    setState(() => _urgentAlertsEnabled = val);
    await _saveToggle('notif_urgent_alerts', val);
    try {
      await ApiService.put(ApiConfig.toggleUrgentAlerts, {'enabled': val});
    } catch (e) {
      debugPrint('Failed to sync urgent alert settings');
    }
  }

  Future<void> _toggleCategory(String category) async {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
        NotificationService.unsubscribeFromJobCategory(category);
      } else {
        _selectedCategories.add(category);
        NotificationService.subscribeToJobCategory(category);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notif_categories', _selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text('notificationSettingsTitle'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text('enableAllNotifications'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            subtitle: Text('masterToggleDesc'.tr()),
            value: _masterToggle,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _masterToggle = val);
              _saveToggle('notif_master', val);
            },
          ),
          const Divider(),
          if (_masterToggle) ...[
            SwitchListTile(
              title: const Text('Urgent Job Alerts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              subtitle: const Text('Alarm-style notification for urgent nearby jobs.'),
              value: _urgentAlertsEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: _toggleUrgentAlerts,
            ),
            const Divider(),
            SwitchListTile(
              title: Text('applicationStatusUpdates'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('appStatusDesc'.tr()),
              value: _applicationStatusAlerts,
              activeThumbColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _applicationStatusAlerts = val);
                _saveToggle('notif_app_status', val);
              },
            ),
            SwitchListTile(
              title: Text('jobReminders'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('jobRemindersDesc'.tr()),
              value: _jobReminders,
              activeThumbColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _jobReminders = val);
                _saveToggle('notif_job_reminders', val);
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'jobAlertCategories'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'jobAlertCategoriesDesc'.tr(),
                style: const TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: JOB_CATEGORIES.map((cat) {
                final isSelected = _selectedCategories.contains(cat.id);
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(cat.name, style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold
                      )),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  onSelected: (_) => _toggleCategory(cat.id),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

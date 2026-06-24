import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class AdminSkillBadgeScreen extends StatefulWidget {
  const AdminSkillBadgeScreen({super.key});

  @override
  State<AdminSkillBadgeScreen> createState() => _AdminSkillBadgeScreenState();
}

class _AdminSkillBadgeScreenState extends State<AdminSkillBadgeScreen> {
  List<dynamic> _pendingBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    try {
      final res = await ApiService.get(ApiConfig.adminPendingBadges);
      if (res['success'] == true) {
        if (!mounted) return;
        setState(() {
          _pendingBadges = res['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(String id, String action, String? note) async {
    try {
      final res = await ApiService.patch('${ApiConfig.adminUpdateBadge}/$id', {
        'action': action,
        'adminNote': note,
      });
      if (res['success'] == true) {
        _fetchPending();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Badge ${action == 'verify' ? 'Verified' : 'Rejected'}'),
                backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('pendingSkillBadges'.tr())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingBadges.isEmpty
              ? Center(child: Text('noPendingSkillBadges'.tr()))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingBadges.length,
                  itemBuilder: (context, index) {
                    final badge = _pendingBadges[index];
                    final worker = badge['workerId'];
                    return _BadgeRequestCard(
                      badge: badge,
                      worker: worker,
                      onAction: (action, note) =>
                          _handleAction(badge['_id'], action, note),
                    );
                  },
                ),
    );
  }
}

class _BadgeRequestCard extends StatelessWidget {
  final dynamic badge;
  final dynamic worker;
  final Function(String, String?) onAction;

  const _BadgeRequestCard(
      {required this.badge, required this.worker, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final hasProof = badge['documentUrl'] != null &&
        badge['documentUrl'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(worker?['name']?[0]?.toUpperCase() ?? '?',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker?['name'] ?? 'Unknown User',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(worker?['phone'] ?? '',
                        style: const TextStyle(
                            color: AppColors.textMedium, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                    kSkillsList
                        .firstWhere((s) => s.id == badge['skill'],
                            orElse: () =>
                                const SkillInfo('', '', Icons.handyman_rounded))
                        .name,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasProof) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () =>
                    _showFullscreenImage(context, badge['documentUrl']),
                child: CachedNetworkImage(
                  imageUrl: badge['documentUrl'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                      color: Colors.grey.shade100,
                      child: const Center(child: CircularProgressIndicator())),
                  errorWidget: (_, __, ___) =>
                      const Center(child: Icon(Icons.error)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger)),
                  child: Text('rejectBtn'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onAction('verify', null),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success),
                  child: Text('verifyBtn'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('rejectBadgeReq'.tr()),
        content: VoiceTextField(
          controller: ctrl,
          decoration:
              InputDecoration(hintText: 'enterReasonForRejection'.tr()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancelBtn'.tr())),
          ElevatedButton(
            onPressed: () {
              onAction('reject', ctrl.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('rejectBtn'.tr()),
          ),
        ],
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            InteractiveViewer(
                child: Center(child: CachedNetworkImage(imageUrl: url))),
            Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                )),
          ],
        ),
      ),
    );
  }
}

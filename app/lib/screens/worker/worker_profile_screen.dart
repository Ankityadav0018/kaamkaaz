import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/locale_keys.g.dart';

class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    if (user == null) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(LocaleKeys.myProfile.tr(),
            style: TextStyle(fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/worker/profile/edit'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(authProvider.notifier).refreshUser(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                      child: Text(user.name[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: cs.primary)),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 4),
                    Text('+91 ${user.phone}',
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                    if (user.email.isNotEmpty && user.email.toLowerCase() != 'none' && user.email.toLowerCase() != 'null') ...[
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5), fontSize: 14)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),



              _sectionHeader(context, LocaleKeys.userInformation.tr()),
              _card(context, [
                _infoTile(context,
                    Icons.location_on_outlined,
                    LocaleKeys.villageCity.tr(),
                    user.village.isEmpty
                        ? LocaleKeys.notSet.tr()
                        : user.village),
                Divider(color: theme.dividerColor),
                _infoTile(context, Icons.badge_outlined, LocaleKeys.role.tr(),
                    LocaleKeys.worker.tr()),
              ]),
              const SizedBox(height: 16),

              _sectionHeader(context, LocaleKeys.skills.tr()),
              _card(context, [
                if (user.skills.isEmpty)
                  Text(LocaleKeys.noSkillsAdded.tr(),
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5)))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.skills
                        .map((s) => Chip(
                              label:
                                  Text(s, style: TextStyle(fontSize: 12, color: cs.primary)),
                              backgroundColor:
                                  cs.primary.withValues(alpha: 0.08),
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
              ]),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
                letterSpacing: 1.2)),
      );

  Widget _card(BuildContext context, List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _infoTile(BuildContext context, IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6))),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                ],
              ),
            )
          ],
        ),
      );
}

import '../l10n/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/rating_provider.dart';
import '../utils/app_colors.dart';

class RatingsBottomSheet extends ConsumerWidget {
  final String userId;
  const RatingsBottomSheet({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(userRatingsProvider(userId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 16),
            Text(LocaleKeys.ratingsAndFeedback.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ratingsAsync.when(
                data: (ratings) => ratings.isEmpty
                    ? Center(child: Text(LocaleKeys.noReviewsYetAlt.tr()))
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: ratings.length,
                        itemBuilder: (_, i) {
                          final r = ratings[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(
                                        5,
                                        (index) => Icon(
                                              index < r.score
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              size: 16,
                                              color: Colors.amber,
                                            )),
                                    const Spacer(),
                                    Text(
                                        DateFormat('dd MMM yyyy')
                                            .format(r.createdAt.toLocal()),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textLight)),
                                  ],
                                ),
                                if (r.comment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(r.comment,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textDark)),
                                ],
                                const SizedBox(height: 4),
                                Text('byRaterName'.tr(args: [r.raterName, r.raterRole]), 
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMedium,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('errorPrefix'.tr(args: [err.toString()]))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

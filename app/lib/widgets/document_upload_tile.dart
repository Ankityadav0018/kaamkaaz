import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';

class DocumentUploadTile extends StatelessWidget {
  final String label;
  final String? uploadedUrl;
  final bool isMandatory;
  final bool isUploading;
  final VoidCallback onTap;

  const DocumentUploadTile({
    super.key,
    required this.label,
    required this.onTap,
    this.uploadedUrl,
    this.isMandatory = true,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDoc = uploadedUrl != null && uploadedUrl!.isNotEmpty;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasDoc
                ? AppColors.success.withValues(alpha: 0.5)
                : isUploading
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
            width: hasDoc ? 1.5 : 1,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            // Thumbnail or placeholder
            _buildThumbnail(hasDoc),
            const SizedBox(width: 14),
            // Label + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (isMandatory) ...[
                        const SizedBox(width: 4),
                        const Text('*',
                            style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (isUploading)
                    const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Uploading...',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  else if (hasDoc)
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Uploaded ✓',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Not uploaded',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Upload button / retake
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasDoc
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasDoc
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                hasDoc ? 'Retake' : 'Upload',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: hasDoc ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool hasDoc) {
    return Container(
      width: 80,
      height: 64,
      decoration: BoxDecoration(
        color: hasDoc ? Colors.transparent : AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasDoc
          ? CachedNetworkImage(
              imageUrl: uploadedUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 200,
              memCacheHeight: 200,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image_rounded,
                    color: AppColors.textLight, size: 28),
              ),
            )
          : Center(
              child: Icon(
                _getIcon(),
                color: AppColors.textLight,
                size: 28,
              ),
            ),
    );
  }

  IconData _getIcon() {
    if (label.toLowerCase().contains('licence') ||
        label.toLowerCase().contains('aadhaar') ||
        label.toLowerCase().contains('rc')) {
      return Icons.badge_rounded;
    }
    if (label.toLowerCase().contains('photo')) {
      return Icons.person_rounded;
    }
    if (label.toLowerCase().contains('police') ||
        label.toLowerCase().contains('verification')) {
      return Icons.verified_user_rounded;
    }
    return Icons.upload_file_rounded;
  }
}

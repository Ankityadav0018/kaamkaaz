import '../l10n/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/app_colors.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class RatingDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(int score, String comment) onSubmit;

  const RatingDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSubmit,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _score = 5;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Text(widget.subtitle,
              style:
                  const TextStyle(color: AppColors.textMedium, fontSize: 14)),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 0,
            children: List.generate(5, (index) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() => _score = index + 1);
                },
                icon: Icon(
                  index < _score
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.accent,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          VoiceTextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'addCommentOptionalHint'.tr(),
              filled: true,
              fillColor: AppColors.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.cancelBtn.tr())),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(_score, _commentCtrl.text);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(LocaleKeys.submitRatingBtn.tr()),
        ),
      ],
    );
  }
}

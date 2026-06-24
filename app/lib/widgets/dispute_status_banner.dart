import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../l10n/locale_keys.g.dart';
import '../screens/shared/my_disputes_screen.dart';

class DisputeStatusBanner extends StatelessWidget {
  const DisputeStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyDisputesScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          border: Border(bottom: BorderSide(color: Colors.amber.shade300)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LocaleKeys.disputeBanner.tr(),
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.amber.shade900, size: 20),
          ],
        ),
      ),
    );
  }
}

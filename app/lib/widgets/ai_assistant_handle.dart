import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_colors.dart';
import '../utils/app_keys.dart';
import 'ai_assistant_overlay.dart';

class AIAssistantHandle extends StatefulWidget {
  final GoRouter router;
  const AIAssistantHandle({super.key, required this.router});

  @override
  State<AIAssistantHandle> createState() => _AIAssistantHandleState();
}

class _AIAssistantHandleState extends State<AIAssistantHandle> {
  bool _isExpanded = false;

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  void _openAI(BuildContext context) {
    setState(() => _isExpanded = false);
    final navCtx = AppKeys.rootNavigatorKey.currentContext;
    final route = widget.router.routerDelegate.currentConfiguration.uri.toString();
    AIAssistantOverlay.show(navCtx ?? context, route);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      right: _isExpanded ? 16 : -64, // When hidden, hide the FAB, keep only the tab
      top: MediaQuery.of(context).size.height * 0.25, // Upper middle
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < -2) {
            // Swipe left -> Show
            if (!_isExpanded) setState(() => _isExpanded = true);
          } else if (details.delta.dx > 2) {
            // Swipe right -> Hide
            if (_isExpanded) setState(() => _isExpanded = false);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pull tab
            GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 24,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(-2, 0),
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isExpanded ? Icons.arrow_forward_ios_rounded : Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // The main AI FAB
            FloatingActionButton(
              heroTag: 'ai_assistant_fab_handle',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => _openAI(context),
              child: const Icon(Icons.auto_awesome_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

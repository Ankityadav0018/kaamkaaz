import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/voice_input_service.dart';
import 'listening_overlay.dart';
import 'dart:math' as math;

class VoiceTextField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;
  final bool obscureText;
  final bool showMic;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final bool autocorrect;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;
  final int? maxLength;
  final InputCounterWidgetBuilder? buildCounter;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;

  const VoiceTextField({
    super.key,
    this.controller,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.decoration,
    this.obscureText = false,
    this.showMic = false,
    this.validator,
    this.inputFormatters,
    this.readOnly = false,
    this.focusNode,
    this.prefixIcon,
    this.autocorrect = true,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onSubmitted,
    this.style,
    this.maxLength,
    this.buildCounter,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
  });

  @override
  ConsumerState<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends ConsumerState<VoiceTextField> with SingleTickerProviderStateMixin {
  late final String _fieldId;
  late AnimationController _pulseController;
  late TextEditingController _controller;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _fieldId = math.Random().nextInt(1000000).toString();
    _controller = widget.controller ?? TextEditingController();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleMic() async {
    final notifier = ref.read(voiceInputProvider.notifier);
    
    _previousText = _controller.text;
    if (_previousText.isNotEmpty && !_previousText.endsWith(' ')) {
      _previousText += ' ';
    }

    bool started = await notifier.toggleListening(
      fieldId: _fieldId,
      localeCode: context.locale.toString(),
      onResult: (text, isFinal) {
        final newText = _previousText + text;
        _controller.text = newText;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        if (widget.onChanged != null) {
          widget.onChanged!(newText);
        }
      },
    );

    if (started) {
      if (mounted) {
        ListeningOverlay.show(context);
      }
    } else {
      final state = ref.read(voiceInputProvider);
      if (!state.hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('micPermissionDenied'.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputProvider);
    final isThisFieldListening = voiceState.isListening && voiceState.activeFieldId == _fieldId;

    Widget? suffixIcon = widget.decoration?.suffixIcon;
    
    // Only show mic if enabled, not obscured, and not readonly
    if (widget.showMic && !widget.obscureText && !widget.readOnly) {
      final micIcon = GestureDetector(
        onTap: _toggleMic,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: isThisFieldListening
              ? AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.2),
                      child: const Icon(Icons.mic, color: Colors.red),
                    );
                  },
                )
              : const Icon(Icons.mic_none, color: Colors.grey),
        ),
      );

      if (suffixIcon != null) {
        suffixIcon = Row(
          mainAxisSize: MainAxisSize.min,
          children: [suffixIcon, micIcon],
        );
      } else {
        suffixIcon = micIcon;
      }
    }

    final inputDecoration = widget.decoration?.copyWith(
      suffixIcon: suffixIcon,
      prefixIcon: widget.prefixIcon ?? widget.decoration?.prefixIcon,
    ) ?? InputDecoration(
      hintText: widget.hintText,
      suffixIcon: suffixIcon,
      prefixIcon: widget.prefixIcon,
    );

    return TextFormField(
      controller: _controller,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      obscureText: widget.obscureText,
      decoration: inputDecoration,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      readOnly: widget.readOnly,
      focusNode: widget.focusNode,
      autocorrect: widget.autocorrect,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted ?? widget.onSubmitted,
      style: widget.style,
      maxLength: widget.maxLength,
      buildCounter: widget.buildCounter,
      textCapitalization: widget.textCapitalization,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
    );
  }
}

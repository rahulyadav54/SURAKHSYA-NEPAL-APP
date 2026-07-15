import 'package:flutter/material.dart';

class SurakshaButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const SurakshaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  @override
  State<SurakshaButton> createState() => _SurakshaButtonState();
}

class _SurakshaButtonState extends State<SurakshaButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );

    final secondaryStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isSecondary ? theme.colorScheme.primary : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.onPressed == null
                ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                : widget.isSecondary
                    ? theme.colorScheme.primary
                    : Colors.white,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: IgnorePointer(
          ignoring: true, 
          child: widget.isSecondary
              ? OutlinedButton(
                  onPressed: widget.onPressed,
                  style: secondaryStyle,
                  child: buttonContent,
                )
              : FilledButton(
                  onPressed: widget.onPressed,
                  style: baseStyle,
                  child: buttonContent,
                ),
        ),
      ),
    );
  }
}

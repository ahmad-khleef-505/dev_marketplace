import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GlassPanel extends StatefulWidget {
  const GlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.borderRadius = 16,
    this.color = const Color(0xFF1E293B),
    this.hoverable = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color color;
  final bool hoverable;

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hovered = kIsWeb && widget.hoverable && _isHovered;
    return MouseRegion(
      onEnter: widget.hoverable
          ? (_) => setState(() => _isHovered = true)
          : null,
      onExit: widget.hoverable
          ? (_) => setState(() => _isHovered = false)
          : null,
      child: AnimatedScale(
        scale: hovered ? 1.008 : 1,
        duration: const Duration(milliseconds: 160),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.16),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: RepaintBoundary(
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: hovered
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.55)
                        : const Color(0xFF475569).withValues(alpha: 0.65),
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'glass_panel.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.lottiePath,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionPressed,
    super.key,
  });

  final String lottiePath;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  bool get _isNetworkPath =>
      lottiePath.startsWith('http://') || lottiePath.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animation = _isNetworkPath
        ? Lottie.network(
            lottiePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackAnimation(context),
          )
        : Lottie.asset(
            lottiePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackAnimation(context),
          );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GlassPanel(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            borderRadius: 24,
            color: const Color(0xFF111C31),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 220, height: 190, child: animation),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF94A3B8),
                    height: 1.6,
                  ),
                ),
                if (actionLabel != null && onActionPressed != null) ...[
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onActionPressed,
                    icon: const Icon(Icons.explore_outlined),
                    label: Text(actionLabel!),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAnimation(BuildContext context) => const Center(
    child: Icon(Icons.inbox_outlined, size: 96, color: Color(0xFF60A5FA)),
  );
}

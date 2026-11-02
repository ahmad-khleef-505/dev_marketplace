import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../screens/project_detail_screen.dart';
import '../models/favorite_project.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../repositories/project_repository.dart';
import '../services/purchase_service.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String developerName;
  final String developerUid;
  final String projectId;
  final String projectType;
  final double price;
  final List<String> techStack;
  final double rating;
  final String imageUrl;
  final bool isEscrow;
  final String description;
  final String demoLink;
  final int ratingCount;
  final int views;
  final bool horizontal;

  const ProjectCard({
    super.key,
    required this.title,
    required this.developerName,
    this.developerUid = '',
    required this.projectId,
    required this.projectType,
    required this.price,
    required this.techStack,
    required this.rating,
    required this.imageUrl,
    required this.description,
    this.demoLink = '',
    this.isEscrow = true,
    this.ratingCount = 0,
    this.views = 0,
    this.horizontal = true,
  });

  Future<void> _recordView(BuildContext context) async {
    try {
      await context.read<ProjectRepository>().recordView(projectId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تسجيل مشاهدة المشروع: $error')),
        );
      }
    }
  }

  void _openProjectDetails(BuildContext context) {
    unawaited(_recordView(context));
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProjectDetailScreen(
          projectId: projectId,
          projectType: projectType,
          title: title,
          developerName: developerName,
          developerUid: developerUid,
          price: price,
          techStack: techStack,
          rating: rating,
          imageUrl: imageUrl,
          isEscrow: isEscrow,
          description: description,
          demoLink: demoLink,
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      final settings = await PurchaseService().publicSettings();
      final phone = (settings['adminWhatsAppPhone'] as String).replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final message = Uri.encodeComponent(
        'مرحباً مدير التطبيق، أتواصل معك من تطبيق Dev Marketplace بخصوص المشروع: "$title". أريد الاستعلام عن المزيد من التفاصيل.',
      );
      final url = Uri.parse('https://wa.me/$phone?text=$message');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تأكد من تثبيت تطبيق واتساب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _HoverProjectCard(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: RepaintBoundary(
          child: horizontal
              ? _buildHorizontalContents(context)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Hero(
                            tag: 'project-image-$projectId',
                            child: _ProjectCardImage(imageUrl: imageUrl),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _FavoriteProjectButton(
                            projectId: projectId,
                            title: title,
                            developerUid: developerUid,
                            developerName: developerName,
                            price: price,
                            imageUrl: imageUrl,
                            projectType: projectType,
                            techStack: techStack,
                            rating: rating,
                            ratingCount: ratingCount,
                            description: description,
                            demoLink: demoLink,
                            isEscrow: isEscrow,
                            views: views,
                          ),
                        ),
                        if (isEscrow)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Escrow',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: const Color(
                                  0xFF3B82F6,
                                ).withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  projectType == 'website'
                                      ? Icons.language
                                      : Icons.phone_iphone,
                                  size: 15,
                                  color: const Color(0xFF60A5FA),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  projectType == 'website'
                                      ? 'موقع (Website)'
                                      : 'تطبيق (App)',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 8,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.person,
                                      size: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 130,
                                    ),
                                    child: Text(
                                      developerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.visibility_outlined,
                                    size: 15,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    views.toString(),
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ratingCount > 0
                                        ? rating.toStringAsFixed(1)
                                        : 'جديد',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (ratingCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '($ratingCount)',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: techStack
                                .map(
                                  (tech) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                    child: Text(
                                      tech,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const Divider(color: Color(0xFF334155), height: 24),

                          // أزرار التحكم
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: OutlinedButton(
                                  onPressed: () => _openProjectDetails(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF3B82F6),
                                    side: const BorderSide(
                                      color: Color(0xFF3B82F6),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    'عرض التفاصيل',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openWhatsApp(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(Icons.chat, size: 14),
                                  label: const Text(
                                    'تواصل',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ).animate().fadeIn(duration: 220.ms);
  }

  Widget _buildHorizontalContents(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Hero(
                          tag: 'project-image-$projectId',
                          child: _ProjectCardImage(imageUrl: imageUrl),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 44),
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    developerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 17,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ratingCount > 0
                                      ? '${rating.toStringAsFixed(1)} ($ratingCount)'
                                      : 'جديد',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const Spacer(),
                                if (isEscrow)
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 17,
                                    color: colorScheme.secondary,
                                    semanticLabel: 'دفع آمن',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openProjectDetails(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('التفاصيل'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'تواصل مع المطور',
                    onPressed: () => _openWhatsApp(context),
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      backgroundColor: colorScheme.secondaryContainer,
                      fixedSize: const Size(40, 40),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _FavoriteProjectButton(
            projectId: projectId,
            title: title,
            developerUid: developerUid,
            developerName: developerName,
            price: price,
            imageUrl: imageUrl,
            projectType: projectType,
            techStack: techStack,
            rating: rating,
            ratingCount: ratingCount,
            description: description,
            demoLink: demoLink,
            isEscrow: isEscrow,
            views: views,
          ),
        ),
      ],
    );
  }
}

class _HoverProjectCard extends StatefulWidget {
  const _HoverProjectCard({required this.child});

  final Widget child;

  @override
  State<_HoverProjectCard> createState() => _HoverProjectCardState();
}

class _HoverProjectCardState extends State<_HoverProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: kIsWeb ? (_) => setState(() => _isHovered = true) : null,
      onExit: kIsWeb ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
                    blurRadius: 26,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: AnimatedScale(
          scale: _isHovered ? 1.012 : 1,
          duration: const Duration(milliseconds: 180),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ProjectCardImage extends StatefulWidget {
  const _ProjectCardImage({required this.imageUrl});

  final String imageUrl;

  @override
  State<_ProjectCardImage> createState() => _ProjectCardImageState();
}

class _ProjectCardImageState extends State<_ProjectCardImage> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: kIsWeb ? (_) => setState(() => _isHovered = true) : null,
      onExit: kIsWeb ? (_) => setState(() => _isHovered = false) : null,
      child: ClipRect(
        child: AnimatedScale(
          scale: _isHovered ? 1.07 : 1,
          duration: const Duration(milliseconds: 250),
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 100,
              width: 100,
              color: colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF60A5FA),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 100,
              width: 100,
              color: colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image,
                color: colorScheme.onSurfaceVariant,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteProjectButton extends StatelessWidget {
  const _FavoriteProjectButton({
    required this.projectId,
    required this.title,
    required this.developerUid,
    required this.developerName,
    required this.price,
    required this.imageUrl,
    required this.projectType,
    required this.techStack,
    required this.rating,
    required this.ratingCount,
    required this.description,
    required this.demoLink,
    required this.isEscrow,
    required this.views,
  });

  final String projectId;
  final String title;
  final String developerUid;
  final String developerName;
  final double price;
  final String imageUrl;
  final String projectType;
  final List<String> techStack;
  final double rating;
  final int ratingCount;
  final String description;
  final String demoLink;
  final bool isEscrow;
  final int views;

  Future<void> _toggleFavorite(BuildContext context) async {
    try {
      await context.read<FavoritesProvider>().toggleFavorite(
            FavoriteProject(
              projectId: projectId,
              title: title,
              developerUid: developerUid,
              developerName: developerName,
              price: price,
              imageUrl: imageUrl,
              projectType: projectType,
              techStack: techStack,
              averageRating: rating,
              ratingCount: ratingCount,
              description: description,
              demoLink: demoLink,
              isEscrow: isEscrow,
              views: views,
            ),
          );
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تحديث المفضلة: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, FavoritesProvider>(
      builder: (context, auth, favorites, _) => _FavoriteIconButton(
        isFavorite: favorites.isFavorite(projectId),
        onPressed: auth.currentUser == null
            ? () => _toggleFavorite(context)
            : favorites.isLoading || favorites.error != null
                ? null
                : () => _toggleFavorite(context),
      ),
    );
  }
}

class _FavoriteIconButton extends StatefulWidget {
  const _FavoriteIconButton({
    required this.isFavorite,
    required this.onPressed,
  });

  final bool isFavorite;
  final Future<void> Function()? onPressed;

  @override
  State<_FavoriteIconButton> createState() => _FavoriteIconButtonState();
}

class _FavoriteIconButtonState extends State<_FavoriteIconButton> {
  bool _isUpdating = false;

  Future<void> _handlePressed() async {
    final onPressed = widget.onPressed;
    if (onPressed == null || _isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await onPressed();
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: widget.isFavorite ? 'إزالة من المفضلة' : 'أضف إلى المفضلة',
        onPressed:
            widget.onPressed == null || _isUpdating ? null : _handlePressed,
        icon: _isUpdating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFB7185),
                ),
              )
            : Icon(
                widget.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: widget.isFavorite
                    ? const Color(0xFFFB7185)
                    : colorScheme.onSurface,
                size: 20,
              ),
      ),
    );
  }
}

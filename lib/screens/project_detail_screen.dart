import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'project_chat_screen.dart';
import 'developer_public_profile.dart';
import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../repositories/project_repository.dart';
import '../widgets/purchase_flow_dialog.dart';
import '../widgets/glass_panel.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  final String projectType;
  final String title;
  final String developerName;
  final String developerUid;
  final String developerPhone;
  final double price;
  final List<String> techStack;
  final double rating;
  final String imageUrl;
  final bool isEscrow;
  final String description;
  final String demoLink;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectType,
    required this.title,
    required this.developerName,
    this.developerUid = '',
    this.developerPhone = '',
    required this.price,
    required this.techStack,
    required this.rating,
    required this.imageUrl,
    required this.description,
    this.demoLink = '',
    this.isEscrow = true,
  });

  void _showPurchaseContactDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => PurchaseFlowDialog(
        projectTitle: title,
        projectType: projectType,
        developerName: developerName,
        projectLink: demoLink,
      ),
    );
  }

  Future<void> _openDeveloperProfile(BuildContext context) async {
    var uid = developerUid;
    if (uid.isEmpty) {
      try {
        final project = await context.read<ProjectRepository>().getProject(
          projectId,
        );
        uid = project?.developerId ?? '';
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر فتح ملف المطور: $error')),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    if (uid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تحديد حساب المطور.')));
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DeveloperPublicProfileScreen(
          developerUid: uid,
          initialDeveloperName: developerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080D19),
        appBar: AppBar(
          backgroundColor: const Color(0xFF080D19),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'رجوع',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          title: Text(
            'تفاصيل المشروع',
            style: GoogleFonts.cairo(
              color: const Color(0xFFCBD5E1),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: SingleChildScrollView(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              28,
                              10,
                              18,
                              40,
                            ),
                            child: _buildProjectOverview(context, isWide: true),
                          ),
                        ),
                        SizedBox(
                          width: 360,
                          child: SingleChildScrollView(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              10,
                              16,
                              24,
                              40,
                            ),
                            child: _buildPurchaseCard(context),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProjectOverview(context, isWide: false),
                          const SizedBox(height: 20),
                          _buildPurchaseCard(context),
                        ],
                      ),
                    );
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProjectOverview(BuildContext context, {required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: AspectRatio(
            aspectRatio: isWide ? 1.9 : 1.55,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'project-image-$projectId',
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF111C30),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF111C30),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image,
                        color: Color(0xFF64748B),
                        size: 52,
                      ),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x11080D19),
                        Color(0x00080D19),
                        Color(0xCC080D19),
                      ],
                      stops: [0, 0.4, 1],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 18,
                  start: 18,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _DetailBadge(
                        icon: projectType == 'website'
                            ? Icons.language_rounded
                            : Icons.phone_iphone_rounded,
                        label: projectType == 'website'
                            ? 'موقع إلكتروني'
                            : 'تطبيق جوال',
                        color: const Color(0xFF60A5FA),
                      ),
                      if (isEscrow)
                        const _DetailBadge(
                          icon: Icons.verified_user_rounded,
                          label: 'شراء محمي',
                          color: Color(0xFF34D399),
                        ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  start: 24,
                  end: 24,
                  bottom: 20,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: isWide ? 30 : 24,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      shadows: const [
                        Shadow(color: Color(0xAA38BDF8), blurRadius: 22),
                        Shadow(color: Colors.black54, blurRadius: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.025, end: 0),
        const SizedBox(height: 24),
        Wrap(
              spacing: 18,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _openDeveloperProfile(context),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 19,
                          backgroundColor: Color(0xFF172A46),
                          child: Icon(
                            Icons.person_outline,
                            color: Color(0xFF93C5FD),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              developerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'مطور المشروع',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111C30),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF25334B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFBBF24),
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'تقييم المشروع',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
            .animate(delay: 90.ms)
            .fadeIn(duration: 320.ms)
            .slideY(begin: 0.03, end: 0),
        const SizedBox(height: 30),
        _sectionLabel('عن المشروع', Icons.subject_rounded),
        const SizedBox(height: 12),
        GlassPanel(
              padding: const EdgeInsets.all(18),
              borderRadius: 16,
              color: const Color(0xFF101A2D),
              child: Text(
                description.isNotEmpty
                    ? description
                    : 'لا يوجد وصف متاح لهذا المشروع حالياً.',
                style: const TextStyle(
                  color: Color(0xFFB6C2D2),
                  fontSize: 14,
                  height: 1.9,
                ),
              ),
            )
            .animate(delay: 140.ms)
            .fadeIn(duration: 320.ms)
            .slideY(begin: 0.025, end: 0),
        const SizedBox(height: 28),
        _sectionLabel('التقنيات المستخدمة', Icons.auto_awesome_mosaic_rounded),
        const SizedBox(height: 14),
        Wrap(
              spacing: 9,
              runSpacing: 9,
              children: techStack
                  .map((tech) => _TechnologyChip(label: tech))
                  .toList(),
            )
            .animate(delay: 190.ms)
            .fadeIn(duration: 320.ms)
            .slideY(begin: 0.025, end: 0),
        const SizedBox(height: 28),
        _ProjectRatingSection(projectId: projectId),
        if (demoLink.isNotEmpty) ...[
          const SizedBox(height: 28),
          _sectionLabel('معاينة المشروع', Icons.open_in_new_rounded),
          const SizedBox(height: 12),
          _DemoLink(
            link: demoLink,
            onTap: () async {
              final finalUrl = demoLink.startsWith('http')
                  ? demoLink
                  : 'https://$demoLink';
              final launched = await launchUrl(
                Uri.parse(finalUrl),
                mode: LaunchMode.externalApplication,
              );
              if (!launched && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تعذر فتح رابط المعاينة.')),
                );
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF60A5FA)),
        const SizedBox(width: 9),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseCard(BuildContext context) {
    return GlassPanel(
          borderRadius: 24,
          color: const Color(0xFF111B2D),
          padding: const EdgeInsets.all(24),
          hoverable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sell_outlined,
                    color: Color(0xFF60A5FA),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'احصل على المشروع',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 8, bottom: 5),
                    child: Text(
                      'USD',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF26364F), height: 1),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      developerName,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFBBF24),
                    size: 17,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _PurchaseActionButton(
                label: 'شراء الكود المصدري',
                icon: Icons.shopping_bag_outlined,
                onPressed: () => _showPurchaseContactDialog(context),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => ProjectChatScreen(
                        projectId: projectId,
                        projectTitle: title,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBFDBFE),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: const Text(
                    'استفسار / محادثة',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF26364F), height: 1),
              const SizedBox(height: 14),
              const _PurchasePerk(
                icon: Icons.verified_user_outlined,
                label: 'مراجعة آمنة لعملية الشراء',
              ),
              const SizedBox(height: 10),
              const _PurchasePerk(
                icon: Icons.code_rounded,
                label: 'كود المشروع والتقنيات موضحة',
              ),
              if (isEscrow) ...[
                const SizedBox(height: 10),
                const _PurchasePerk(
                  icon: Icons.shield_outlined,
                  label: 'حماية الدفع عبر المنصة',
                ),
              ],
            ],
          ),
        )
        .animate(delay: 130.ms)
        .fadeIn(duration: 360.ms)
        .slideY(begin: 0.035, end: 0);
  }
}

class _ProjectRatingSection extends StatefulWidget {
  const _ProjectRatingSection({required this.projectId});

  final String projectId;

  @override
  State<_ProjectRatingSection> createState() => _ProjectRatingSectionState();
}

class _ProjectRatingSectionState extends State<_ProjectRatingSection> {
  int _selectedRating = 0;
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول لتقييم المشروع.')),
      );
      return;
    }
    if (_selectedRating == 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<ProjectRepository>().submitRating(
        projectId: widget.projectId,
        userId: user.uid,
        rating: _selectedRating,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شكراً لك، تم تسجيل تقييمك.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر إرسال التقييم: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final repository = context.read<ProjectRepository>();

    return StreamBuilder<Project?>(
      stream: repository.watchProject(widget.projectId),
      builder: (context, projectSnapshot) {
        final project = projectSnapshot.data;
        final average = project?.averageRating ?? 0;
        final count = project?.ratingCount ?? 0;

        if (user == null) {
          return _buildRatingCard(
            average: average,
            count: count,
            alreadyRated: false,
            canRate: false,
          );
        }

        return StreamBuilder<bool>(
          stream: repository.watchHasRated(widget.projectId, user.uid),
          builder: (context, ratingSnapshot) => _buildRatingCard(
            average: average,
            count: count,
            alreadyRated: ratingSnapshot.data ?? false,
            canRate:
                project?.status == 'approved' &&
                project?.developerId != user.uid,
          ),
        );
      },
    );
  }

  Widget _buildRatingCard({
    required double average,
    required int count,
    required bool alreadyRated,
    required bool canRate,
  }) {
    return GlassPanel(
      borderRadius: 20,
      color: const Color(0xFF111B2D),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تقييم المشروع',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
              const SizedBox(width: 5),
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($count تقييم)',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                tooltip: '${index + 1} نجوم',
                onPressed: !canRate || alreadyRated || _isSubmitting
                    ? null
                    : () => setState(() => _selectedRating = index + 1),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  index < _selectedRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFFBBF24),
                  size: 29,
                ),
              ),
            ),
          ),
          if (alreadyRated)
            const Text(
              'شكراً لك، لقد قيّمت هذا المشروع بالفعل.',
              style: TextStyle(color: Color(0xFF34D399), fontSize: 12),
            )
          else if (canRate)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _selectedRating == 0 || _isSubmitting
                    ? null
                    : _submitRating,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBFDBFE),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إرسال التقييم'),
              ),
            )
          else
            const Text(
              'سجّل الدخول لتقييم هذا المشروع.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xD9080D19),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnologyChip extends StatelessWidget {
  const _TechnologyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10213A),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFBFDBFE),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PurchasePerk extends StatelessWidget {
  const _PurchasePerk({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF34D399)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _DemoLink extends StatefulWidget {
  const _DemoLink({required this.link, required this.onTap});

  final String link;
  final VoidCallback onTap;

  @override
  State<_DemoLink> createState() => _DemoLinkState();
}

class _DemoLinkState extends State<_DemoLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: kIsWeb ? (_) => setState(() => _isHovered = true) : null,
      onExit: kIsWeb ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF122644) : const Color(0xFF101A2B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF3B82F6)
                : const Color(0xFF26364F),
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: Color(0xFF60A5FA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFBFDBFE),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  color: Color(0xFF60A5FA),
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseActionButton extends StatefulWidget {
  const _PurchaseActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_PurchaseActionButton> createState() => _PurchaseActionButtonState();
}

class _PurchaseActionButtonState extends State<_PurchaseActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: kIsWeb ? (_) => setState(() => _isHovered = true) : null,
      onExit: kIsWeb ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF2563EB,
              ).withValues(alpha: _isHovered ? 0.4 : 0.2),
              blurRadius: _isHovered ? 24 : 14,
              spreadRadius: _isHovered ? 1 : 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [Color(0xFF2563EB), Color(0xFF4F8DFD)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 19),
                  const SizedBox(width: 9),
                  Text(
                    widget.label,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

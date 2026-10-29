import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../repositories/project_repository.dart';
import '../repositories/user_repository.dart';
import '../widgets/glass_panel.dart';
import '../widgets/project_card.dart';

class DeveloperPublicProfileScreen extends StatelessWidget {
  const DeveloperPublicProfileScreen({
    required this.developerUid,
    this.initialDeveloperName = '',
    super.key,
  });

  final String developerUid;
  final String initialDeveloperName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        title: const Text('ملف المطور'),
        backgroundColor: const Color(0xFF080D19),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: context.read<UserRepository>().watchPublicDeveloperProfile(
          developerUid,
        ),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return _ProfileMessage(
              message: 'تعذر تحميل بيانات المطور: ${userSnapshot.error}',
              icon: Icons.error_outline,
            );
          }
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data ?? <String, dynamic>{};

          final name =
              (userData['name'] ??
                      (initialDeveloperName.isEmpty
                          ? 'مطور'
                          : initialDeveloperName))
                  .toString();
          final bio = (userData['bio'] ?? '').toString().trim();
          final photoUrl =
              (userData['photoUrl'] ??
                      userData['photoURL'] ??
                      userData['avatarUrl'] ??
                      '')
                  .toString()
                  .trim();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: GlassPanel(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        color: const Color(0xFF111B2D),
                        hoverable: true,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: const Color(0xFF1E3A5F),
                              foregroundImage: photoUrl.isEmpty
                                  ? null
                                  : NetworkImage(photoUrl),
                              child: photoUrl.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFFBFDBFE),
                                      size: 42,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  StreamBuilder<List<Project>>(
                                    stream: context
                                        .read<ProjectRepository>()
                                        .watchDeveloperApprovedProjects(
                                          developerUid,
                                        ),
                                    builder: (context, ratingSnapshot) {
                                      var totalRating = 0.0;
                                      var ratingCount = 0;
                                      for (final project
                                          in ratingSnapshot.data ??
                                              const <Project>[]) {
                                        final count = project.ratingCount;
                                        final average = project.averageRating;
                                        final weight = count > 0 ? count : 1;
                                        final total =
                                            count > 0 && project.totalRating > 0
                                            ? project.totalRating.toDouble()
                                            : average * weight;
                                        totalRating += total;
                                        ratingCount += weight;
                                      }
                                      final rating = ratingCount == 0
                                          ? 0.0
                                          : totalRating / ratingCount;
                                      return Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFBBF24),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            ratingSnapshot.hasError
                                                ? '—'
                                                : rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Color(0xFFE2E8F0),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'التقييم العام',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  if (bio.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      bio,
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        height: 1.7,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.grid_view_rounded,
                            color: Color(0xFF60A5FA),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'مشاريع $name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: StreamBuilder<List<Project>>(
                        stream: context
                            .read<ProjectRepository>()
                            .watchDeveloperApprovedProjects(developerUid),
                        builder: (context, projectSnapshot) {
                          if (projectSnapshot.hasError) {
                            return _ProfileMessage(
                              message:
                                  'تعذر تحميل مشاريع المطور: ${projectSnapshot.error}',
                              icon: Icons.error_outline,
                            );
                          }
                          if (!projectSnapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final approvedProjects = projectSnapshot.data!;
                          if (approvedProjects.isEmpty) {
                            return const _ProfileMessage(
                              message:
                                  'لا توجد مشاريع منشورة لهذا المطور حالياً.',
                              icon: Icons.inventory_2_outlined,
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = kIsWeb
                                  ? (constraints.maxWidth / 300).floor().clamp(
                                      1,
                                      4,
                                    )
                                  : constraints.maxWidth >= 700
                                  ? 2
                                  : 1;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: approvedProjects.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      mainAxisExtent: 430,
                                    ),
                                itemBuilder: (context, index) {
                                  final project = approvedProjects[index];
                                  return ProjectCard(
                                    projectId: project.id,
                                    developerUid: developerUid,
                                    projectType: project.projectType,
                                    title: project.title,
                                    developerName: project.developerName.isEmpty
                                        ? name
                                        : project.developerName,
                                    price: project.price,
                                    techStack: project.techStack,
                                    rating: project.averageRating,
                                    ratingCount: project.ratingCount,
                                    views: project.views,
                                    imageUrl: project.imageUrl,
                                    isEscrow: project.isEscrow,
                                    description: project.description,
                                    demoLink: project.demoLink,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(28),
      color: const Color(0xFF111B2D),
      hoverable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: const Color(0xFF60A5FA)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.6),
          ),
        ],
      ),
    );
  }
}

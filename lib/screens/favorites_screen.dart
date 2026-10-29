import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_project.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/EmptyStateWidget.dart';
import '../widgets/project_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({required this.onBrowseProjects, super.key});

  final VoidCallback onBrowseProjects;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    if (auth.isLoading || favoritesProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF080D19),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (auth.currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF080D19),
        body: Center(
          child: Text(
            'سجّل الدخول لعرض مشاريعك المفضلة.',
            style: TextStyle(color: Color(0xFFCBD5E1)),
          ),
        ),
      );
    }
    if (favoritesProvider.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF080D19),
        body: Center(
          child: Text(
            'تعذر تحميل المفضلة: ${favoritesProvider.error}',
            style: const TextStyle(color: Color(0xFFEF4444)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final favorites = favoritesProvider.favorites;

    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        title: const Text(
          'المفضلة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF080D19),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? EmptyStateWidget(
              lottiePath:
                  'https://assets9.lottiefiles.com/packages/lf20_0yfsb3a1.json',
              title: 'لا توجد مشاريع في المفضلة',
              subtitle: 'أضف المشاريع التي أعجبتك لتجدها هنا لاحقاً.',
              actionLabel: 'تصفح المشاريع الآن',
              onActionPressed: onBrowseProjects,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = kIsWeb && constraints.maxWidth >= 760;
                if (!isWide) {
                  return ListView.separated(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: favorites.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) => SizedBox(
                      height: 420,
                      child: _favoriteCard(favorites[index]),
                    ),
                  );
                }

                final columns = (constraints.maxWidth / 330).floor().clamp(
                  2,
                  5,
                );
                return GridView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  itemCount: favorites.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    mainAxisExtent: 430,
                  ),
                  itemBuilder: (context, index) =>
                      _favoriteCard(favorites[index]),
                );
              },
            ),
    );
  }

  Widget _favoriteCard(FavoriteProject favorite) {
    return ProjectCard(
      projectId: favorite.projectId,
      developerUid: favorite.developerUid,
      projectType: favorite.projectType,
      title: favorite.title,
      developerName: favorite.developerName,
      price: favorite.price,
      techStack: favorite.techStack,
      rating: favorite.averageRating,
      ratingCount: favorite.ratingCount,
      views: favorite.views,
      imageUrl: favorite.imageUrl,
      isEscrow: favorite.isEscrow,
      description: favorite.description,
      demoLink: favorite.demoLink,
    );
  }
}

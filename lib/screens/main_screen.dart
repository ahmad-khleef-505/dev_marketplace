import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'developer_dashboard.dart';
import 'favorites_screen.dart';
import 'marketplace_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import '../widgets/glass_panel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser != null,
    );
    final isDeveloper = context.select<UserProvider, bool>(
      (provider) =>
          provider.userData?['role'] == 'developer' ||
          provider.userData?['userType'] == 'developer',
    );
    if (!isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول للمتابعة.')),
      );
    }

    final destinations = <_MainDestination>[
      _MainDestination(
        label: 'الرئيسية',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        screen: const MarketplaceScreen(),
      ),
      if (isDeveloper)
        _MainDestination(
          label: 'إضافة مشروع',
          icon: Icons.add_box_outlined,
          selectedIcon: Icons.add_box,
          screen: const DeveloperDashboard(),
        ),
      _MainDestination(
        label: 'المفضلة',
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        screen: FavoritesScreen(
          onBrowseProjects: () => setState(() => _currentIndex = 0),
        ),
      ),
      _MainDestination(
        label: 'الرسائل',
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        screen: MessagesScreen(
          onBrowseProjects: () => setState(() => _currentIndex = 0),
        ),
      ),
      _MainDestination(
        label: 'حسابي',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        screen: const ProfileScreen(),
      ),
    ];
    final selectedIndex = _currentIndex.clamp(0, destinations.length - 1);
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;

    final content = KeyedSubtree(
      key: ValueKey(selectedIndex),
      child: destinations[selectedIndex].screen,
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: isDesktopWeb
          ? AppBar(
              titleSpacing: 28,
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'DevMarketplace',
                    style: GoogleFonts.cairo(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    height: 22,
                    width: 1,
                    color: const Color(0xFF334155),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    'منتجات رقمية مختارة بعناية',
                    style: GoogleFonts.cairo(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: const [
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 26),
                  child: Center(child: _SecureMarketBadge()),
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 80, child: _AmbientGlow()),
          Column(
            children: [
              _buildWelcomeBanner(isDesktopWeb: isDesktopWeb),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(
                        Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    ),
                  ),
                  child: content,
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RepaintBoundary(
                    child: _FloatingNavigationBar(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onSelected: (index) =>
                          setState(() => _currentIndex = index),
                      isDesktop: isDesktopWeb,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner({required bool isDesktopWeb}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            isDesktopWeb ? 28 : 16,
            10,
            isDesktopWeb ? 28 : 16,
            8,
          ),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            borderRadius: 18,
            color: const Color(0xFF10213A),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بك في سوق المبرمجين',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: isDesktopWeb ? 18 : 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'مدير التطبيق ومبرمجه : أحمد الخليف',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF93C5FD),
                          fontSize: isDesktopWeb ? 12 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainDestination {
  const _MainDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.isDesktop,
  });

  final List<_MainDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isDesktop ? 760 : width - 28),
      child: GlassPanel(
        borderRadius: 28,
        color: const Color(0xFF101A2D),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: _FloatingNavigationItem(
                  destination: destinations[index],
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                  compact: width < 430,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavigationItem extends StatefulWidget {
  const _FloatingNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final _MainDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_FloatingNavigationItem> createState() =>
      _FloatingNavigationItemState();
}

class _FloatingNavigationItemState extends State<_FloatingNavigationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.selected || (kIsWeb && _isHovered);
    return MouseRegion(
      onEnter: kIsWeb ? (_) => setState(() => _isHovered = true) : null,
      onExit: kIsWeb ? (_) => setState(() => _isHovered = false) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 4 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: widget.selected
                    ? const Color(0xFF2563EB).withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF3B82F6,
                          ).withValues(alpha: 0.26),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isHighlighted ? 1.08 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      widget.selected
                          ? widget.destination.selectedIcon
                          : widget.destination.icon,
                      size: 21,
                      color: isHighlighted
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.destination.label,
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.cairo(
                        color: isHighlighted
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFF94A3B8),
                        fontSize: widget.compact ? 10 : 11,
                        fontWeight:
                            widget.selected ? FontWeight.w700 : FontWeight.w500,
                      ),
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

class _SecureMarketBadge extends StatelessWidget {
  const _SecureMarketBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2F),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF34D399),
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            'سوق آمن للمشاريع',
            style: GoogleFonts.cairo(
              color: const Color(0xFFCBD5E1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 440,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF2563EB).withValues(alpha: 0.12),
              const Color(0xFF2563EB).withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

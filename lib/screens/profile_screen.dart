import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'admin_panel_screen.dart';
import 'legal_screen.dart';
import 'onboarding_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';
import '../widgets/glass_panel.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await context.read<UserProvider>().signOut();
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تسجيل الخروج: ${error.message ?? error.code}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تسجيل الخروج: $error'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تعديل كلمة المرور',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال كلمة المرور';
              }
              if (value.length < 6) {
                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await context.read<AuthProvider>().updatePassword(
                  passwordController.text.trim(),
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تعديل كلمة المرور بنجاح!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              } on FirebaseAuthException catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.code == 'requires-recent-login'
                            ? 'لأسباب أمنية، يرجى تسجيل الخروج والدخول مرة أخرى ثم المحاولة.'
                            : 'تعذر تعديل كلمة المرور: ${error.message ?? error.code}',
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ التعديل'),
          ),
        ],
      ),
    ).whenComplete(passwordController.dispose);
  }

  String _roleLabel(Map<String, dynamic> data) {
    final userType = data['userType']?.toString();
    return switch (userType) {
      'superAdmin' => 'سوبر أدمن',
      'admin' => 'مدير',
      'agent' => 'وكيل',
      'client' => 'عميل',
      _ => data['role'] == 'developer' ? 'مطور' : 'عميل',
    };
  }

  String _orderStatusLabel(String status) {
    return switch (status) {
      'pending_payment' => 'بانتظار الدفع',
      'pending_admin_review' => 'قيد مراجعة الإدارة',
      'approved' => 'مكتمل',
      'rejected' => 'مرفوض',
      _ => status,
    };
  }

  Color _orderStatusColor(String status) {
    return switch (status) {
      'approved' => const Color(0xFF10B981),
      'rejected' => const Color(0xFFEF4444),
      'pending_admin_review' => const Color(0xFFF59E0B),
      _ => const Color(0xFF60A5FA),
    };
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 20),
      borderRadius: 18,
      padding: const EdgeInsets.all(20),
      hoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xFF60A5FA), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.025, end: 0);
  }

  Widget _buildPurchaseHistory(BuildContext context, String uid) {
    return RepaintBoundary(
      child: _PurchaseHistory(
        uid: uid,
        repository: context.read<PurchaseOrderRepository>(),
        buildOrderTile: _buildOrderTile,
      ),
    );
  }

  Widget _buildOrderTile(PurchaseOrder order) {
    final status = order.status;
    final amount = order.amount;
    final date = order.createdAt;
    final dateLabel = date == null
        ? 'التاريخ غير متوفر'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: Color(0xFF60A5FA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.projectTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    amount == null
                        ? dateLabel
                        : '${amount.toStringAsFixed(2)} ${order.currency} · $dateLabel',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _orderStatusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _orderStatusLabel(status),
                      style: TextStyle(
                        color: _orderStatusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (status == 'rejected' &&
                  (order.reviewReason?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 6),
                Text(
                  'سبب الرفض: ${order.reviewReason}',
                  style: const TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: user == null
                ? const Center(
                    child: Text(
                      'يرجى تسجيل الدخول لعرض الملف الشخصي.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : Selector<
                    UserProvider,
                    (bool, Object?, Map<String, dynamic>?)
                  >(
                    selector: (context, userProvider) => (
                      userProvider.isLoading,
                      userProvider.error,
                      userProvider.userData,
                    ),
                    builder: (context, userState, _) {
                      final (isLoading, error, userData) = userState;
                      if (isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3B82F6),
                          ),
                        );
                      }
                      if (error != null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'تعذر تحميل بيانات الحساب: $error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ),
                        );
                      }
                      if (userData == null) {
                        return const Center(
                          child: Text(
                            'لم يتم العثور على بيانات الحساب.',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        );
                      }

                      final name = userData['name']?.toString() ?? 'بدون اسم';
                      final email = user.email ?? 'غير مسجل';
                      final phone = userData['phone']?.toString() ?? 'غير مسجل';

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                            children: [
                              _sectionCard(
                                icon: Icons.badge_outlined,
                                title: 'البيانات الأساسية',
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF3B82F6),
                                          width: 2,
                                        ),
                                      ),
                                      child: const CircleAvatar(
                                        radius: 32,
                                        backgroundColor: Color(0xFF0F172A),
                                        child: Icon(
                                          Icons.person_outline,
                                          size: 34,
                                          color: Color(0xFF93C5FD),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          _infoLine(
                                            Icons.email_outlined,
                                            email,
                                          ),
                                          const SizedBox(height: 7),
                                          _infoLine(
                                            Icons.phone_outlined,
                                            phone,
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF3B82F6,
                                              ).withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF3B82F6,
                                                ).withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Text(
                                              _roleLabel(userData),
                                              style: const TextStyle(
                                                color: Color(0xFF60A5FA),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _sectionCard(
                                icon: Icons.tune_rounded,
                                title: 'الإعدادات',
                                child: Column(
                                  children: [
                                    Consumer<ThemeProvider>(
                                      builder:
                                          (
                                            context,
                                            themeProvider,
                                            child,
                                          ) => SwitchListTile.adaptive(
                                            contentPadding: EdgeInsets.zero,
                                            secondary: Icon(
                                              themeProvider.isDarkMode
                                                  ? Icons.dark_mode_rounded
                                                  : Icons.light_mode_rounded,
                                              color: const Color(0xFF60A5FA),
                                            ),
                                            title: const Text(
                                              'الوضع الليلي',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              themeProvider.isDarkMode
                                                  ? 'المظهر الداكن مفعّل'
                                                  : 'المظهر الفاتح مفعّل',
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                            value: themeProvider.isDarkMode,
                                            activeThumbColor: const Color(
                                              0xFF60A5FA,
                                            ),
                                            onChanged: (enabled) async {
                                              try {
                                                await themeProvider
                                                    .setThemeMode(
                                                      enabled
                                                          ? ThemeMode.dark
                                                          : ThemeMode.light,
                                                    );
                                              } catch (error) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'تعذر حفظ إعداد المظهر: $error',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                    ),
                                    const Divider(
                                      height: 16,
                                      color: Color(0xFF334155),
                                    ),
                                    _settingsTile(
                                      icon: Icons.lock_reset,
                                      title: 'تعديل كلمة المرور',
                                      subtitle: 'تحديث بيانات الدخول إلى حسابك',
                                      onTap: () =>
                                          _showChangePasswordDialog(context),
                                    ),
                                    const Divider(
                                      height: 16,
                                      color: Color(0xFF334155),
                                    ),
                                    _settingsTile(
                                      icon: Icons.policy_outlined,
                                      title: 'الشروط والأحكام وسياسة الخصوصية',
                                      subtitle:
                                          'عرض شروط استخدام المنصة وبيان الخصوصية',
                                      onTap: () => Navigator.push<void>(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => const LegalScreen(),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      height: 16,
                                      color: Color(0xFF334155),
                                    ),
                                    _settingsTile(
                                      icon: Icons.lightbulb_outline,
                                      title: 'اقتراح ميزات جديدة',
                                      subtitle: 'شاركنا رأيك حول تطوير المنصة',
                                      onTap: () => Navigator.push<void>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OnboardingScreen(
                                                onCompleted: () =>
                                                    Navigator.of(context).pop(),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _sectionCard(
                                icon: Icons.receipt_long_outlined,
                                title: 'سجل الطلبات والمشتريات',
                                child: _buildPurchaseHistory(context, user.uid),
                              ),
                              if (userData['userType'] == 'superAdmin')
                                _buildAdminPanelButton(context),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: RepaintBoundary(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _signOut(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanelButton(BuildContext context) {
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 20),
      borderRadius: 18,
      padding: const EdgeInsets.all(5),
      color: const Color(0xFF211A22),
      hoverable: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const AdminPanelScreen(),
            ),
          ),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFF87171),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لوحة التحكم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'إدارة المشاريع والمستخدمين',
                        style: TextStyle(
                          color: Color(0xFFB6A3A6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Color(0xFFF87171),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.025, end: 0);
  }

  Widget _infoLine(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: const Color(0xFF60A5FA)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
        onTap: onTap,
      ),
    );
  }
}

class _PurchaseHistory extends StatefulWidget {
  const _PurchaseHistory({
    required this.uid,
    required this.repository,
    required this.buildOrderTile,
  });

  final String uid;
  final PurchaseOrderRepository repository;
  final Widget Function(PurchaseOrder order) buildOrderTile;

  @override
  State<_PurchaseHistory> createState() => _PurchaseHistoryState();
}

class _PurchaseHistoryState extends State<_PurchaseHistory> {
  Stream<List<PurchaseOrder>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _scheduleOrdersLoad();
  }

  @override
  void didUpdateWidget(covariant _PurchaseHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid ||
        oldWidget.repository != widget.repository) {
      _ordersStream = null;
      _scheduleOrdersLoad();
    }
  }

  void _scheduleOrdersLoad() {
    final uid = widget.uid;
    final repository = widget.repository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || uid != widget.uid || repository != widget.repository) {
        return;
      }
      setState(() {
        _ordersStream = repository.watchClientOrders(uid);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersStream = _ordersStream;
    if (ordersStream == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return StreamBuilder<List<PurchaseOrder>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'تعذر تحميل سجل المشتريات: ${snapshot.error}',
            style: const TextStyle(color: Color(0xFFEF4444)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          );
        }

        final orders = snapshot.data ?? const <PurchaseOrder>[];
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF64748B),
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'لا توجد مشتريات حتى الآن',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) => widget.buildOrderTile(orders[index]),
          separatorBuilder: (context, index) =>
              const Divider(height: 20, color: Color(0xFF334155)),
        );
      },
    );
  }
}

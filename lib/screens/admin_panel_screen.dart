import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../repositories/admin_repository.dart';
import '../services/purchase_service.dart';
import '../widgets/glass_panel.dart';

Future<void> _openDeveloperPhone(
  BuildContext context,
  String phone, {
  required bool whatsapp,
}) async {
  final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalizedPhone.isEmpty) return;

  final uri = whatsapp
      ? Uri.https('wa.me', '/${normalizedPhone.replaceAll('+', '')}')
      : Uri(scheme: 'tel', path: normalizedPhone);
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('تعذر فتح تطبيق التواصل.');
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح تطبيق التواصل: $error')),
      );
    }
  }
}

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.security, color: Color(0xFFEF4444)),
                SizedBox(width: 10),
                Text(
                  'لوحة الإدارة (أبو أيمن)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                onPressed: () async {
                  await context.read<AuthProvider>().signOut();
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: const TabBar(
              isScrollable: true,
              indicatorColor: Color(0xFF3B82F6),
              labelColor: Color(0xFF3B82F6),
              unselectedLabelColor: Color(0xFF64748B),
              tabs: [
                Tab(text: 'قيد المراجعة'),
                Tab(text: 'مقبول'),
                Tab(text: 'مرفوض'),
                Tab(text: 'إدارة المستخدمين'),
                Tab(text: 'طلبات الشراء'),
                Tab(text: 'الإحصائيات'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _ProjectList(status: 'pending'),
              _ProjectList(status: 'approved'),
              _ProjectList(status: 'rejected'),
              _UsersList(),
              _PurchaseOrdersTab(),
              _AdminAnalyticsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAnalyticsTab extends StatefulWidget {
  const _AdminAnalyticsTab();

  @override
  State<_AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<_AdminAnalyticsTab> {
  late Future<AdminAnalyticsSummary> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = context.read<AdminRepository>().getAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminAnalyticsSummary>(
      future: _analyticsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تعذر تحميل الإحصائيات: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(
                        () => _analyticsFuture =
                            context.read<AdminRepository>().getAnalytics(),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        final analytics = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 600
                    ? 2
                    : 1;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.count(
                  padding: const EdgeInsets.all(24),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: columns == 1 ? 184 : 196,
                  children: [
                    _AnalyticsCard(
                      title: 'إجمالي المستخدمين',
                      value: analytics.usersCount.toString(),
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF60A5FA),
                    ),
                    _AnalyticsCard(
                      title: 'إجمالي المشاريع',
                      value: analytics.projectsCount.toString(),
                      icon: Icons.apps_rounded,
                      color: const Color(0xFFA78BFA),
                    ),
                    _AnalyticsCard(
                      title: 'إجمالي الطلبات والمبيعات',
                      value: analytics.ordersCount.toString(),
                      icon: Icons.shopping_bag_rounded,
                      color: const Color(0xFFFBBF24),
                    ),
                    _AnalyticsCard(
                      title: 'قيمة المشاريع المعتمدة',
                      value:
                          '\$${analytics.approvedPriceTotal.toStringAsFixed(2)}',
                      icon: Icons.attach_money_rounded,
                      color: const Color(0xFF34D399),
                      subtitle: 'مجموع أسعار المشاريع المنشورة',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 400;
    return GlassPanel(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      borderRadius: 20,
      color: const Color(0xFF111B2D),
      hoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 38 : 42,
            height: isCompact ? 38 : 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: isCompact ? 21 : 23),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.025, end: 0);
  }
}

// ------------------- قائمة المشاريع -------------------
class _ProjectList extends StatelessWidget {
  final String status;
  const _ProjectList({required this.status});

  Future<void> _updateProjectStatus(
    BuildContext context,
    String projectId,
    String newStatus,
  ) async {
    try {
      await context.read<AdminRepository>().updateProjectStatus(
            projectId,
            newStatus,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'approved'
                  ? 'تمت الموافقة على المشروع ونشره.'
                  : 'تم رفض المشروع.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث حالة المشروع: $error')),
        );
      }
    }
  }

  Future<void> _deleteProject(BuildContext context, String projectId) async {
    try {
      await context.read<AdminRepository>().deleteProject(projectId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر حذف المشروع: $error')));
      }
    }
  }

  Future<void> _editProject(
    BuildContext context,
    String projectId,
    Map<String, dynamic> data,
  ) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(
      text: data['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: data['description']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: (data['price'] ?? '').toString(),
    );
    var selectedStatus = data['status']?.toString() ?? 'pending';

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تعديل المشروع',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'عنوان المشروع',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'عنوان المشروع مطلوب'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'وصف المشروع',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'وصف المشروع مطلوب'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'السعر بالدولار',
                          prefixText: '\$ ',
                        ),
                        validator: (value) {
                          final price = double.tryParse(value?.trim() ?? '');
                          return price == null || !price.isFinite || price <= 0
                              ? 'أدخل سعراً صالحاً أكبر من صفر'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'حالة المشروع',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('قيد المراجعة'),
                          ),
                          DropdownMenuItem(
                            value: 'approved',
                            child: Text('مقبول'),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Text('مرفوض'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => selectedStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            try {
                              await context
                                  .read<AdminRepository>()
                                  .updateProjectDetails(
                                    id: projectId,
                                    title: titleController.text.trim(),
                                    description:
                                        descriptionController.text.trim(),
                                    price: double.parse(
                                      priceController.text.trim(),
                                    ),
                                    status: selectedStatus,
                                  );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم تحديث المشروع بنجاح.'),
                                  ),
                                );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تعذر تحديث المشروع: $error'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('حفظ التعديلات'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      priceController.dispose();
    }
  }

  // دالة عرض التفاصيل الكاملة (Bottom Sheet)
  void _showDetails(
    BuildContext context,
    String projectId,
    Map<String, dynamic> data,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.read<AuthProvider>().currentUser;
    final isSuperAdminFuture = user == null
        ? Future<bool>.value(false)
        : context
            .read<AdminRepository>()
            .getUser(user.uid)
            .then((userData) => userData?['userType'] == 'superAdmin');
    final developerPhoneFuture =
        context.read<AdminRepository>().getDeveloperPhone(projectId);

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHighest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Text(
                  data['title'] ?? 'بدون عنوان',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // الصورة
                if (data['imageUrl'] != null &&
                    data['imageUrl'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.black26,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // الوصف
                const Text(
                  'الوصف:',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['description'] ?? 'لا يوجد وصف.',
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // الفئة والسعر
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الفئة: ${data['category'] ?? 'غير محدد'}',
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'السعر: \$${data['price']}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF334155)),
                const SizedBox(height: 16),

                // معلومات المطور
                const Text(
                  'معلومات المطور (سرية):',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الاسم: ${data['developerName'] ?? 'مجهول'}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<String?>(
                  future: developerPhoneFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'تعذر تحميل رقم المطوّر: ${snapshot.error}',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                        ),
                      );
                    }
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    final phone = snapshot.data?.trim() ?? '';
                    return Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: phone.isEmpty
                              ? const Text(
                                  'الهاتف: غير متوفر',
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : TextButton.icon(
                                  onPressed: () => _openDeveloperPhone(
                                    context,
                                    phone,
                                    whatsapp: false,
                                  ),
                                  icon: const Icon(Icons.call, size: 18),
                                  label: Text('الهاتف: $phone'),
                                ),
                        ),
                      ],
                    );
                  },
                ),
                FutureBuilder<bool>(
                  future: isSuperAdminFuture,
                  builder: (context, adminSnapshot) {
                    if (adminSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'تعذر التحقق من صلاحية الإدارة: ${adminSnapshot.error}',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    if (adminSnapshot.data != true) {
                      return const SizedBox.shrink();
                    }

                    return FutureBuilder<String?>(
                      future: developerPhoneFuture,
                      builder: (context, phoneSnapshot) {
                        if (phoneSnapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'تعذر تحميل رقم المطور: ${phoneSnapshot.error}',
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        final phone = phoneSnapshot.data?.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        if (phone == null || phone.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'لا يتوفر رقم واتساب للمطور.',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _contactDeveloperOnWhatsApp(
                                context,
                                phone: phone,
                                projectTitle:
                                    data['title']?.toString() ?? 'بدون عنوان',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text(
                                'التواصل مع المطور عبر واتساب',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // رابط المعاينة
                if (data['demoLink'] != null &&
                    data['demoLink'].toString().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'رابط المعاينة:',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['demoLink'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _contactDeveloperOnWhatsApp(
    BuildContext context, {
    required String phone,
    required String projectTitle,
  }) async {
    final message = [
      'مرحباً، معك مدير تطبيق سوق المبرمجين.',
      'أريد الاستفسار عن المشروع الذي عارضته على التطبيق:',
      '- اسم المشروع: $projectTitle',
    ].join('\n');
    final uri = Uri.https('wa.me', '/$phone', {'text': message});

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('تعذر فتح واتساب.');
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر فتح واتساب: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: context.read<AdminRepository>().watchProjects(status),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('حدث خطأ', style: TextStyle(color: Colors.red)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        final projects = snapshot.data!.docs;
        if (projects.isEmpty) {
          return Center(
            child: Text(
              'لا توجد مشاريع $status',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            final data = project.data();
            final price = (data['price'] ?? 0.0).toDouble();
            final commission = price * 0.10;

            return GlassPanel(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              hoverable: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الصف الأول: الصورة والاسم والهاتف
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['imageUrl'] ?? '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.black26,
                            child: const Icon(
                              Icons.image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'بدون عنوان',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'المطور: ${data['developerName'] ?? 'مجهول'}',
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'الهاتف: بيانات خاصة',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // زر الحذف
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xFFEF4444),
                        ),
                        onPressed: () {
                          _deleteProject(context, project.id);
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 24),

                  // الصف الثاني: السعر والعمولة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'السعر: \$${price.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'العمولة: \$${commission.toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // زر عرض التفاصيل
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showDetails(context, project.id, data),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('التفاصيل'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            side: const BorderSide(
                              color: Color(0xFF3B82F6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _editProject(context, project.id, data),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('تعديل المشروع'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF59E0B),
                            side: const BorderSide(
                              color: Color(0xFFF59E0B),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // أزرار الموافقة والرفض (تظهر فقط للمعلقة)
                  if (status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateProjectStatus(
                              context,
                              project.id,
                              'rejected',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            child: const Text('رفض'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateProjectStatus(
                              context,
                              project.id,
                              'approved',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                            ),
                            child: const Text('قبول'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: index * 25))
                .fadeIn(duration: 240.ms)
                .slideY(begin: 0.025, end: 0);
          },
        );
      },
    );
  }
}

// ------------------- قائمة المستخدمين -------------------
class _UsersList extends StatelessWidget {
  const _UsersList();

  Future<void> _deleteUser(BuildContext context, String userId) async {
    try {
      await context.read<AdminRepository>().deleteUser(userId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر حذف المستخدم: $error')));
      }
    }
  }

  Future<void> _changeUserType(
    BuildContext context,
    String userId,
    String userName,
    String newUserType,
  ) async {
    final adminRepository = context.read<AdminRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(
          dialogContext,
        ).colorScheme.surfaceContainerHighest,
        title: const Text('تأكيد تغيير الرتبة'),
        content: Text('هل تريد تغيير رتبة "$userName" إلى $newUserType؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await adminRepository.updateUserType(userId, newUserType);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث رتبة المستخدم.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تغيير رتبة المستخدم: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: context.read<AdminRepository>().watchUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'تعذر تحميل المستخدمين: ${snapshot.error}',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'لا يوجد مستخدمين',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data();
            final rawUserType = data['userType']?.toString();
            final role = rawUserType ??
                (data['role'] == 'developer' ? 'agent' : 'client');
            final isSuperAdminUser = role == 'superAdmin';
            final isDeveloper = data['role'] == 'developer' || role == 'agent';
            final userName = data['name']?.toString() ?? 'بدون اسم';

            return GlassPanel(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: 12,
              hoverable: true,
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      tileColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isDeveloper
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                        child: Icon(
                          isDeveloper ? Icons.code : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        data['email']?.toString() ?? 'بدون ايميل',
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      0,
                      16,
                      8,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'رتبة المستخدم',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: const [
                              'client',
                              'agent',
                              'admin',
                            ].contains(role)
                                ? role
                                : null,
                            hint: Text(
                              role == 'superAdmin' ? 'superAdmin' : role,
                              style: const TextStyle(color: Colors.white),
                            ),
                            isExpanded: true,
                            dropdownColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            items: const [
                              DropdownMenuItem(
                                value: 'client',
                                child: Text('عميل (client)'),
                              ),
                              DropdownMenuItem(
                                value: 'agent',
                                child: Text('وكيل (agent)'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('مدير (admin)'),
                              ),
                            ],
                            onChanged: isSuperAdminUser
                                ? null
                                : (newUserType) {
                                    if (newUserType != null &&
                                        newUserType != role) {
                                      _changeUserType(
                                        context,
                                        user.id,
                                        userName,
                                        newUserType,
                                      );
                                    }
                                  },
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف المستخدم',
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Color(0xFFEF4444),
                          ),
                          onPressed: isSuperAdminUser
                              ? null
                              : () => _deleteUser(context, user.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: index * 20))
                .fadeIn(duration: 220.ms)
                .slideY(begin: 0.02, end: 0);
          },
        );
      },
    );
  }
}

class _PurchaseOrdersTab extends StatefulWidget {
  const _PurchaseOrdersTab();

  @override
  State<_PurchaseOrdersTab> createState() => _PurchaseOrdersTabState();
}

class _PurchaseOrdersTabState extends State<_PurchaseOrdersTab> {
  final PurchaseService _purchaseService = PurchaseService();
  final Map<String, Future<String?>> _developerPhoneFutures = {};
  String? _processingOrderId;

  Future<String?> _getDeveloperPhone(String projectId) =>
      _developerPhoneFutures.putIfAbsent(
        projectId,
        () => context.read<AdminRepository>().getDeveloperPhone(projectId),
      );

  Future<void> _approveOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: const Text('تأكيد قبول الطلب'),
        content: const Text(
          'هل تحققت يدويًا من صورة إشعار واتساب ومن استلام المبلغ في شام كاش؟ لا توافق قبل التحقق من الأمرين.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد القبول'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _reviewOrder(orderId: orderId, decision: 'approve');
  }

  Future<void> _rejectOrder(String orderId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: const Text('رفض طلب الشراء'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'سبب الرفض'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('رفض الطلب'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) {
      return;
    }
    await _reviewOrder(orderId: orderId, decision: 'reject', reason: reason);
  }

  Future<void> _reviewOrder({
    required String orderId,
    required String decision,
    String reason = '',
  }) async {
    setState(() => _processingOrderId = orderId);
    try {
      final contactAvailable = await _purchaseService.reviewOrder(
        orderId: orderId,
        decision: decision,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'approve'
                  ? contactAvailable
                      ? 'تم قبول الطلب بعد المراجعة.'
                      : 'تم قبول الطلب، لكن رقم المطوّر غير متوفر حالياً.'
                  : 'تم رفض الطلب وتسجيل السبب.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر مراجعة الطلب: $error'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _purchaseService.pendingPurchaseOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'تعذر تحميل الطلبات المنتظرة.',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }
        final orders = snapshot.data?.docs ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد طلبات بانتظار المراجعة.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data();
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            final clientUid = data['clientUid']?.toString() ?? '';
            final projectId = data['projectId']?.toString() ?? '';
            final isProcessing = _processingOrderId == order.id;
            return GlassPanel(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              hoverable: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    data['projectTitle']?.toString() ?? 'مشروع',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'المبلغ: ${amount.toStringAsFixed(2)} ${data['currency'] ?? ''}',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'العميل: ${data['clientName'] ?? data['clientUid'] ?? 'غير معروف'}',
                    style: const TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                  if (clientUid.isNotEmpty)
                    FutureBuilder<Map<String, dynamic>?>(
                      future: context.read<AdminRepository>().getUser(
                            clientUid,
                          ),
                      builder: (context, snapshot) {
                        final phone = snapshot.data?['phone']?.toString();
                        return Text(
                          'هاتف العميل: ${phone?.isNotEmpty == true ? phone : 'غير متوفر'}',
                          style: const TextStyle(color: Color(0xFFCBD5E1)),
                        );
                      },
                    ),
                  if (projectId.isNotEmpty)
                    FutureBuilder<String?>(
                      future: _getDeveloperPhone(projectId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'تعذر تحميل رقم المطوّر: ${snapshot.error}',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                            ),
                          );
                        }
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('جارٍ تحميل رقم المطوّر...'),
                            ],
                          );
                        }

                        final phone = snapshot.data?.trim() ?? '';
                        if (phone.isEmpty) {
                          return const Text(
                            'هاتف المطوّر: غير متوفر',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                            ),
                          );
                        }
                        return Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'هاتف المطوّر: $phone',
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            IconButton(
                              tooltip: 'اتصال بالمطوّر',
                              onPressed: () => _openDeveloperPhone(
                                context,
                                phone,
                                whatsapp: false,
                              ),
                              icon: const Icon(Icons.call),
                            ),
                            IconButton(
                              tooltip: 'واتساب المطوّر',
                              onPressed: () => _openDeveloperPhone(
                                context,
                                phone,
                                whatsapp: true,
                              ),
                              icon: const Icon(Icons.chat),
                            ),
                          ],
                        );
                      },
                    ),
                  Text(
                    'معرّف الطلب: ${order.id}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  if (data['transferNoticeSubmittedAt'] is Timestamp)
                    Text(
                      'وصل الإشعار: ${(data['transferNoticeSubmittedAt'] as Timestamp).toDate().toLocal()}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'تحقق من إشعار واتساب واستلام المبلغ يدويًا قبل القبول.',
                    style: TextStyle(color: Color(0xFFFBBF24), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  if (isProcessing)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _approveOrder(order.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('قبول بعد التحقق'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _rejectOrder(order.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('رفض وذكر السبب'),
                        ),
                      ],
                    ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: index * 25))
                .fadeIn(duration: 220.ms)
                .slideY(begin: 0.02, end: 0);
          },
        );
      },
    );
  }
}

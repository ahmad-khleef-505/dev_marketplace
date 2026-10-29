import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../repositories/project_repository.dart';
import '../repositories/user_repository.dart';

class DeveloperDashboard extends StatefulWidget {
  const DeveloperDashboard({super.key});

  @override
  State<DeveloperDashboard> createState() => _DeveloperDashboardState();
}

class _DeveloperDashboardState extends State<DeveloperDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _languageController = TextEditingController();
  final _techStackController = TextEditingController(text: 'Flutter, Firebase');
  final _priceController = TextEditingController();
  final _demoLinkController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _phoneController = TextEditingController(); // حقل رقم المطور

  String _selectedCategory = 'تطبيق جوال';
  String _projectType = 'app';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _languageController.dispose();
    _techStackController.dispose();
    _priceController.dispose();
    _demoLinkController.dispose();
    _imageUrlController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _uploadProject() async {
    if (!_formKey.currentState!.validate()) return;

    final userRepository = context.read<UserRepository>();
    final projectRepository = context.read<ProjectRepository>();
    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) throw StateError('يجب تسجيل الدخول قبل نشر مشروع.');
      final userData = await userRepository.getUserProfile(user.uid);
      if (!mounted) return;
      final developerName =
          userData?['name']?.toString() ??
          user.email?.split('@').first ??
          'مطور مجهول';
      final normalizedDemoLink = _demoLinkController.text.trim();
      await projectRepository.addProject(
        project: Project(
          id: '',
          developerId: user.uid,
          developerName: developerName,
          projectType: _projectType,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          language: _languageController.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceController.text.trim()),
          demoLink:
              normalizedDemoLink.isNotEmpty &&
                  !normalizedDemoLink.startsWith('http')
              ? 'https://$normalizedDemoLink'
              : normalizedDemoLink,
          imageUrl: _imageUrlController.text.trim(),
          techStack: _techStackController.text
              .split(',')
              .map((technology) => technology.trim())
              .where((technology) => technology.isNotEmpty)
              .toList(),
          averageRating: 5,
          ratingCount: 0,
          totalRating: 0,
          isEscrow: true,
          status: 'pending',
          views: 0,
        ),
        developerPhone: _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع المشروع بنجاح! (قيد المراجعة)'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        // تفريغ الحقول بعد النجاح
        _titleController.clear();
        _descController.clear();
        _languageController.clear();
        _techStackController.clear();
        _priceController.clear();
        _demoLinkController.clear();
        _imageUrlController.clear();
        _phoneController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'إضافة مشروع جديد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      controller: _imageUrlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'رابط صورة المشروع',
                        hintText: 'https://example.com/image.jpg',
                        prefixIcon: Icon(
                          Icons.image_outlined,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      validator: (value) {
                        final uri = Uri.tryParse(value?.trim() ?? '');
                        if (uri == null ||
                            uri.scheme != 'https' ||
                            uri.host.isEmpty) {
                          return 'أدخل رابط صورة صالحاً يبدأ بـ https';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // حقل عنوان المشروع
                    TextFormField(
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان المشروع',
                        helperText: 'اكتب اسماً جذاباً وواضحاً للمشروع',
                        prefixIcon: Icon(Icons.title, color: Color(0xFF3B82F6)),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 16),

                    // حقل الوصف
                    TextFormField(
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'وصف المشروع',
                        helperText:
                            'اشرح مميزات المشروع والتقنيات التي يستخدمها',
                        prefixIcon: Icon(
                          Icons.description,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      controller: _languageController,
                      decoration: const InputDecoration(
                        labelText: 'لغة البرمجة',
                        hintText: 'مثال: Dart أو JavaScript',
                        prefixIcon: Icon(Icons.code, color: Color(0xFF3B82F6)),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'يرجى إدخال لغة البرمجة'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      controller: _techStackController,
                      decoration: const InputDecoration(
                        labelText: 'التقنيات المستخدمة',
                        hintText:
                            'افصل التقنيات بفواصل، مثال: Flutter, Firebase',
                        prefixIcon: Icon(
                          Icons.developer_board,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'يرجى إدخال تقنية واحدة على الأقل'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // حقل رقم المطور
                    TextFormField(
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم هاتف المطور',
                        helperText:
                            'لن يظهر للعملاء، مخصص للتواصل من قبل الإدارة فقط',
                        prefixIcon: Icon(Icons.phone, color: Color(0xFF3B82F6)),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _projectType,
                      decoration: const InputDecoration(
                        labelText: 'نوع المشروع',
                        prefixIcon: Icon(
                          Icons.devices,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      dropdownColor: const Color(0xFF1E293B),
                      items: const [
                        DropdownMenuItem(
                          value: 'app',
                          child: Text('تطبيق (App)'),
                        ),
                        DropdownMenuItem(
                          value: 'website',
                          child: Text('موقع (Website)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _projectType = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // الفئة والسعر
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'فئة المشروع',
                              prefixIcon: Icon(
                                Icons.category,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            dropdownColor: const Color(0xFF1E293B),
                            items:
                                [
                                  'تطبيق جوال',
                                  'موقع ويب',
                                  'تصميم واجهات',
                                  'خادم/API',
                                ].map((String category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                            onChanged: (newValue) =>
                                setState(() => _selectedCategory = newValue!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'السعر',
                              helperText: 'بالدولار الأمريكي',
                              prefixText: '\$ ',
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // رابط المعاينة
                    TextFormField(
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      controller: _demoLinkController,
                      decoration: const InputDecoration(
                        labelText: 'رابط تجريبي (اختياري)',
                        helperText: 'رابط لموقع أو فيديو يعرض المشروع',
                        prefixIcon: Icon(Icons.link, color: Color(0xFF3B82F6)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // زر الرفع
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _uploadProject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'نشر المشروع للمراجعة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

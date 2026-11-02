import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../repositories/project_repository.dart';
import '../repositories/user_repository.dart';
import '../widgets/app_footer.dart';

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
  final _phoneController = TextEditingController(); // حقل رقم المطور
  final _imageFieldKey = GlobalKey<FormFieldState<Uint8List>>();
  final _imagePicker = ImagePicker();

  String _selectedCategory = 'تطبيق جوال';
  String _projectType = 'app';
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _languageController.dispose();
    _techStackController.dispose();
    _priceController.dispose();
    _demoLinkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProjectImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
      _imageFieldKey.currentState?.didChange(bytes);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار الصورة: $error')),
        );
      }
    }
  }

  Future<String> _uploadProjectImage(String userId) async {
    final image = _selectedImage;
    final bytes = _selectedImageBytes;
    if (image == null || bytes == null) {
      throw StateError('يرجى اختيار صورة للمشروع.');
    }

    final mimeType = image.mimeType ?? 'image/jpeg';
    final extension = mimeType.split('/').last.replaceAll(
          RegExp(r'[^a-zA-Z0-9]'),
          '',
        );
    final reference = FirebaseStorage.instance.ref().child(
          'project_images/$userId/${DateTime.now().microsecondsSinceEpoch}.${extension.isEmpty ? 'jpg' : extension}',
        );
    await reference.putData(
      bytes,
      SettableMetadata(contentType: mimeType),
    );
    return reference.getDownloadURL();
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
          userData?['name']?.toString().trim().isNotEmpty == true
              ? userData!['name'].toString().trim()
              : user.email?.split('@').first ?? 'مطور مجهول';
      final normalizedDemoLink = _demoLinkController.text.trim();
      final imageUrl = await _uploadProjectImage(user.uid);
      if (!mounted) return;
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
          demoLink: normalizedDemoLink.isNotEmpty &&
                  !normalizedDemoLink.startsWith('http')
              ? 'https://$normalizedDemoLink'
              : normalizedDemoLink,
          imageUrl: imageUrl,
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
        _phoneController.clear();
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
        });
        _imageFieldKey.currentState?.didChange(null);
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
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final categoryField = DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'فئة المشروع',
        prefixIcon: Icon(Icons.category),
      ),
      dropdownColor: colorScheme.surfaceContainerHighest,
      items: [
        'تطبيق جوال',
        'موقع ويب',
        'تصميم واجهات',
        'خادم/API',
      ]
          .map((category) =>
              DropdownMenuItem(value: category, child: Text(category)))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) setState(() => _selectedCategory = newValue);
      },
    );
    final priceField = TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'السعر',
        helperText: 'بالدولار الأمريكي',
        prefixText: '\$ ',
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: TextInputType.number,
      validator: (value) => value!.isEmpty ? 'مطلوب' : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة مشروع جديد'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 16 : 24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FormField<Uint8List>(
                            key: _imageFieldKey,
                            validator: (value) => _selectedImageBytes == null
                                ? 'يرجى اختيار صورة للمشروع'
                                : null,
                            builder: (field) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_selectedImageBytes != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      height: isCompact ? 180 : 240,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          await _pickProjectImage();
                                          field.didChange(_selectedImageBytes);
                                        },
                                  icon:
                                      const Icon(Icons.photo_library_outlined),
                                  label: Text(
                                    _selectedImage == null
                                        ? 'اختيار صورة من المعرض'
                                        : 'تغيير الصورة المختارة',
                                  ),
                                ),
                                if (field.errorText != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    field.errorText!,
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'عنوان المشروع',
                              helperText: 'اكتب اسماً جذاباً وواضحاً للمشروع',
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _descController,
                            decoration: const InputDecoration(
                              labelText: 'وصف المشروع',
                              helperText:
                                  'اشرح مميزات المشروع والتقنيات التي يستخدمها',
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 4,
                            validator: (value) =>
                                value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _languageController,
                            decoration: const InputDecoration(
                              labelText: 'لغة البرمجة',
                              hintText: 'مثال: Dart أو JavaScript',
                              prefixIcon: Icon(Icons.code),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'يرجى إدخال لغة البرمجة'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _techStackController,
                            decoration: const InputDecoration(
                              labelText: 'التقنيات المستخدمة',
                              hintText:
                                  'افصل التقنيات بفواصل، مثال: Flutter, Firebase',
                              prefixIcon: Icon(Icons.developer_board),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'يرجى إدخال تقنية واحدة على الأقل'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'رقم هاتف المطور',
                              helperText:
                                  'لن يظهر للعملاء، مخصص للتواصل من قبل الإدارة فقط',
                              prefixIcon: Icon(Icons.phone),
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
                              prefixIcon: Icon(Icons.devices),
                            ),
                            dropdownColor: colorScheme.surfaceContainerHighest,
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
                              if (value != null) {
                                setState(() => _projectType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          if (isCompact) ...[
                            categoryField,
                            const SizedBox(height: 16),
                            priceField,
                          ] else
                            Row(
                              children: [
                                Expanded(child: categoryField),
                                const SizedBox(width: 16),
                                Expanded(child: priceField),
                              ],
                            ),
                          const SizedBox(height: 16),

                          // رابط المعاينة
                          TextFormField(
                            controller: _demoLinkController,
                            decoration: const InputDecoration(
                              labelText: 'رابط تجريبي (اختياري)',
                              helperText: 'رابط لموقع أو فيديو يعرض المشروع',
                              prefixIcon: Icon(Icons.link),
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
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onSecondary,
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
                  const SizedBox(height: 24),
                  const AppFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

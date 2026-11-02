import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/project.dart';
import '../repositories/project_repository.dart';
import '../services/smart_price_matcher_logic.dart';
import 'glass_panel.dart';
import 'project_card.dart';

class SmartPriceMatcher extends StatefulWidget {
  const SmartPriceMatcher({super.key});

  @override
  State<SmartPriceMatcher> createState() => _SmartPriceMatcherState();
}

class _SmartPriceMatcherState extends State<SmartPriceMatcher> {
  final _formKey = GlobalKey<FormState>();
  final _keywordController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();

  String _projectType = 'app';
  bool _isSearching = false;
  String? _errorMessage;
  String? _resultMessage;
  List<_PriceMatch> _matches = [];
  bool _showFallback = false;

  @override
  void dispose() {
    _keywordController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate() || _isSearching) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _resultMessage = null;
      _matches = [];
      _showFallback = false;
    });

    try {
      final budget = double.parse(_budgetController.text.trim());
      final keyword = _keywordController.text.trim().toLowerCase();
      final projects = await context
          .read<ProjectRepository>()
          .getApprovedProjectsByType(_projectType);

      final result = SmartPriceMatcherLogic.findClosestProject(
        projects: projects,
        budget: budget,
        keyword: keyword,
      );

      if (!mounted) return;
      if (result.status == PriceMatchStatus.noCandidates ||
          result.status == PriceMatchStatus.noAffordableMatch) {
        setState(() {
          _showFallback = true;
        });
        return;
      }

      final selectedProject = result.project!;
      setState(() {
        _matches = [_PriceMatch(project: selectedProject)];
        _resultMessage = (budget - selectedProject.price).abs() < 0.000001
            ? 'وجدنا مشروعاً يطابق ميزانيتك تماماً:'
            : 'أقرب مشروع ضمن الميزانية وبفارق لا يتجاوز 40%:';
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'تعذر البحث عن المشاريع: $error';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _contactOnWhatsApp() async {
    final projectType = _projectType == 'website' ? 'موقع' : 'تطبيق';
    final message = [
      'مرحباً أبو أيمن،',
      'أريد الاستفسار عن تنفيذ مشروع جديد:',
      '- وصف المشروع: ${_keywordController.text.trim()}',
      '- نوع المشروع: $projectType',
      '- الميزانية المتوقعة: ${_budgetController.text.trim()} \$',
      '- المدة الزمنية المطلوبة: ${_durationController.text.trim()}',
      '',
      'أرجو التواصل معي لمناقشة التفاصيل.',
    ].join('\n');
    final uri = Uri.parse(
      'https://wa.me/963981359229?text=${Uri.encodeComponent(message)}',
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('تعذر فتح واتساب.');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر فتح واتساب: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: GlassPanel(
            padding: const EdgeInsets.all(22),
            borderRadius: 20,
            hoverable: true,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'احصل على أقرب سعر للمشروع الذي تريده',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 680;
                      final fields = [
                        TextFormField(
                          controller: _keywordController,
                          scrollPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            label: 'كلمة مفتاحية (اختياري)',
                            hint: 'اسم المشروع أو التقنية',
                            icon: Icons.search_rounded,
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _projectType,
                          decoration: _inputDecoration(
                            label: 'نوع المشروع',
                            icon: Icons.category_outlined,
                          ),
                          dropdownColor: colorScheme.surfaceContainerHighest,
                          items: const [
                            DropdownMenuItem(
                              value: 'app',
                              child: Text('تطبيق'),
                            ),
                            DropdownMenuItem(
                              value: 'website',
                              child: Text('موقع'),
                            ),
                          ],
                          onChanged: _isSearching
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _projectType = value);
                                  }
                                },
                        ),
                        TextFormField(
                          controller: _budgetController,
                          scrollPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.search,
                          onFieldSubmitted: (_) => _search(),
                          decoration: _inputDecoration(
                            label: 'الميزانية',
                            hint: 'مثال: 250',
                            icon: Icons.payments_outlined,
                          ),
                          validator: (value) {
                            final budget = double.tryParse(value?.trim() ?? '');
                            if (budget == null ||
                                !budget.isFinite ||
                                budget <= 0) {
                              return 'أدخل ميزانية أكبر من صفر';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _durationController,
                          scrollPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.search,
                          onFieldSubmitted: (_) => _search(),
                          decoration: _inputDecoration(
                            label: 'المدة الزمنية المطلوبة (بالأيام)',
                            hint: 'مثال: 30',
                            icon: Icons.schedule_rounded,
                          ),
                          validator: (value) {
                            final days = int.tryParse(value?.trim() ?? '');
                            if (days == null || days <= 0) {
                              return 'أدخل مدة صحيحة بالأيام';
                            }
                            return null;
                          },
                        ),
                      ];

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: fields[0]),
                            const SizedBox(width: 10),
                            Expanded(flex: 2, child: fields[1]),
                            const SizedBox(width: 10),
                            Expanded(flex: 2, child: fields[2]),
                            const SizedBox(width: 10),
                            Expanded(flex: 2, child: fields[3]),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          fields[0],
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: fields[1]),
                              const SizedBox(width: 10),
                              Expanded(child: fields[2]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          fields[3],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        elevation: 8,
                        shadowColor: const Color(
                          0xFF3B82F6,
                        ).withValues(alpha: 0.35),
                      ),
                      icon: _isSearching
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _isSearching ? 'جارٍ البحث...' : 'ابحث عن الأقرب',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFF87171)),
                    ),
                  ],
                  if (_resultMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _resultMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (_matches.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth >= 760
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: _matches
                              .map(
                                (match) => SizedBox(
                                  width: cardWidth,
                                  child: _buildProjectCard(match),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                  if (_showFallback) ...[
                    const SizedBox(height: 20),
                    _buildFallbackCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCard() {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      color: const Color(0xFF112033),
      hoverable: true,
      child: Column(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            size: 44,
            color: Color(0xFF60A5FA),
          ),
          const SizedBox(height: 12),
          const Text(
            'عذراً، لا يوجد مشروع يطابق ميزانيتك الحالية. ولكن لا تقلق! يمكنك طلب مشروعك المخصص.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تواصل مع مدير التطبيق أحمد الخليف لمساعدتك.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _contactOnWhatsApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.chat_rounded),
              label: const Text(
                'تواصل عبر الواتساب',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  Widget _buildProjectCard(_PriceMatch match) {
    final project = match.project;
    return ProjectCard(
      projectId: project.id,
      developerUid: project.developerId,
      projectType: project.projectType,
      title: project.title,
      developerName: project.developerName,
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
  }
}

class _PriceMatch {
  const _PriceMatch({required this.project});

  final Project project;
}

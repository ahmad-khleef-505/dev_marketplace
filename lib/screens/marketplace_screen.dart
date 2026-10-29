import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';
import '../widgets/project_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/glass_panel.dart';
import '../widgets/smart_price_matcher.dart';
import '../widgets/EmptyStateWidget.dart';
import '../services/purchase_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  static const _pageSize = 10;
  static const _projectCategories = ['تطبيق جوال', 'موقع ويب'];
  static const _availableTechnologies = [
    'Flutter',
    'React',
    'Firebase',
    'Python',
  ];
  static const _maxFilterPrice = 1000.0;
  final ScrollController _marketplaceScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _requestDescriptionController =
      TextEditingController();
  final TextEditingController _requestBudgetController =
      TextEditingController();
  final TextEditingController _requestDeadlineController =
      TextEditingController();
  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  String _searchQuery = "";
  String _languageFilter = '';
  RangeValues _currentPriceRange = const RangeValues(0, 1000);
  Set<String> _selectedTechnologies = {};
  bool _isFilterActive = false;
  final Map<String, List<Project>> _additionalProjects = {};
  final Map<String, ProjectCursor?> _pageCursors = {};
  final Map<String, bool> _hasMoreProjects = {};
  final Set<String> _loadingProjectPages = {};
  bool _isSendingProjectRequest = false;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _marketplaceScrollController.addListener(_handleMarketplaceScroll);
  }

  void _handleMarketplaceScroll() {
    if (!_marketplaceScrollController.hasClients) return;
    final position = _marketplaceScrollController.position;
    if (position.maxScrollExtent - position.pixels > 200) return;

    for (final category in _projectCategories) {
      _loadMoreProjects(category);
    }
  }

  void _handleSearchFocusChange() {
    if (mounted) setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _marketplaceScrollController
      ..removeListener(_handleMarketplaceScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_handleSearchFocusChange)
      ..dispose();
    _languageController.dispose();
    _requestDescriptionController.dispose();
    _requestBudgetController.dispose();
    _requestDeadlineController.dispose();
    super.dispose();
  }

  Future<void> _submitProjectRequest() async {
    if (!_requestFormKey.currentState!.validate() || _isSendingProjectRequest) {
      return;
    }

    setState(() => _isSendingProjectRequest = true);
    final message = [
      'طلب مشروع مخصص - DevMarketplace',
      '',
      'وصف المشروع المطلوب:',
      _requestDescriptionController.text.trim(),
      '',
      'الميزانية المتوقعة: \$${_requestBudgetController.text.trim()}',
      'المدة الزمنية للتنفيذ: ${_requestDeadlineController.text.trim()}',
    ].join('\n');
    final uri = Uri.https('wa.me', '/963981359229', {'text': message});

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw StateError('لم يتمكن الجهاز من فتح رابط واتساب.');
      }
      _requestFormKey.currentState!.reset();
      _requestDescriptionController.clear();
      _requestBudgetController.clear();
      _requestDeadlineController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح واتساب برسالة طلبك. أرسلها لإكمال الطلب.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح واتساب: $error'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingProjectRequest = false);
    }
  }

  Future<void> _contactAdmin() async {
    try {
      final settings = await PurchaseService().publicSettings();
      final phone = (settings['adminWhatsAppPhone'] as String).replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final message = Uri.encodeComponent(
        'مرحباً أبو أيمن، أنا أبحث عن مشروع معين في التطبيق ولم أجده. هل يمكنك مساعدتي في توفيره؟',
      );
      final url = Uri.parse('https://wa.me/$phone?text=$message');
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تأكد من تثبيت واتساب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreProjects(String category) async {
    if (_loadingProjectPages.contains(category) ||
        _hasMoreProjects[category] != true) {
      return;
    }

    final loadedPages = _additionalProjects[category] ?? [];
    final cursor = _pageCursors[category];
    if (cursor == null) return;
    setState(() => _loadingProjectPages.add(category));
    try {
      final page = await context
          .read<ProjectRepository>()
          .getNextApprovedProjects(
            category: category,
            minimumPrice: _currentPriceRange.start,
            maximumPrice: _currentPriceRange.end,
            technologies: Set<String>.from(_selectedTechnologies),
            limit: _pageSize,
            cursor: cursor,
          );
      if (!mounted) return;
      setState(() {
        final existingIds = loadedPages.map((project) => project.id).toSet();
        _additionalProjects[category] = [
          ...loadedPages,
          ...page.projects.where(
            (project) => !existingIds.contains(project.id),
          ),
        ];
        _hasMoreProjects[category] = page.hasMore;
        if (page.cursor != null) _pageCursors[category] = page.cursor;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleMarketplaceScroll();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل المزيد من المشاريع: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingProjectPages.remove(category));
    }
  }

  void _clearFilters() {
    setState(() {
      _currentPriceRange = const RangeValues(0, _maxFilterPrice);
      _selectedTechnologies = {};
      _languageFilter = '';
      _languageController.clear();
      _isFilterActive = false;
      _additionalProjects.clear();
      _pageCursors.clear();
      _hasMoreProjects.clear();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var draftPriceRange = _currentPriceRange;
        final draftTechnologies = Set<String>.from(_selectedTechnologies);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    16 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    color: const Color(0xFF101A2D),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF475569),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'الفلاتر المتقدمة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'نطاق السعر (بالدولار)',
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '\$${draftPriceRange.start.round()} - \$${draftPriceRange.end.round()}',
                              style: const TextStyle(
                                color: Color(0xFF60A5FA),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: draftPriceRange,
                          min: 0,
                          max: _maxFilterPrice,
                          divisions: 20,
                          activeColor: const Color(0xFF3B82F6),
                          inactiveColor: const Color(0xFF334155),
                          labels: RangeLabels(
                            '\$${draftPriceRange.start.round()}',
                            '\$${draftPriceRange.end.round()}',
                          ),
                          onChanged: (values) {
                            setModalState(() => draftPriceRange = values);
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'التقنيات',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _availableTechnologies.map((technology) {
                            final selected = draftTechnologies.contains(
                              technology,
                            );
                            return FilterChip(
                              label: Text(technology),
                              selected: selected,
                              showCheckmark: true,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFFCBD5E1),
                              ),
                              selectedColor: const Color(0xFF2563EB),
                              backgroundColor: const Color(0xFF1E293B),
                              side: BorderSide(
                                color: selected
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF334155),
                              ),
                              onSelected: (value) {
                                setModalState(() {
                                  if (value) {
                                    draftTechnologies.add(technology);
                                  } else {
                                    draftTechnologies.remove(technology);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _languageController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'لغة البرمجة (اختياري)',
                            hintText: 'مثال: Dart',
                            prefixIcon: const Icon(Icons.code),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _clearFilters();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFCBD5E1),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF475569),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('مسح'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _currentPriceRange = draftPriceRange;
                                    _selectedTechnologies = Set<String>.from(
                                      draftTechnologies,
                                    );
                                    _languageFilter = _languageController.text
                                        .trim()
                                        .toLowerCase();
                                    _isFilterActive =
                                        draftPriceRange.start > 0 ||
                                        draftPriceRange.end < _maxFilterPrice ||
                                        draftTechnologies.isNotEmpty ||
                                        _languageFilter.isNotEmpty;
                                    _additionalProjects.clear();
                                    _pageCursors.clear();
                                    _hasMoreProjects.clear();
                                  });
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.tune),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                label: const Text('تطبيق الفلتر'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D19),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isSearchFocused && kIsWeb
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF3B82F6,
                                ).withValues(alpha: 0.22),
                                blurRadius: 22,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن تطبيق، موقع، أو تقنية...',
                        hintStyle: GoogleFonts.cairo(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF60A5FA),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: Color(0xFF94A3B8),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: _isSearchFocused
                            ? const Color(0xFF111D31)
                            : const Color(0xFF0D1728),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _isSearchFocused
                                ? const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.55)
                                : const Color(0xFF26364F),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF60A5FA),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'الفلاتر المتقدمة',
              icon: Icon(
                Icons.tune_rounded,
                color: _isFilterActive ? const Color(0xFF60A5FA) : Colors.white,
              ),
              onPressed: _showFilterSheet,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _marketplaceScrollController,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SmartPriceMatcher(),
                _buildSection(
                  'التطبيقات المميزة',
                  'تطبيق جوال',
                  Icons.phone_android,
                ),
                _buildSection('المواقع المميزة', 'موقع ويب', Icons.web),
                _buildCustomProjectRequest(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomProjectRequest() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: GlassPanel(
            padding: const EdgeInsets.all(24),
            borderRadius: 20,
            hoverable: true,
            child: Form(
              key: _requestFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF60A5FA),
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'لم تجد ما تبحث عنه؟ اطلب مشروعك الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أخبرنا بما تحتاجه وسنساعدك في الوصول إلى المشروع المناسب.',
                    style: TextStyle(color: Color(0xFF94A3B8), height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    controller: _requestDescriptionController,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 2000,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      labelText: 'وصف المشروع المطلوب',
                      hintText: 'اشرح فكرة المشروع والميزات التي تحتاجها...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 64),
                        child: Icon(Icons.description_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'وصف المشروع مطلوب.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final deadlineField = TextFormField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        controller: _requestDeadlineController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'المدة الزمنية للتنفيذ',
                          hintText: 'مثال: شهر واحد',
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixIcon: const Icon(Icons.schedule_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'المدة الزمنية مطلوبة.'
                            : null,
                      );
                      final budgetField = TextFormField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        controller: _requestBudgetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'الميزانية المتوقعة',
                          prefixText: '\$ ',
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixIcon: const Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          final budget = double.tryParse(value?.trim() ?? '');
                          return budget == null ||
                                  !budget.isFinite ||
                                  budget <= 0
                              ? 'أدخل ميزانية رقمية أكبر من صفر.'
                              : null;
                        },
                      );
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            budgetField,
                            const SizedBox(height: 12),
                            deadlineField,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: budgetField),
                          const SizedBox(width: 12),
                          Expanded(child: deadlineField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSendingProjectRequest
                          ? null
                          : _submitProjectRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSendingProjectRequest
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.chat),
                      label: const Text(
                        'إرسال الطلب عبر واتساب',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.035, end: 0),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String category, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: 16,
            color: const Color(0xFF101A2D),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF60A5FA), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (kIsWeb)
                  TextButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const MarketplaceScreen(),
                      ),
                    ),
                    child: const Text(
                      'مشاهدة المشاريع',
                      style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.025, end: 0),
        ),

        StreamBuilder<ProjectPage>(
          stream: context.read<ProjectRepository>().getApprovedProjects(
            category: category,
            minimumPrice: _currentPriceRange.start,
            maximumPrice: _currentPriceRange.end,
            technologies: Set<String>.from(_selectedTechnologies),
            limit: _pageSize,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'تعذر تحميل المشاريع: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1100
                      ? 4
                      : constraints.maxWidth >= 700
                      ? 3
                      : 2;
                  return GridView.builder(
                    reverse: true,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 6,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 420,
                    ),
                    itemBuilder: (context, index) => const ShimmerCard(),
                  );
                },
              );
            }

            final firstPage = snapshot.data!.projects;
            if ((_additionalProjects[category] ?? []).isEmpty) {
              _hasMoreProjects[category] = snapshot.data!.hasMore;
              _pageCursors[category] = snapshot.data!.cursor;
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _handleMarketplaceScroll();
            });
            final allProjects = [
              ...firstPage,
              ...(_additionalProjects[category] ?? []),
            ];
            final projects = allProjects.where((project) {
              final pTitle = project.title.toLowerCase();
              final pDesc = project.description.toLowerCase();
              final pTech = project.techStack.join(' ').toLowerCase();
              final pLanguage = project.language.toLowerCase();
              final pPrice = project.price;

              bool matchesSearch =
                  pTitle.contains(_searchQuery) ||
                  pDesc.contains(_searchQuery) ||
                  pTech.contains(_searchQuery);
              final matchesPrice =
                  pPrice >= _currentPriceRange.start &&
                  pPrice <= _currentPriceRange.end;
              final matchesLanguage =
                  _languageFilter.isEmpty ||
                  pLanguage.contains(_languageFilter) ||
                  pTech.contains(_languageFilter);

              return matchesSearch && matchesPrice && matchesLanguage;
            }).toList();

            if (projects.isEmpty) {
              return Column(
                children: [
                  EmptyStateWidget(
                    lottiePath:
                        'https://assets9.lottiefiles.com/packages/lf20_0yfsb3a1.json',
                    title: 'لم يتم العثور على نتائج مطابقة',
                    subtitle:
                        'جرّب تعديل كلمات البحث أو الفلاتر، أو اطلب من الإدارة توفير المشروع الذي تبحث عنه.',
                    actionLabel: 'اطلب من الإدارة توفيره',
                    onActionPressed: _contactAdmin,
                  ),
                  if (_loadingProjectPages.contains(category))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktopWeb = kIsWeb && constraints.maxWidth >= 700;
                final columns = (constraints.maxWidth / 310).floor().clamp(
                  2,
                  5,
                );
                Widget projectCard(int index) {
                  final project = projects[index];
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
                      )
                      .animate()
                      .fadeIn(
                        duration: 250.ms,
                        delay: (index.clamp(0, 8) * 35).ms,
                      )
                      .slideY(begin: 0.04, end: 0);
                }

                final projectsLayout = isDesktopWeb
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          columns,
                          (column) => Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: column == 0 ? 24 : 9,
                                end: column == columns - 1 ? 24 : 9,
                              ),
                              child: GridView.builder(
                                reverse: true,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: column >= projects.length
                                    ? 0
                                    : (projects.length -
                                              column +
                                              columns -
                                              1) ~/
                                          columns,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      mainAxisSpacing: 18,
                                      mainAxisExtent: 430,
                                    ),
                                itemBuilder: (context, itemIndex) {
                                  final index = column + itemIndex * columns;
                                  return projectCard(index);
                                },
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        reverse: true,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: projects.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) =>
                            SizedBox(height: 420, child: projectCard(index)),
                      );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    projectsLayout,
                    if (_loadingProjectPages.contains(category))
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

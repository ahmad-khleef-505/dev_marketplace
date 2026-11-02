import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/glass_panel.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.onCompleted,
    this.isDialog = false,
    super.key,
  });

  final VoidCallback onCompleted;
  final bool isDialog;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _whatsAppNumber = '963981359229';
  static const _feedbackEmail = 'ahmadkhleefahmad@gmail.com';
  static const _emailSubject = 'اقتراحات لتطوير المنصة';

  static const _features = [
    (
      title: 'نظام اشتراكات المطورين',
      description: 'لضمان دخل شهري ثابت للمطورين.',
    ),
    (
      title: 'التحقق من الهوية (KYC)',
      description: 'لزيادة الأمان والمصداقية بين العميل والمطور.',
    ),
    (
      title: 'مساحة عمل سحابية',
      description: 'لحفظ الأكواد وإدارة المشاريع مباشرة من المنصة.',
    ),
    (
      title: 'نظام الإحالة',
      description: 'لمنح مكافآت للعملاء الذين يجذبون مستخدمين جدد.',
    ),
    (
      title: 'مدونة تقنية',
      description: 'لنشر المقالات التقنية والأخبار الخاصة بالمبرمجين.',
    ),
    (
      title: 'دعم فني متقدم',
      description: 'لإعطاء أولوية في الرد والدعم للمشاريع الكبيرة.',
    ),
  ];

  final _suggestionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<int> _selectedFeatures = {};
  bool _isSending = false;
  String? _selectionError;

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  String _buildFeedbackMessage() {
    final selected = _selectedFeatures
        .map(
          (index) =>
              '- ${_features[index].title}: ${_features[index].description}',
        )
        .join('\n');
    final suggestion = _suggestionController.text.trim();
    return [
      'اقتراحات لتطوير سوق المطورين',
      if (selected.isNotEmpty) ...['المميزات المقترحة:', selected],
      if (suggestion.isNotEmpty) ...['ميزة أخرى:', suggestion],
    ].join('\n\n');
  }

  Future<void> _sendFeedback({required bool byEmail}) async {
    if (_selectedFeatures.isEmpty &&
        _suggestionController.text.trim().isEmpty) {
      setState(
        () => _selectionError = 'اختر ميزة أو اكتب اقتراحاً قبل الإرسال.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _selectionError = null;
    });

    try {
      final message = _buildFeedbackMessage();
      final uri = byEmail
          ? Uri(
              scheme: 'mailto',
              path: _feedbackEmail,
              queryParameters: {'subject': _emailSubject, 'body': message},
            )
          : Uri.parse(
              'https://wa.me/$_whatsAppNumber?text=${Uri.encodeComponent(message)}',
            );

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('No application could open $uri');

      if (!mounted) return;
      widget.onCompleted();
    } catch (error, stackTrace) {
      debugPrint('Feedback submission launch failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح تطبيق الإرسال. حاول مرة أخرى.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: widget.isDialog
          ? Material(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      12,
                      20,
                      4,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'رأيك يصنع الفرق',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'إغلاق وتسجيل الخروج',
                          onPressed: _isSending ? null : widget.onCompleted,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildFeedbackForm()),
                ],
              ),
            )
          : Scaffold(
              appBar: AppBar(
                title: const Text('رأيك يصنع الفرق'),
                automaticallyImplyLeading: false,
              ),
              body: SafeArea(child: _buildFeedbackForm()),
            ),
    );
  }

  Widget _buildFeedbackForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFF3B82F6),
                size: 46,
              ),
              const SizedBox(height: 12),
              const Text(
                'مرحباً بك في سوق المطورين!\nساعدنا في رسم ملامح المستقبل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ما الميزات الاحترافية التي ترغب في رؤيتها؟ اختر كل ما يهمك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), height: 1.5),
              ),
              const SizedBox(height: 20),
              ...List.generate(_features.length, (index) {
                final feature = _features[index];
                final selected = _selectedFeatures.contains(index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassPanel(
                    borderRadius: 10,
                    child: CheckboxListTile(
                      value: selected,
                      activeColor: const Color(0xFF3B82F6),
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        feature.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        feature.description,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          height: 1.4,
                        ),
                      ),
                      onChanged: _isSending
                          ? null
                          : (value) => setState(() {
                                if (value == true) {
                                  _selectedFeatures.add(index);
                                } else {
                                  _selectedFeatures.remove(index);
                                }
                                _selectionError = null;
                              }),
                    ),
                  ),
                );
              }),
              if (_selectionError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _selectionError!,
                  style: const TextStyle(color: Color(0xFFFCA5A5)),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _suggestionController,
                enabled: !_isSending,
                minLines: 3,
                maxLines: 5,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'ميزة أخرى تقترحها؟',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (_) => _selectedFeatures.isEmpty &&
                        _suggestionController.text.trim().isEmpty
                    ? 'اختر ميزة أو اكتب اقتراحاً قبل الإرسال.'
                    : null,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      _isSending ? null : () => _sendFeedback(byEmail: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text('إرسال عبر واتساب'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed:
                      _isSending ? null : () => _sendFeedback(byEmail: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('إرسال عبر الإيميل'),
                ),
              ),
              if (_isSending) ...[
                const SizedBox(height: 12),
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

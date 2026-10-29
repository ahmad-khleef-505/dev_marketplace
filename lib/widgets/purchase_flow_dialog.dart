import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseFlowDialog extends StatefulWidget {
  const PurchaseFlowDialog({
    required this.projectTitle,
    required this.projectType,
    required this.developerName,
    required this.projectLink,
    super.key,
  });

  final String projectTitle;
  final String projectType;
  final String developerName;
  final String projectLink;

  @override
  State<PurchaseFlowDialog> createState() => _PurchaseFlowDialogState();
}

class _PurchaseFlowDialogState extends State<PurchaseFlowDialog> {
  bool _isOpeningWhatsApp = false;

  Future<void> _openWhatsApp() async {
    if (_isOpeningWhatsApp) return;
    setState(() => _isOpeningWhatsApp = true);

    final link = widget.projectLink.trim().isEmpty
        ? 'غير متوفر'
        : widget.projectLink.trim();
    final message = [
      'مرحباً، أريد شراء/الاستفسار عن الكود المصدري للمشروع التالي:',
      '- اسم المشروع: ${widget.projectTitle}',
      '- نوع المشروع: ${widget.projectType}',
      '- اسم المطور: ${widget.developerName}',
      '- رابط المشروع المباشر: $link',
    ].join('\n');
    final uri = Uri.https('wa.me', '/963981359229', {'text': message});

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('تعذر فتح واتساب.');
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر فتح واتساب: $error')));
    } finally {
      if (mounted) setState(() => _isOpeningWhatsApp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111B2D),
      icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 42),
      title: const Text(
        'التواصل لإتمام الشراء',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'لإتمام الشراء والاستفسار، يرجى التواصل مباشرة عبر الواتساب',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFCBD5E1), height: 1.6),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isOpeningWhatsApp ? null : _openWhatsApp,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isOpeningWhatsApp
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.chat_rounded),
            label: Text(
              _isOpeningWhatsApp ? 'جارٍ فتح واتساب...' : 'تواصل عبر واتساب',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

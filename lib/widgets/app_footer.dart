import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'glass_panel.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const _phoneNumber = '+963 981 359 229';
  static const _whatsAppNumber = '963981359229';

  Future<void> _openContact(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('تعذر فتح تطبيق التواصل.');
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح تطبيق التواصل: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        borderRadius: 0,
        color: const Color(0xFF111C30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              spacing: 16,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'تصميم وتطوير: المبرمج أحمد الخليف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 15,
                      color: Color(0xFF94A3B8),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Text(
                        _phoneNumber,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'تواصل عبر واتساب',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () => _openContact(
                        context,
                        Uri.https('wa.me', '/$_whatsAppNumber'),
                      ),
                      icon: const Icon(
                        Icons.chat,
                        size: 18,
                        color: Color(0xFF25D366),
                      ),
                    ),
                    IconButton(
                      tooltip: 'اتصال هاتفي',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () => _openContact(
                        context,
                        Uri(
                          scheme: 'tel',
                          path: _phoneNumber.replaceAll(' ', ''),
                        ),
                      ),
                      icon: const Icon(
                        Icons.call_outlined,
                        size: 18,
                        color: Color(0xFF60A5FA),
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
  }
}

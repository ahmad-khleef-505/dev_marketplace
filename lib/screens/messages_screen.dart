import 'package:flutter/material.dart';

import '../widgets/EmptyStateWidget.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({required this.onBrowseProjects, super.key});

  final VoidCallback onBrowseProjects;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'الرسائل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: EmptyStateWidget(
        lottiePath:
            'https://assets9.lottiefiles.com/packages/lf20_0yfsb3a1.json',
        title: 'لا توجد محادثات بعد',
        subtitle: 'عند تواصلك مع المطورين ستظهر محادثاتك ورسائلك هنا.',
        actionLabel: 'تصفح المشاريع الآن',
        onActionPressed: onBrowseProjects,
      ),
    );
  }
}

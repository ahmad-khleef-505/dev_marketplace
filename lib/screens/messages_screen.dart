import 'package:flutter/material.dart';

import '../widgets/EmptyStateWidget.dart';
import '../widgets/app_footer.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({required this.onBrowseProjects, super.key});

  final VoidCallback onBrowseProjects;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسائل'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: EmptyStateWidget(
              lottiePath:
                  'https://assets9.lottiefiles.com/packages/lf20_0yfsb3a1.json',
              title: 'لا توجد محادثات بعد',
              subtitle: 'عند تواصلك مع المطورين ستظهر محادثاتك ورسائلك هنا.',
              actionLabel: 'تصفح المشاريع الآن',
              onActionPressed: onBrowseProjects,
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}

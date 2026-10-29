import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/legal_screen.dart';
import 'screens/main_screen.dart';
import 'services/push_notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'repositories/admin_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/favorite_repository.dart';
import 'repositories/project_chat_repository.dart';
import 'repositories/project_repository.dart';
import 'repositories/purchase_order_repository.dart';
import 'repositories/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (PushNotificationService.isMessagingPlatformSupported) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  await PushNotificationService.instance.initialize();
  final themeProvider = await ThemeProvider.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => AdminRepository()),
        ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(repository: context.read<AuthRepository>()),
        ),
        Provider(create: (_) => ProjectRepository()),
        Provider(create: (_) => ProjectChatRepository()),
        Provider(create: (_) => PurchaseOrderRepository()),
        Provider(create: (_) => UserRepository()),
        ChangeNotifierProvider(
          create: (context) => UserProvider(
            repository: context.read<UserRepository>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FavoritesProvider(
            repository: FavoriteRepository(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),
      ],
      child: const DevMarketplaceApp(),
    ),
  );
}

class DevMarketplaceApp extends StatelessWidget {
  const DevMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = GoogleFonts.poppinsTextTheme();
    return MaterialApp(
      title: 'Dev Marketplace',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: notificationMessengerKey,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)
            .apply(
              bodyColor: const Color(0xFF0F172A),
              displayColor: const Color(0xFF0F172A),
            ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          surface: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.white54),
          labelStyle: TextStyle(color: Colors.white70),
          floatingLabelStyle: TextStyle(color: Color(0xFF60A5FA)),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF3B82F6),
          selectionColor: Color(0x663B82F6),
          selectionHandleColor: Color(0xFF3B82F6),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
            .merge(textTheme)
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF0F172A),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.white54),
          labelStyle: TextStyle(color: Colors.white70),
          floatingLabelStyle: TextStyle(color: Color(0xFF60A5FA)),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF3B82F6),
          selectionColor: Color(0x663B82F6),
          selectionHandleColor: Color(0xFF3B82F6),
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            );
          }
          if (authProvider.error != null) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'تعذر التحقق من حالة تسجيل الدخول: ${authProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          final user = authProvider.currentUser;
          return user == null
              ? const AuthScreen()
              : _TermsConsentGate(key: ValueKey(user.uid), user: user);
        },
      ),
    );
  }
}

class _TermsConsentGate extends StatefulWidget {
  const _TermsConsentGate({required this.user, super.key});

  final User user;

  @override
  State<_TermsConsentGate> createState() => _TermsConsentGateState();
}

class _TermsConsentGateState extends State<_TermsConsentGate> {
  static const _consentVersion = '2026-10-29';
  bool? _hasAccepted;
  bool _isShowingDialog = false;
  String? _loadError;

  String get _preferenceKey =>
      'legal_consent_${widget.user.uid}_$_consentVersion';

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _hasAccepted = preferences.getBool(_preferenceKey) ?? false;
        _loadError = null;
      });
      if (!_hasAccepted!) _showConsentDialog();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'تعذر التحقق من الموافقة على الشروط: $error';
      });
    }
  }

  void _showConsentDialog() {
    if (_isShowingDialog || !mounted) return;
    _isShowingDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _TermsConsentDialog(
          onAccepted: () async {
            final preferences = await SharedPreferences.getInstance();
            await preferences.setBool(_preferenceKey, true);
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(true);
            }
          },
          onDeclined: () async {
            try {
              await context.read<AuthProvider>().signOut();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(false);
              }
            } on FirebaseAuthException catch (error) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تعذر تسجيل الخروج: ${error.message ?? error.code}',
                    ),
                  ),
                );
              }
            }
          },
        ),
      );
      _isShowingDialog = false;
      if (!mounted) return;
      if (accepted == true) {
        setState(() => _hasAccepted = true);
      } else if (context.read<AuthProvider>().currentUser?.uid ==
          widget.user.uid) {
        _showConsentDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _loadError = null);
                    _loadConsent();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_hasAccepted != true) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }
    return const MainScreen();
  }
}

class _TermsConsentDialog extends StatefulWidget {
  const _TermsConsentDialog({
    required this.onAccepted,
    required this.onDeclined,
  });

  final Future<void> Function() onAccepted;
  final Future<void> Function() onDeclined;

  @override
  State<_TermsConsentDialog> createState() => _TermsConsentDialogState();
}

class _TermsConsentDialogState extends State<_TermsConsentDialog> {
  bool _isSaving = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onAccepted();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'تعذر حفظ موافقتك. حاول مرة أخرى: $error';
        });
      }
    }
  }

  Future<void> _decline() async {
    setState(() => _isSaving = true);
    await widget.onDeclined();
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFF111B2D),
        icon: const Icon(
          Icons.policy_outlined,
          color: Color(0xFF60A5FA),
          size: 34,
        ),
        title: const Text(
          'الشروط والأحكام وسياسة الخصوصية',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'لاستخدام المنصة، يرجى مراجعة الشروط وسياسة الخصوصية والموافقة عليهما. يمكنك فتح الصفحة الكاملة قبل اتخاذ القرار.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFCBD5E1), height: 1.6),
              ),
              TextButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalScreen(),
                        ),
                      ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('قراءة الشروط كاملة'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFF87171)),
                ),
              ],
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _decline,
            child: const Text(
              'رفض وتسجيل الخروج',
              style: TextStyle(color: Color(0xFFF87171)),
            ),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _accept,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('موافقة ومتابعة'),
          ),
        ],
      ),
    );
  }
}

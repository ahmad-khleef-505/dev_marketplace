import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'legal_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController(); // حقل الاسم الجديد

  bool _isLogin = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'client';
  bool _isArabic = true;

  String _selectedCountryCode = '+962';

  bool get _isLoginInputValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) &&
        password.length >= 6;
  }

  final List<Map<String, String>> _countries = [
    {'name': 'الأردن', 'nameEn': 'Jordan', 'code': '+962'},
    {'name': 'السعودية', 'nameEn': 'Saudi Arabia', 'code': '+966'},
    {'name': 'الإمارات', 'nameEn': 'UAE', 'code': '+971'},
    {'name': 'قطر', 'nameEn': 'Qatar', 'code': '+974'},
    {'name': 'الكويت', 'nameEn': 'Kuwait', 'code': '+965'},
    {'name': 'البحرين', 'nameEn': 'Bahrain', 'code': '+973'},
    {'name': 'عمان', 'nameEn': 'Oman', 'code': '+968'},
    {'name': 'فلسطين', 'nameEn': 'Palestine', 'code': '+970'},
    {'name': 'مصر', 'nameEn': 'Egypt', 'code': '+20'},
    {'name': 'سوريا', 'nameEn': 'Syria', 'code': '+963'},
    {'name': 'لبنان', 'nameEn': 'Lebanon', 'code': '+961'},
    {'name': 'العراق', 'nameEn': 'Iraq', 'code': '+964'},
    {'name': 'المغرب', 'nameEn': 'Morocco', 'code': '+212'},
    {'name': 'الجزائر', 'nameEn': 'Algeria', 'code': '+213'},
    {'name': 'تونس', 'nameEn': 'Tunisia', 'code': '+216'},
    {'name': 'ليبيا', 'nameEn': 'Libya', 'code': '+218'},
    {'name': 'السودان', 'nameEn': 'Sudan', 'code': '+249'},
    {'name': 'اليمن', 'nameEn': 'Yemen', 'code': '+967'},
    {'name': 'تركيا', 'nameEn': 'Turkey', 'code': '+90'},
    {'name': 'أمريكا', 'nameEn': 'USA', 'code': '+1'},
    {'name': 'بريطانيا', 'nameEn': 'UK', 'code': '+44'},
    {'name': 'كندا', 'nameEn': 'Canada', 'code': '+1'},
    {'name': 'ألمانيا', 'nameEn': 'Germany', 'code': '+49'},
    {'name': 'فرنسا', 'nameEn': 'France', 'code': '+33'},
    {'name': 'إيطاليا', 'nameEn': 'Italy', 'code': '+39'},
    {'name': 'إسبانيا', 'nameEn': 'Spain', 'code': '+34'},
    {'name': 'هولندا', 'nameEn': 'Netherlands', 'code': '+31'},
    {'name': 'السويد', 'nameEn': 'Sweden', 'code': '+46'},
    {'name': 'روسيا', 'nameEn': 'Russia', 'code': '+7'},
    {'name': 'الصين', 'nameEn': 'China', 'code': '+86'},
    {'name': 'اليابان', 'nameEn': 'Japan', 'code': '+81'},
    {'name': 'كوريا الجنوبية', 'nameEn': 'South Korea', 'code': '+82'},
    {'name': 'الهند', 'nameEn': 'India', 'code': '+91'},
    {'name': 'باكستان', 'nameEn': 'Pakistan', 'code': '+92'},
    {'name': 'إندونيسيا', 'nameEn': 'Indonesia', 'code': '+62'},
    {'name': 'ماليزيا', 'nameEn': 'Malaysia', 'code': '+60'},
    {'name': 'البرازيل', 'nameEn': 'Brazil', 'code': '+55'},
    {'name': 'أستراليا', 'nameEn': 'Australia', 'code': '+61'},
    {'name': 'جنوب أفريقيا', 'nameEn': 'South Africa', 'code': '+27'},
    {'name': 'نيجيريا', 'nameEn': 'Nigeria', 'code': '+234'},
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await context.read<AuthProvider>().signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
      } else {
        await context.read<AuthProvider>().register(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              name: _nameController.text.trim(),
              role: _selectedRole,
              phone: '$_selectedCountryCode${_phoneController.text.trim()}',
            );
      }
    } on FirebaseAuthException catch (e) {
      String message = _isArabic ? 'حدث خطأ ما' : 'An error occurred';
      if (e.code == 'user-not-found') {
        message = _isArabic ? 'لا يوجد حساب بهذا البريد' : 'No user found.';
      }
      if (e.code == 'wrong-password') {
        message = _isArabic ? 'كلمة المرور غير صحيحة' : 'Wrong password.';
      }
      if (e.code == 'email-already-in-use') {
        message =
            _isArabic ? 'هذا البريد مسجل مسبقاً' : 'Email already in use.';
      }
      if (e.code == 'weak-password') {
        message = _isArabic ? 'كلمة المرور ضعيفة جداً' : 'Password too weak.';
      }
      if (e.code == 'invalid-email') {
        message = _isArabic ? 'البريد الإلكتروني غير صالح' : 'Invalid email.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic
                ? 'أدخل بريدك الإلكتروني أولاً.'
                : 'Enter your email first.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'إذا كان البريد مسجلاً، ستصلك رسالة لإعادة تعيين كلمة المرور.'
                  : 'If the email is registered, a reset link will be sent.',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.code == 'invalid-email'
                  ? (_isArabic
                      ? 'البريد الإلكتروني غير صالح.'
                      : 'Invalid email address.')
                  : (_isArabic
                      ? 'تعذر إرسال رسالة الاستعادة.'
                      : 'Could not send reset email.'),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1555066931-4365d14bab8c?q=80&w=1000&auto=format&fit=crop',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.75)),
            ),
            SafeArea(
              child: Align(
                alignment: _isArabic ? Alignment.topLeft : Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _isArabic = !_isArabic),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF1E293B,
                      ).withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                    icon: const Icon(Icons.language, size: 18),
                    label: Text(_isArabic ? 'English' : 'عربي'),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16.0 : 40.0,
                    vertical: 20.0,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: EdgeInsets.all(isMobile ? 24.0 : 40.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      onChanged: () => setState(() {}),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.code,
                              size: 40,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isArabic ? 'سوق المبرمجين' : 'Dev Marketplace',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin
                                ? (_isArabic
                                    ? 'مرحباً بعودتك! يرجى إدخال بياناتك.'
                                    : 'Welcome back! Please enter your details.')
                                : (_isArabic
                                    ? 'أنشئ حساباً للبدء.'
                                    : 'Create an account to get started.'),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // حقل الاسم (يظهر فقط عند إنشاء حساب)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText:
                                    _isArabic ? 'الاسم الكامل' : 'Full Name',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF94A3B8),
                                ),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? (_isArabic
                                          ? 'الاسم الكامل مطلوب.'
                                          : 'Full name is required.')
                                      : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText:
                                  _isArabic ? 'البريد الإلكتروني' : 'Email',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Color(0xFF94A3B8),
                              ),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return _isArabic
                                    ? 'البريد الإلكتروني مطلوب.'
                                    : 'Email is required.';
                              }
                              if (!RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(email)) {
                                return _isArabic
                                    ? 'أدخل بريداً إلكترونياً صالحاً.'
                                    : 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          if (!_isLogin) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: Container(
                                    height: 58,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCountryCode,
                                        isExpanded: true,
                                        dropdownColor: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                        ),
                                        onChanged: (String? newValue) =>
                                            setState(
                                          () =>
                                              _selectedCountryCode = newValue!,
                                        ),
                                        items: _countries
                                            .map<DropdownMenuItem<String>>((
                                          Map<String, String> country,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: country['code'],
                                            child: Text(
                                              '${_isArabic ? country['name'] : country['nameEn']} ${country['code']}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumber,
                                    ],
                                    decoration: InputDecoration(
                                      labelText:
                                          _isArabic ? 'رقم الهاتف' : 'Phone',
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF3B82F6),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().length < 6
                                            ? (_isArabic
                                                ? 'أدخل رقم هاتف صحيحاً.'
                                                : 'Enter a valid phone number.')
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: _isLogin
                                ? const [AutofillHints.password]
                                : const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: _isArabic ? 'كلمة المرور' : 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF94A3B8),
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? (_isArabic
                                        ? 'إظهار كلمة المرور'
                                        : 'Show password')
                                    : (_isArabic
                                        ? 'إخفاء كلمة المرور'
                                        : 'Hide password'),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3B82F6),
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) {
                                return _isArabic
                                    ? 'كلمة المرور مطلوبة.'
                                    : 'Password is required.';
                              }
                              if (password.length < 6) {
                                return _isArabic
                                    ? 'كلمة المرور 6 أحرف على الأقل.'
                                    : 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),

                          if (_isLogin)
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed:
                                    _isLoading ? null : _sendPasswordResetEmail,
                                child: Text(
                                  _isArabic
                                      ? 'نسيت كلمة المرور؟'
                                      : 'Forgot password?',
                                ),
                              ),
                            ),

                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: _isArabic
                                    ? 'تأكيد كلمة المرور'
                                    : 'Confirm Password',
                                prefixIcon: const Icon(
                                  Icons.lock_reset,
                                  color: Color(0xFF94A3B8),
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmPassword
                                      ? (_isArabic
                                          ? 'إظهار كلمة المرور'
                                          : 'Show password')
                                      : (_isArabic
                                          ? 'إخفاء كلمة المرور'
                                          : 'Hide password'),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return _isArabic
                                      ? 'تأكيد كلمة المرور مطلوب.'
                                      : 'Password confirmation is required.';
                                }
                                if (value != _passwordController.text) {
                                  return _isArabic
                                      ? 'كلمتا المرور غير متطابقتين.'
                                      : 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (val) =>
                                    setState(() => _rememberMe = val!),
                                activeColor: const Color(0xFF3B82F6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Text(
                                _isArabic ? 'تذكرني' : 'Remember me',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: !_isLogin
                                ? Column(
                                    children: [
                                      Text(
                                        _isArabic ? 'أنا...' : 'I am a...',
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isNarrow =
                                              constraints.maxWidth < 320;
                                          final roleCardWidth = isNarrow
                                              ? constraints.maxWidth
                                              : (constraints.maxWidth - 12) / 2;
                                          return Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: [
                                              SizedBox(
                                                width: roleCardWidth,
                                                child: _buildRoleCard(
                                                  title: _isArabic
                                                      ? 'عميل'
                                                      : 'Client',
                                                  description: _isArabic
                                                      ? 'شراء المشاريع'
                                                      : 'Buy projects',
                                                  icon: Icons
                                                      .shopping_bag_outlined,
                                                  isSelected:
                                                      _selectedRole == 'client',
                                                  onTap: () => setState(
                                                    () => _selectedRole =
                                                        'client',
                                                  ),
                                                  color: const Color(
                                                    0xFF3B82F6,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: roleCardWidth,
                                                child: _buildRoleCard(
                                                  title: _isArabic
                                                      ? 'مطور'
                                                      : 'Developer',
                                                  description: _isArabic
                                                      ? 'بيع المهارات'
                                                      : 'Sell skills',
                                                  icon: Icons.terminal,
                                                  isSelected: _selectedRole ==
                                                      'developer',
                                                  onTap: () => setState(
                                                    () => _selectedRole =
                                                        'developer',
                                                  ),
                                                  color: const Color(
                                                    0xFF10B981,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ||
                                      (_isLogin && !_isLoginInputValid)
                                  ? null
                                  : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFF3B82F6,
                                ),
                                disabledForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
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
                                  : Text(
                                      _isLogin
                                          ? (_isArabic ? 'دخول' : 'Sign In')
                                          : (_isArabic
                                              ? 'إنشاء حساب'
                                              : 'Create Account'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          TextButton(
                            onPressed: () =>
                                setState(() => _isLogin = !_isLogin),
                            child: RichText(
                              text: TextSpan(
                                text: _isLogin
                                    ? (_isArabic
                                        ? "ليس لديك حساب؟ "
                                        : "Don't have an account? ")
                                    : (_isArabic
                                        ? "لديك حساب بالفعل؟ "
                                        : "Already have an account? "),
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                                children: [
                                  TextSpan(
                                    text: _isLogin
                                        ? (_isArabic ? 'إنشاء حساب' : 'Sign up')
                                        : (_isArabic ? 'دخول' : 'Sign in'),
                                    style: const TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const LegalScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.policy_outlined, size: 17),
                            label: Text(
                              _isArabic
                                  ? 'الشروط والأحكام وسياسة الخصوصية'
                                  : 'Terms and Privacy Policy',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF93C5FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : const Color(0xFF94A3B8),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : const Color(0xFFCBD5E1),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessageFilter {
  const ChatMessageFilter._();

  static final _phoneKeyword = RegExp(r'(?:رقم|هاتف|موبايل|واتس|اتصل|اتصال)');
  static final _digit = RegExp(r'[0-9٠-٩۰-۹]');
  static final _longNumber = RegExp(r'[0-9٠-٩۰-۹]{7,}');
  static final _localMobile = RegExp(r'(?:09|٠٩|۰۹)[0-9٠-٩۰-۹]+');

  static bool containsPhoneNumber(String text) =>
      _longNumber.hasMatch(text) ||
      _localMobile.hasMatch(text) ||
      text.contains('+963') ||
      (_phoneKeyword.hasMatch(text) && _digit.hasMatch(text));

  static bool isMessageAllowed(String text) => !containsPhoneNumber(text);
}

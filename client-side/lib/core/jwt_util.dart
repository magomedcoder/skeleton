import 'dart:convert';

String _base64UrlDecode(String input) {
  var output = input.replaceAll('-', '+').replaceAll('_', '/');
  switch (output.length % 4) {
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
  }
  return utf8.decode(base64.decode(output));
}

DateTime? getAccessTokenExpiry(String? accessToken) {
  if (accessToken == null || accessToken.isEmpty) return null;
  final parts = accessToken.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = parts[1];
    final decoded = _base64UrlDecode(payload);
    final map = jsonDecode(decoded) as Map<String, dynamic>;
    final exp = map['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    }
    return null;
  } catch (_) {
    return null;
  }
}

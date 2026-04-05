import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleiq/services/auth/auth_service.dart';

class AppUserService {
  AppUserService._();

  static String get currentUserId {
    try {
      return AuthService().currentUserId ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  static Future<Map<String, String>> getStylePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    const keys = [
      'dress_code',
      'color_palette',
      'style_goals',
      'cultural_background',
      'fashion_adventure',
      'shopping_budget',
      'style_challenge',
      'tips_frequency',
    ];

    final values = <String, String>{};
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        values[key] = value;
      }
    }
    return values;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/makeover/models/hairstyle_recommendation.dart';
import 'package:styleiq/features/wardrobe/models/wardrobe_item.dart';
import 'package:styleiq/models/notification.dart' as notification_model;
import 'package:styleiq/models/notification_settings.dart';
import 'package:styleiq/models/privacy_settings.dart';
import 'package:styleiq/models/subscription_plan.dart';
import 'package:styleiq/models/user_profile.dart';

/// Service for local storage using Hive
class LocalStorageService {
  static const String userProfileBox = 'user_profile';
  static const String styleAnalysisBox = 'style_analyses';
  static const String appPreferencesBox = 'app_preferences';
  static const String onboardingBox = 'onboarding_answers';
  static const String wardrobeBox = 'wardrobe_items';
  static const String hairstyleBox = 'hairstyle_results';
  static const String notificationSettingsBox = 'notification_settings';
  static const String privacySettingsBox = 'privacy_settings';
  static const String subscriptionBox = 'subscription_plan';
  static const String notificationsBox = 'notifications';

  /// Initialize Hive and open all boxes.
  /// On corruption / missing-file errors, wipes the Hive directory and retries once.
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      await _openBoxes();
    } catch (_) {
      // Wipe corrupted files and retry — safe to do on first install
      // or after an OS-level cache eviction (errno 2 / invalidated cache).
      if (!kIsWeb) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final hiveDir = Directory(dir.path);
          if (hiveDir.existsSync()) {
            for (final f in hiveDir.listSync()) {
              if (f.path.endsWith('.hive') || f.path.endsWith('.lock')) {
                f.deleteSync();
              }
            }
          }
        } catch (_) {
          // If we can't clean up, just continue — Hive will recreate files.
        }
      }
      await Hive.close();
      await Hive.initFlutter();
      await _openBoxes();
    }
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<String>(userProfileBox);
    await Hive.openBox<String>(styleAnalysisBox);
    await Hive.openBox<dynamic>(appPreferencesBox);
    await Hive.openBox<dynamic>(onboardingBox);
    await Hive.openBox<String>(wardrobeBox);
    await Hive.openBox<String>(hairstyleBox);
    await Hive.openBox<String>(notificationSettingsBox);
    await Hive.openBox<String>(privacySettingsBox);
    await Hive.openBox<String>(subscriptionBox);
    await Hive.openBox<String>(notificationsBox);
  }

  /// Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    final box = Hive.box<String>(userProfileBox);
    await box.put(profile.id, jsonEncode(profile.toJson()));
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    final box = Hive.box<String>(userProfileBox);
    final data = box.get(userId);
    if (data == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    final box = Hive.box<String>(userProfileBox);
    await box.delete(userId);
  }

  /// Save style analysis
  Future<void> saveStyleAnalysis(StyleAnalysis analysis, String userId) async {
    final box = Hive.box<String>(styleAnalysisBox);
    final key = '${userId}_${analysis.analyzedAt.millisecondsSinceEpoch}';
    await box.put(key, jsonEncode(analysis.toJson()));
  }

  /// Get all style analyses for a user
  Future<List<StyleAnalysis>> getStyleAnalyses(String userId) async {
    final box = Hive.box<String>(styleAnalysisBox);
    final analyses = <StyleAnalysis>[];

    for (final entry in box.toMap().entries) {
      final key = entry.key as String;
      if (key.startsWith(userId)) {
        try {
          final analysis = StyleAnalysis.fromJson(
            jsonDecode(entry.value) as Map<String, dynamic>,
          );
          analyses.add(analysis);
        } catch (e) {
          // Skip malformed entries
        }
      }
    }

    analyses.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    return analyses;
  }

  /// Delete style analysis
  Future<void> deleteStyleAnalysis(String key) async {
    final box = Hive.box<String>(styleAnalysisBox);
    await box.delete(key);
  }

  /// Clear all style analyses
  Future<void> clearAllStyleAnalyses(String userId) async {
    final box = Hive.box<String>(styleAnalysisBox);
    final keysToDelete = <String>[];

    for (final key in box.keys) {
      if ((key as String).startsWith(userId)) {
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Save onboarding answer
  Future<void> saveOnboardingAnswer(String question, String answer) async {
    final box = Hive.box<dynamic>(onboardingBox);
    await box.put(question, answer);
  }

  /// Get onboarding answer
  Future<String?> getOnboardingAnswer(String question) async {
    final box = Hive.box<dynamic>(onboardingBox);
    return box.get(question) as String?;
  }

  /// Get all onboarding answers
  Future<Map<String, dynamic>> getAllOnboardingAnswers() async {
    final box = Hive.box<dynamic>(onboardingBox);
    return Map<String, dynamic>.from(box.toMap());
  }

  /// Clear onboarding answers
  Future<void> clearOnboardingAnswers() async {
    final box = Hive.box<dynamic>(onboardingBox);
    await box.clear();
  }

  /// Save app preference
  Future<void> savePreference(String key, dynamic value) async {
    final box = Hive.box<dynamic>(appPreferencesBox);
    await box.put(key, value);
  }

  /// Get app preference
  Future<dynamic> getPreference(String key, {dynamic defaultValue}) async {
    final box = Hive.box<dynamic>(appPreferencesBox);
    return box.get(key, defaultValue: defaultValue);
  }

  /// Get all preferences
  Future<Map<String, dynamic>> getAllPreferences() async {
    final box = Hive.box<dynamic>(appPreferencesBox);
    return Map<String, dynamic>.from(box.toMap());
  }

  /// Delete preference
  Future<void> deletePreference(String key) async {
    final box = Hive.box<dynamic>(appPreferencesBox);
    await box.delete(key);
  }

  /// Notification settings (per user)
  Future<NotificationSettings> getNotificationSettings(String userId) async {
    final box = Hive.box<String>(notificationSettingsBox);
    final raw = box.get(userId);
    if (raw == null) {
      return NotificationSettings(userId: userId);
    }
    try {
      return NotificationSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return NotificationSettings(userId: userId);
    }
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    final box = Hive.box<String>(notificationSettingsBox);
    await box.put(settings.userId, jsonEncode(settings.toJson()));
  }

  /// Privacy settings (per user)
  Future<PrivacySettings> getPrivacySettings(String userId) async {
    final box = Hive.box<String>(privacySettingsBox);
    final raw = box.get(userId);
    if (raw == null) {
      return PrivacySettings(userId: userId);
    }
    try {
      return PrivacySettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return PrivacySettings(userId: userId);
    }
  }

  Future<void> savePrivacySettings(PrivacySettings settings) async {
    final box = Hive.box<String>(privacySettingsBox);
    await box.put(settings.userId, jsonEncode(settings.toJson()));
  }

  /// Subscription state (per user)
  Future<SubscriptionPlan> getSubscription(String userId) async {
    final box = Hive.box<String>(subscriptionBox);
    final raw = box.get(userId);
    if (raw == null) {
      return SubscriptionPlan(
        id: 'free',
        name: 'Free',
        description: 'Basic plan with daily tips and analysis cap',
        price: 0.0,
        currency: 'USD',
        interval: 'month',
        features: ['3 analyses / month', 'Basic insights'],
        maxAnalyses: 3,
        maxWardrobeItems: 50,
        hasAiEngine: false,
        hasCulturalDb: false,
        hasPrioritySupport: false,
        isActive: true,
      );
    }
    try {
      return SubscriptionPlan.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return SubscriptionPlan(
        id: 'free',
        name: 'Free',
        description: 'Basic plan with daily tips and analysis cap',
        price: 0.0,
        currency: 'USD',
        interval: 'month',
        features: ['3 analyses / month', 'Basic insights'],
        maxAnalyses: 3,
        maxWardrobeItems: 50,
        hasAiEngine: false,
        hasCulturalDb: false,
        hasPrioritySupport: false,
        isActive: true,
      );
    }
  }

  Future<void> saveSubscription(String userId, SubscriptionPlan subscription) async {
    final box = Hive.box<String>(subscriptionBox);
    await box.put(userId, jsonEncode(subscription.toJson()));
  }

  /// Notifications inbox (per user)
  Future<List<notification_model.Notification>> getNotifications(
      String userId) async {
    final box = Hive.box<String>(notificationsBox);
    final raw = box.get(userId);
    if (raw == null) return [];

    try {
      final items = List<Map<String, dynamic>>.from(
          jsonDecode(raw) as List<dynamic>);
      final notifications = items
          .map((json) => notification_model.Notification.fromJson(json))
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotifications(
      String userId, List<notification_model.Notification> notifications) async {
    final box = Hive.box<String>(notificationsBox);
    final payload = notifications.map((n) => n.toJson()).toList();
    await box.put(userId, jsonEncode(payload));
  }

  Future<void> addNotification(
      String userId, notification_model.Notification notification) async {
    final existing = await getNotifications(userId);
    await saveNotifications(userId, [notification, ...existing]);
  }

  Future<void> markNotificationRead(String userId, String notificationId) async {
    final current = await getNotifications(userId);
    final updated = current
        .map((n) => n.id == notificationId ? n.markAsRead() : n)
        .toList();
    await saveNotifications(userId, updated);
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final current = await getNotifications(userId);
    final updated = current.map((n) => n.markAsRead()).toList();
    await saveNotifications(userId, updated);
  }

  Future<int> unreadNotificationCount(String userId) async {
    final notifs = await getNotifications(userId);
    return notifs.where((n) => n.isUnread).length;
  }

  /// Save a wardrobe item
  Future<void> saveWardrobeItem(WardrobeItem item, String userId) async {
    final box = Hive.box<String>(wardrobeBox);
    final key = '${userId}_${item.id}';
    await box.put(key, jsonEncode(item.toJson()));
  }

  /// Get all wardrobe items for a user
  Future<List<WardrobeItem>> getWardrobeItems(String userId) async {
    final box = Hive.box<String>(wardrobeBox);
    final items = <WardrobeItem>[];

    for (final entry in box.toMap().entries) {
      final key = entry.key as String;
      if (key.startsWith(userId)) {
        try {
          final item = WardrobeItem.fromJson(
            jsonDecode(entry.value) as Map<String, dynamic>,
          );
          items.add(item);
        } catch (e) {
          // Skip malformed entries
        }
      }
    }

    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  /// Delete a wardrobe item
  Future<void> deleteWardrobeItem(String itemId, String userId) async {
    final box = Hive.box<String>(wardrobeBox);
    await box.delete('${userId}_$itemId');
  }

  /// Clear all wardrobe items for a user
  Future<void> clearWardrobeItems(String userId) async {
    final box = Hive.box<String>(wardrobeBox);
    final keysToDelete = box.keys
        .cast<String>()
        .where((k) => k.startsWith(userId))
        .toList();
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Save a hairstyle result
  Future<void> saveHairstyleResult(HairstyleResult result) async {
    final box = Hive.box<String>(hairstyleBox);
    await box.put(result.id, jsonEncode(result.toJson()));
  }

  /// Get hairstyle history, newest first
  Future<List<HairstyleResult>> getHairstyleHistory() async {
    final box = Hive.box<String>(hairstyleBox);
    final results = box.values.map((raw) {
      try {
        return HairstyleResult.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<HairstyleResult>().toList();
    results.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    return results;
  }

  /// Clear all boxes
  Future<void> clearAll() async {
    await Hive.box<String>(userProfileBox).clear();
    await Hive.box<String>(styleAnalysisBox).clear();
    await Hive.box<dynamic>(appPreferencesBox).clear();
    await Hive.box<dynamic>(onboardingBox).clear();
    await Hive.box<String>(wardrobeBox).clear();
    await Hive.box<String>(hairstyleBox).clear();
  }
}

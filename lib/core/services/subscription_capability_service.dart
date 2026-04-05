import 'package:styleiq/core/constants/app_constants.dart';
import 'package:styleiq/models/subscription_plan.dart';

class SubscriptionCapabilityService {
  const SubscriptionCapabilityService._();

  static SubscriptionPlan freePlan() {
    return SubscriptionPlan(
      id: 'free',
      name: 'Free',
      description:
          'Local-first style guidance with a small monthly analysis cap.',
      price: 0.0,
      currency: 'USD',
      interval: 'month',
      features: const [
        '3 outfit analyses per month',
        'Wardrobe up to 10 items',
        'Daily tips and local progress',
        'Cultural guide access',
      ],
      maxAnalyses: AppConstants.freeTierAnalysesPerMonth,
      maxWardrobeItems: AppConstants.freeTierWardrobeItems,
      hasAiEngine: true,
      hasCulturalDb: true,
      hasPrioritySupport: false,
      isActive: true,
    );
  }

  static SubscriptionPlan stylePlusPlan() {
    return SubscriptionPlan(
      id: 'style_plus',
      name: 'Style+',
      description: 'Expanded analysis and wardrobe capacity.',
      price: 4.99,
      currency: 'USD',
      interval: 'month',
      features: const [
        '30 outfit analyses per month',
        'Wardrobe up to 50 items',
        '5 hairstyle makeovers per month',
        'Priority processing',
      ],
      maxAnalyses: 30,
      maxWardrobeItems: 50,
      hasAiEngine: true,
      hasCulturalDb: true,
      hasPrioritySupport: false,
      isActive: true,
    );
  }

  static SubscriptionPlan styleProPlan() {
    return SubscriptionPlan(
      id: 'style_pro',
      name: 'Style Pro',
      description: 'Full preview of the planned premium experience.',
      price: 9.99,
      currency: 'USD',
      interval: 'month',
      features: const [
        'Unlimited outfit analyses',
        'Unlimited wardrobe items',
        'Unlimited hairstyle makeovers',
        'Live camera scoring preview',
      ],
      maxAnalyses: null,
      maxWardrobeItems: null,
      hasAiEngine: true,
      hasCulturalDb: true,
      hasPrioritySupport: true,
      isActive: true,
    );
  }

  static List<SubscriptionPlan> catalog() {
    return [freePlan(), stylePlusPlan(), styleProPlan()];
  }

  static bool canAddWardrobeItem(SubscriptionPlan plan, int currentCount) {
    final limit = plan.maxWardrobeItems;
    if (limit == null) return true;
    return currentCount < limit;
  }

  static bool canRunAnalysis(SubscriptionPlan plan, int currentCount) {
    final limit = plan.maxAnalyses;
    if (limit == null) return true;
    return currentCount < limit;
  }

  static int? analysesRemaining(SubscriptionPlan plan, int currentCount) {
    final limit = plan.maxAnalyses;
    if (limit == null) return null;
    return (limit - currentCount).clamp(0, limit);
  }
}

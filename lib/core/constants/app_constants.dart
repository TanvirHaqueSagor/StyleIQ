class AppConstants {
  // Score grades and thresholds
  static const Map<String, int> scoreThresholds = {
    'S': 95,
    'A+': 90,
    'A': 85,
    'B+': 80,
    'B': 75,
    'C+': 70,
    'C': 65,
    'D': 50,
    'F': 0,
  };

  // Dimension weights for overall score calculation
  static const double colorHarmonyWeight = 0.25;
  static const double fitProportionWeight = 0.25;
  static const double occasionMatchWeight = 0.20;
  static const double trendAlignmentWeight = 0.15;
  static const double styleCohesionWeight = 0.15;

  // Free tier limits
  static const int freeTierAnalysesPerMonth = 3;
  static const int freeTierWardrobeItems = 10;

  // Pricing tiers (matches StyleIQ business model)
  static const String pricingFree = 'Free';
  static const String pricingStylePlus = 'Style+'; // $4.99/mo
  static const String pricingStylePro = 'Style Pro'; // $9.99/mo
  static const String pricingFamily = 'Family'; // $14.99/mo

  // Style+ tier limits
  static const int stylePlusMakeoverPerMonth = 5;
  static const int stylePlusWardrobeItems = 50;

  // API configuration
  static const String claudeApiEndpoint =
      'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-sonnet-4-20250514';
  static const int claudeMaxTokens = 4096;

  // FAL.ai image generation — set via environment / api_keys.dart
  static const String falApiKey = String.fromEnvironment('FAL_API_KEY', defaultValue: '');

  // Stripe — set via environment / api_keys.dart
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PK', defaultValue: '');
  static const int claudeTimeoutSeconds = 30;

  // Firebase configuration
  static const String firebaseProjectId = 'styleiq-app';

  // Cultures for cultural guide
  static const List<String> cultures = [
    'Bengali',
    'Indian',
    'Pakistani',
    'Arabic',
    'Japanese',
    'Korean',
    'Nigerian',
    'Western',
    'Chinese',
    'Ethiopian',
  ];

  // Occasions for cultural guide
  static const Map<String, List<String>> culturalOccasions = {
    'Bengali': ['Wedding', 'Eid', 'Puja', 'Formal', 'Festival'],
    'Indian': ['Wedding', 'Diwali', 'Formal', 'Festival', 'Holi'],
    'Pakistani': ['Wedding', 'Eid', 'Formal', 'Festival', 'Mehndi'],
    'Arabic': ['Wedding', 'Eid', 'Formal', 'Hajj', 'Casual'],
    'Japanese': ['Wedding', 'Formal', 'Festival', 'Tea Ceremony', 'Casual'],
    'Korean': ['Wedding', 'Formal', 'Festival', 'Hanbok Occasion', 'Casual'],
    'Nigerian': ['Wedding', 'Festival', 'Formal', 'Traditional', 'Casual'],
    'Western': ['Wedding', 'Formal', 'Casual', 'Business', 'Party'],
    'Chinese': ['Wedding', 'Festival', 'Formal', 'Lunar New Year', 'Casual'],
    'Ethiopian': ['Wedding', 'Festival', 'Formal', 'Traditional', 'Casual'],
  };

  // Onboarding quiz options
  static const List<String> dressCodeOptions = [
    'Casual',
    'Smart Casual',
    'Business',
    'Creative'
  ];

  static const List<String> colorPaletteOptions = [
    'Neutrals',
    'Bold Colors',
    'Pastels',
    'Earth Tones'
  ];

  static const List<String> styleGoalsOptions = [
    'Dress Better Daily',
    'Prepare for Events',
    'Wardrobe Rebuild',
    'Explore New Styles'
  ];

  static const List<String> culturalBackgroundOptions = [
    'South Asian',
    'East Asian',
    'Middle Eastern',
    'African',
    'Western',
    'Other'
  ];

  static const List<String> fashionAdventureOptions = [
    'Classic & Safe',
    'Sometimes Bold',
    'Fashion-Forward'
  ];

  static const List<String> shoppingBudgetOptions = [
    'Budget-Friendly',
    'Mid-Range',
    'Premium',
    'Mixed'
  ];

  static const List<String> styleChallengeOptions = [
    'Color Matching',
    'Finding the Right Fit',
    'Occasion Dressing',
    'Building a Wardrobe'
  ];

  static const List<String> tipsFrequencyOptions = [
    'Daily',
    'Weekly',
    'Only When I Ask'
  ];
}

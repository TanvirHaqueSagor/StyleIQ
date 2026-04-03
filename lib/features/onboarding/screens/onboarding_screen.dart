import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleiq/core/constants/app_constants.dart';
import 'package:styleiq/routes/app_router.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/widgets/styleiq_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;

  /// Page 0 = welcome splash, pages 1–8 = quiz questions
  int _currentPage = 0;
  final Map<String, String?> _answers = {};

  static const _totalPages = 9; // 1 welcome + 8 questions
  static const _questionKeys = [
    'dress_code',
    'color_palette',
    'style_goals',
    'cultural_background',
    'fashion_adventure',
    'shopping_budget',
    'style_challenge',
    'tips_frequency',
  ];

  // ── Question metadata ────────────────────────────────────────────────────
  static const _questions = [
    {
      'emoji': '👔',
      'question': "What's your daily dress code?",
      'key': 'dress_code',
    },
    {
      'emoji': '🎨',
      'question': 'What\'s your preferred color palette?',
      'key': 'color_palette',
    },
    {
      'emoji': '🎯',
      'question': 'What are your style goals?',
      'key': 'style_goals',
    },
    {
      'emoji': '🌍',
      'question': 'What\'s your cultural background?',
      'key': 'cultural_background',
    },
    {
      'emoji': '🚀',
      'question': 'How adventurous are you with fashion?',
      'key': 'fashion_adventure',
    },
    {
      'emoji': '💳',
      'question': 'What\'s your shopping budget?',
      'key': 'shopping_budget',
    },
    {
      'emoji': '🤔',
      'question': 'What\'s your biggest style challenge?',
      'key': 'style_challenge',
    },
    {
      'emoji': '🔔',
      'question': 'How often do you want style tips?',
      'key': 'tips_frequency',
    },
  ];

  static const _optionsByKey = {
    'dress_code': AppConstants.dressCodeOptions,
    'color_palette': AppConstants.colorPaletteOptions,
    'style_goals': AppConstants.styleGoalsOptions,
    'cultural_background': AppConstants.culturalBackgroundOptions,
    'fashion_adventure': AppConstants.fashionAdventureOptions,
    'shopping_budget': AppConstants.shoppingBudgetOptions,
    'style_challenge': AppConstants.styleChallengeOptions,
    'tips_frequency': AppConstants.tipsFrequencyOptions,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────
  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  /// Called when a quiz option is tapped — selects and auto-advances
  void _selectOption(String questionKey, String option) {
    setState(() => _answers[questionKey] = option);

    final isLastQuestion = _currentPage == _totalPages - 1;
    if (!isLastQuestion) {
      Future.delayed(const Duration(milliseconds: 320), () {
        if (mounted) _goTo(_currentPage + 1);
      });
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in _answers.entries) {
        await prefs.setString(entry.key, entry.value ?? '');
      }
      await prefs.setBool('completed_onboarding', true);
      markOnboardingComplete();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your preferences. Please try again.'),
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar (hidden on welcome page)
            if (_currentPage > 0) _buildProgressBar(),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(),
                  ..._questions.map((q) => _buildQuizPage(
                        emoji: q['emoji']!,
                        question: q['question']!,
                        questionKey: q['key']!,
                        options:
                            _optionsByKey[q['key']]!,
                      )),
                ],
              ),
            ),

            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  // ── Welcome splash ───────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo / hero icon
          const StyleIQLogo(size: 100)
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(),
          const SizedBox(height: 32),
          Text(
            'Welcome to StyleIQ',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGrey,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 14),
          Text(
            'Your personal AI fashion analyst.\nLet\'s set up your style profile in 60 seconds.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.mediumGrey,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 40),
          // Feature bullets
          ...[
            ('🎯', 'Personalised outfit scores'),
            ('🌍', 'Cultural dress code guidance'),
            ('✂️', 'Hairstyle recommendations'),
          ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Text(
                      item.$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0)),
        ],
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    final questionIndex = _currentPage - 1; // 0-based among questions
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${questionIndex + 1} of 8',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGrey,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '${((questionIndex + 1) / 8 * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryMain,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (questionIndex + 1) / 8,
              minHeight: 6,
              backgroundColor: AppTheme.lightGrey,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryMain),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quiz page ─────────────────────────────────────────────────────────────
  Widget _buildQuizPage({
    required String emoji,
    required String question,
    required String questionKey,
    required List<String> options,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(emoji, style: const TextStyle(fontSize: 40))
                .animate()
                .scale(duration: 300.ms, curve: Curves.elasticOut),
            const SizedBox(height: 14),
            Text(
              question,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to select',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mediumGrey,
                  ),
            ),
            const SizedBox(height: 28),
            ...List.generate(options.length, (i) {
              final option = options[i];
              final isSelected = _answers[questionKey] == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionTile(
                  label: option,
                  isSelected: isSelected,
                  onTap: () => _selectOption(questionKey, option),
                ),
              )
                  .animate(delay: Duration(milliseconds: 60 * i))
                  .fadeIn(duration: 250.ms)
                  .slideX(begin: 0.05, end: 0);
            }),
          ],
        ),
      ),
    );
  }

  // ── Bottom navigation ─────────────────────────────────────────────────────
  Widget _buildNavigation() {
    final isWelcome = _currentPage == 0;
    final isLastQuestion = _currentPage == _totalPages - 1;
    final currentKey =
        _currentPage > 0 ? _questionKeys[_currentPage - 1] : null;
    final answered = currentKey == null || _answers[currentKey] != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        children: [
          if (!isWelcome)
            IconButton(
              onPressed: () => _goTo(_currentPage - 1),
              icon: const Icon(Icons.arrow_back_ios_new),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.lightGrey,
                foregroundColor: AppTheme.darkGrey,
              ),
            )
          else
            const SizedBox(width: 48),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: answered
                  ? () {
                      if (isWelcome) {
                        _goTo(1);
                      } else if (isLastQuestion) {
                        _completeOnboarding();
                      } else {
                        _goTo(_currentPage + 1);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMain,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.lightGrey,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isWelcome
                    ? 'Get Started'
                    : isLastQuestion
                        ? 'Complete Setup ✓'
                        : 'Next',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Extracted option tile widget ─────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryMain.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryMain : AppTheme.lightGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryMain.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryMain : AppTheme.mediumGrey,
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryMain : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? AppTheme.primaryMain : AppTheme.darkGrey,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

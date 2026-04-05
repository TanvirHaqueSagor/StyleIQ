# StyleIQ — AI-Powered Personal Style Intelligence

StyleIQ is a Flutter mobile app that turns your phone into a personal fashion analyst. Upload an outfit photo and get instant AI-powered style scores, improvement suggestions, hairstyle recommendations, and cultural dress code guidance — all powered by Claude AI.

---

## Features

| Feature | Description |
|---|---|
| **Outfit Analysis** | 5-dimension scoring (Color Harmony, Fit, Occasion Match, Trend, Cohesion) with letter grade |
| **Hairstyle Recommender** | Face shape detection + hair texture analysis → 3–5 tailored hairstyle suggestions |
| **Cultural Dress Guide** | 50+ cultures with occasion-specific garment rules, color meanings, faux pas alerts |
| **Virtual Wardrobe** | Save outfit photos, categorise by type, build a personal clothing inventory |
| **Style DNA Profile** | Onboarding quiz stores preferences used to personalise every analysis |
| **Daily Tips** | Rotating style education cards on the home screen |
| **Community (Preview)** | Browse inspiration and share looks locally in preview mode |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.x (Dart), Material 3 |
| State | Riverpod 2.x |
| Navigation | go_router 13 with StatefulShellRoute |
| Local Storage | Hive + SharedPreferences |
| AI | Anthropic Claude API (claude-sonnet-4) |
| HTTP | Dio 5.x |
| Auth | Firebase Authentication + Google Sign-In |
| Backend (planned) | Node.js + Express on Supabase |
| Payments (planned) | Stripe |

---

## Project Structure

```
styleiq/
├── lib/
│   ├── core/
│   │   ├── constants/         # AppConstants, API keys
│   │   ├── theme/             # AppTheme (colours, gradients, typography)
│   │   ├── utils/             # ImageUtils (compression, base64)
│   │   └── widgets/           # MainScaffold, LoadingShimmer
│   ├── features/
│   │   ├── analysis/          # Home screen, analysis screen, models, services
│   │   ├── cultural_guide/    # 50+ culture guide screen
│   │   ├── makeover/          # Hairstyle recommender screen + models
│   │   ├── onboarding/        # 8-question style quiz
│   │   ├── profile/           # Stats, Style DNA, settings
│   │   └── wardrobe/          # Grid, categories, add/delete items
│   ├── models/                # UserProfile
│   ├── routes/                # app_router.dart (GoRouter config)
│   └── services/
│       ├── api/               # ClaudeApiService
│       ├── auth/              # AuthService (Firebase)
│       └── storage/           # LocalStorageService (Hive)
├── assets/
│   ├── prompts/
│   │   └── style-analyst.txt  # Claude AI system prompt (all modules)
│   ├── images/
│   ├── icons/
│   └── fonts/
└── pubspec.yaml
```

---

## Getting Started

### 1. Prerequisites

- Flutter SDK ≥ 3.3.3
- Dart SDK ≥ 3.3.3
- Xcode 15+ (iOS) / Android Studio (Android)
- An [Anthropic API key](https://console.anthropic.com)

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure API Key

Open `lib/core/constants/api_keys.dart` and set your Anthropic key:

```dart
static const String claudeApiKey = 'YOUR_ANTHROPIC_API_KEY_HERE';
```

> Never commit a real API key. Use environment injection or a `.env` file in production.

### 4. Run the app

```bash
# iOS simulator
flutter run -d iPhone

# Android emulator
flutter run -d android

# Specific device
flutter devices
flutter run -d <device-id>
```

### 5. Run on physical iPhone

1. Open `ios/Runner.xcworkspace` in Xcode
2. Set your Apple Developer Team under Signing & Capabilities
3. Select your device and press Run (⌘R)

---

## Pricing Tiers

| Tier | Price | Analyses/Month | Wardrobe Items | Features |
|---|---|---|---|---|
| Free | $0 | 3 | 10 | Basic analysis, local progress, cultural guide |
| Style+ | $4.99/mo | 30 | 50 | Preview only until billing launches |
| Style Pro | $9.99/mo | Unlimited | Unlimited | Preview only until billing launches |
| Family | $14.99/mo | Unlimited (4 members) | Unlimited | All Style Pro features |

---

## Claude AI Brain

The full system prompt is at `assets/prompts/style-analyst.txt`. It covers 4 modules:

1. **Outfit Analysis** — 5-step pipeline with cultural context detection, weighted scoring, structured JSON output
2. **Hairstyle Module** — Face shape (oval/round/square/heart/oblong/diamond) + hair texture (Andre Walker system 1A–4C)
3. **Cultural Dress Code Module** — Garments, color meanings, faux pas, fusion tips, regional notes
4. **Makeover Module** — Hair, accessories, makeup direction as style exploration

All modules return **raw JSON only** — no markdown, no code blocks.

---

## Key Conventions

- All photos compressed to max **2MB** before API call
- All AI responses are **structured JSON** — parsed into typed Dart models
- `withValues(alpha: x)` not `.withOpacity(x)` (Flutter 3.x)
- `super.key` constructor syntax throughout
- Hive boxes: `analysisBox`, `wardrobeBox` — serialised with `jsonEncode`/`jsonDecode`
- Free tier gate: use `SubscriptionCapabilityService` for analysis and wardrobe limits

---

## Roadmap

- [ ] Firebase Auth integration (login / sign-up screens)
- [ ] Riverpod providers wired to all screens
- [ ] Community screen backed by a real networked feed
- [ ] Supabase backend + cloud sync
- [ ] Stripe payment integration
- [ ] Push notifications for daily style tips
- [ ] Dark mode support
- [ ] Score card image export (share as PNG)

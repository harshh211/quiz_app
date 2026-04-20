# Quiz App

A Flutter quiz app that fetches questions from [QuizAPI.io](https://quizapi.io) and delivers an interactive multiple-choice experience with real-time feedback and scoring.

**Author:** Harshvardhan Kamble
**Course:** Mobile App Development · Activity 15
**Semester:** Spring 2026

## Features

- Fetches 10 programming questions per session from the QuizAPI Questions endpoint
- Shuffled answer order on every question to eliminate positional bias
- Immediate color feedback (green for correct, red for incorrect)
- SnackBar notifications announce correct answer on wrong selections
- Check and cancel icons reinforce the color feedback for accessibility
- Progress bar and live score in the app bar
- Auto-advance after 1.5s so the quiz feels snappy
- Graceful handling of network timeout, no-internet, 401, 429, and malformed-response cases with a Retry action
- Play Again fetches a fresh batch of questions
- HTML entity decoding for clean text rendering

## Project Structure
lib/
├── main.dart               # App entry, theme, validation
├── app_config.dart         # Secure API key access via --dart-define
├── models/
│   └── question.dart       # Question data model with JSON parsing
├── services/
│   └── trivia_service.dart # QuizAPI HTTP client with error handling
└── screens/
├── quiz_screen.dart    # Main quiz UI, state, feedback logic
└── result_screen.dart  # Final score screen with replay

## Running the App

### 1. Get a QuizAPI key

Sign up at [quizapi.io](https://quizapi.io) and copy your API key from the dashboard.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run on a connected device or emulator

```bash
flutter run --dart-define=QUIZ_API_KEY=YOUR_API_KEY
```

The `--dart-define` flag passes the key at compile time without storing it in source code.

### 4. Build a release APK

```bash
flutter build apk --release --dart-define=QUIZ_API_KEY=API_KEY
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Security Notes

- The API key is **never** committed to source. It is injected at build time via `--dart-define` and read by `AppConfig.quizApiKey` using `String.fromEnvironment`.
- `AppConfig.validate()` throws on app startup if the key is missing, so a misconfigured build fails loudly instead of silently at runtime.
- Network calls are guarded by a 10-second timeout and typed exception handling (`TimeoutException`, `SocketException`, `FormatException`) so no failure mode leaves the UI stuck on a spinner.

## Dependencies

| Package | Purpose |
|---|---|
| `http` | REST API requests |
| `html_unescape` | Decode HTML entities in question text |

## Tested On

- Physical Android device, Android 14
- All 20 test cases from the Activity 15 Testing Guide passed — see the Critical Thinking Word document for the full test log.
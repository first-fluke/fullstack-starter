# Mobile Agent - Tech Stack Reference

## Flutter (Recommended)
- **Framework**: Flutter 3.19+
- **Language**: Dart 3.3+
- **State**: Riverpod 2.4+, Bloc, Provider
- **Navigation**: GoRouter 13+
- **API Client**: Dio
- **Local Storage**: Drift, Hive
- **Testing**: flutter_test, mockito
- **E2E Testing**: Maestro

## React Native (Alternative)
- **Framework**: React Native 0.73+
- **Language**: TypeScript
- **State**: Redux Toolkit, Zustand
- **Navigation**: React Navigation 6+
- **Testing**: Jest, React Native Testing Library
- **E2E Testing**: Maestro

## Project Structure (Flutter)

```
lib/
  main.dart
  core/              # Theme, router, utils
  features/
    [feature]/
      data/          # Models, repositories
      domain/        # Entities, use cases
      presentation/  # Screens, widgets, providers
  shared/            # Shared widgets
```

## Architecture Pattern

Clean Architecture with Riverpod:
1. Entity (Domain) - Pure business objects
2. Repository Interface (Domain) - Abstract data access
3. Repository Implementation (Data) - Dio, database
4. Providers (Presentation) - State management
5. Screens/Widgets (Presentation) - UI

## Platform Guidelines
- Material Design 3 for Android
- iOS Human Interface Guidelines for iOS
- Use `Platform.isIOS` for platform-specific code

## Swift (iOS Native)

- **Language**: Swift 5.9+ (Swift 6 compatible)
- **UI Framework**: SwiftUI
- **State Management**: Observation framework (`@Observable`, iOS 17+)
- **API Client**: `swift-openapi-generator` (SwiftPM build plugin) + `swift-openapi-runtime` + `swift-openapi-urlsession`
- **Concurrency**: async/await, structured concurrency
- **Local Storage**: SwiftData, UserDefaults, Keychain
- **Testing**: XCTest, XCUITest

Full reference: `../variants/swift-ios/tech-stack.md`

### Project Layout (App / Core / Features / Shared)

```
Sources/
  App/          # @main entry, composition root, DI wiring
  Core/
    Networking/ # openapi.yaml, generated Client, transport, auth middleware
    Services/   # AuthService, TokenStore, etc.
  Features/     # Vertical slices — one folder per feature (View + @Observable ViewModel)
  Shared/       # Reusable UI components, extensions, utilities
Tests/
```

### Architecture Pattern

```
View (SwiftUI)  ->  @Observable ViewModel  ->  Core Service  ->  Generated Client  ->  Backend
```

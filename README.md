# Touchline Agent

An Android-first football agent simulation game built with Flutter.

## Architecture

```text
lib/
├── app/                 # App bootstrap, routing, and theme
├── application/         # Riverpod controllers and providers
├── core/                # Shared UI and utilities
├── data/
│   ├── database/        # Drift schema and generated SQLite access
│   └── repositories/    # Persistence implementations
├── domain/
│   ├── models/          # Pure game entities
│   ├── repositories/    # Persistence contracts
│   └── services/        # UI-independent game rules/factories
├── simulation/          # Weekly football and agency engines
└── features/            # Feature UI grouped by game section
```

The active career is automatically stored in a single Drift/SQLite autosave
slot after every state-changing action. The main menu reads lightweight save
metadata before loading the complete connected game world.

## Run

```bash
flutter pub get
dart run build_runner build
flutter run
```

## Verify

```bash
flutter analyze
flutter test
flutter build apk --debug
```

# TripNest Admin

TripNest Admin is a Flutter mobile application for managing trip and event-related activities. The app includes onboarding, authentication, event creation, notifications, reviews, sales monitoring, and profile settings in a polished Material-style interface.

## Features

- Onboarding and authentication flow
- Login, sign-up, and password recovery
- Event creation and management
- Home dashboard for key app areas
- Reviews and sales pages
- Notification feed and settings
- Profile management with privacy and security options
- Local storage and notification support

## Tech Stack

- Flutter + Dart
- Material Design UI
- Shared preferences for local persistence
- HTTP client for network requests
- Image picker and image processing support
- Local notifications

## Project Structure

- lib/main.dart: application entry point and route configuration
- lib/src/app_shell.dart: main shell/navigation structure
- lib/src/features/: feature-based screens and pages
- lib/src/core/: shared services, theme, and utilities

## Getting Started

### Prerequisites

- Flutter SDK installed and configured
- A compatible emulator or physical device

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Build for release

```bash
flutter build apk
```

## Notes

The app initializes local storage and notification services on startup and includes air-quality-based notification checks.

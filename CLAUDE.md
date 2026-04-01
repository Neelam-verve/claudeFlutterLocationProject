# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on connected device/emulator
flutter run --verbose        # Run with full logs (useful for debugging)
flutter clean && flutter run # Clean build and run
flutter build apk            # Build Android APK
flutter build ios            # Build iOS
```

No test suite is configured yet. No custom linting beyond default `analysis_options.yaml`.

## Architecture

Flutter child safety app using **GetX** for state management, DI, and routing. Two-role system: `admin` (parent) and `user` (child). Firebase backend (Auth + Firestore, Spark free plan — no Firebase Storage).

### Dependency Injection (main.dart)

All services and controllers are registered globally via `Get.put()` in `_registerServices()` before `runApp()`. Registration order matters — services first, then controllers that depend on them. `LocationController`, `AgoraService`, and `AudioController` are registered with `permanent: true` to survive `Get.offAllNamed()` navigation.

### Auth & Session Flow

App starts at splash screen (`/`). `AuthController` listens to `FirebaseAuth.authStateChanges` and routes automatically:
- Logged in + role `admin` → `/admin-dashboard`
- Logged in + role `user` → `/user-dashboard`
- Not logged in → `/user-login`

Navigation uses `Get.offAllNamed()` which disposes all previous route controllers. The auth listener waits for `Get.context != null` before navigating to avoid contextless navigation errors.

### Location Tracking

`LocationController` uses Geolocator with high accuracy and 10m distance filter. On each position update, it writes `latitude`, `longitude`, and `lastSeen` (server timestamp) to the user's Firestore doc via `LocationFirebaseService`. Admin views use `StreamBuilder` with `FirestoreService.watchUser()` for real-time location updates with auto-camera movement.

### Real-Time Audio Listening (Agora RTC)

Live audio streaming from child to admin using Agora RTC — no audio stored anywhere.

- **AgoraService** (`GetxService`): Wraps `agora_rtc_engine`. Manages RtcEngine lifecycle, channel join/leave. Child joins as broadcaster (uid=2, mic on), admin joins as audience (uid=1, listen only). Channel name = child's Firebase Auth UID. All engine calls are try-catch guarded with null safety on `_engine`.
- **AudioController** (`GetxController`, permanent): Child side watches `isListening` field on own Firestore doc via `FirestoreService.watchIsListening()`. When true, calls `AgoraService.startBroadcasting()`. Admin side has `startListeningToChild(uid)` / `stopListeningToChild(uid)` which update Firestore + join/leave Agora channel. Tracks `listeningToChildUid` for auto-stop on dispose.
- **Agora App ID**: Stored in `lib/core/constants/app_constants.dart`. Testing mode (no token auth).
- **Auto-stop**: `UserDetailScreen.dispose()` calls `audioController.autoStopIfListening()` when admin navigates away.

### Key Patterns

- **Services** (`GetxService`): `AuthService`, `FirestoreService`, `LocationFirebaseService`, `AgoraService` — thin wrappers around SDKs
- **Controllers** (`GetxController`): `AuthController`, `LocationController`, `AudioController`, `AdminController`, `UserController` — business logic with Rx observables
- **Screens**: StatelessWidget or StatefulWidget, access controllers via `Get.find()`
- **Routes**: Defined in `AppRoutes` as static constants, no GetX bindings — controllers are manually managed
- **Stream subscriptions** in controllers must be stored and cancelled in `onClose()` to avoid MethodChannel errors
- **Null safety**: All Agora/Firebase async calls wrapped in try-catch. Guard `mounted` after async gaps in StatefulWidgets. Use `?.` on nullable engine/controller references.

### Firestore Schema

Single `users` collection. Each doc keyed by Firebase Auth UID:
```
{ email, name, role ('admin'|'user'), latitude?, longitude?, lastSeen?, isActive, isListening, agoraChannel }
```

## Platform Config

- **Android**: Google Maps API key in `AndroidManifest.xml` `<meta-data>` tag. Firebase via `google-services.json`. Permissions: `RECORD_AUDIO`, `FOREGROUND_SERVICE_MICROPHONE`, `BLUETOOTH`, `BLUETOOTH_CONNECT`, `MODIFY_AUDIO_SETTINGS`. Background location service with `foregroundServiceType="location"`.
- **iOS**: Location + mic permission strings in `Info.plist`. Background modes: `location`, `fetch`, `audio`, `voip`.
- **Firebase**: Project `location-app-e28a9`. Spark free plan (no Storage).
- **Agora**: App ID in `lib/core/constants/app_constants.dart`. Testing mode (empty token). Free tier: 10,000 min/month.

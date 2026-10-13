# Waypoints iOS — Pending iOS Verification & Deferred Testing Matrix

As decided in the development directive, comprehensive compilation, hardware testing, and TestFlight release validation are reserved for the final release verification phase. This document catalogues every feature requiring verification on a physical iPhone or Xcode environment.

---

## 1. Hardware & Runtime Dependent Features

| Feature | Subsystem | Reason Deferred to Final Phase | Verification Requirement |
|---|---|---|---|
| **Metal / Canvas Rendering** | 3D Interactive Globe | Requires physical Apple GPU or Xcode Metal debugger for frame rate verification | Test 60/120 FPS inertial rotation and pinch zoom on iPhone |
| **Inverse Orthographic Hit-Testing** | Globe Tap-to-Pin | Needs physical touch screen coordinates | Verify pin drops precisely under finger touch on real device |
| **Apple Vision OCR** | `VisionOCRService` | Requires Apple Neural Engine runtime | Run OCR on real physical screenshots from Instagram and TikTok |
| **Apple NaturalLanguage NER** | `NaturalLanguageService` | On-device multilingual language models | Verify tokenization on English, Italian, and Japanese captions |
| **CoreLocation GPS** | `NearbyPlacesView` | Hardware GPS sensor and iOS permissions dialog | Test "Allow Once / While Using" system prompts on physical iPhone |
| **App Group IPC Sandbox** | `WaypointsShare` | Requires iOS security sandboxing and provisioning profiles | Verify Safari share sheet enqueues to `group.com.waypoints.atlas` |
| **Home Screen Widgets** | `WidgetKit` | Widget timeline rendering | Verify `WidgetSnapshot.json` displays on iOS 17 Home Screen |
| **App Shortcuts** | `AppIntents` | Siri and iOS Shortcuts app integration | Verify "Open my Waypoints globe" shortcut voice execution |
| **CloudKit Sync** | `CloudKitSyncService` | Requires active \$99/year Apple Developer CloudKit container | Test cross-device sync once Apple Developer team ID is provisioned |

---

## 2. Compilation & Integration Tests Reserved for Final Stage

1. **XcodeGen Project Generation**:
   - Generate `Waypoints.xcodeproj` from `project.yml` on macOS runner: `xcodegen generate`.
2. **Simulator Test Runner**:
   - Execute `xcodebuild test -scheme Waypoints -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'`.
   - Run complete suite: `CoordinateMathTests`, `CoordinateValidatorTests`, `LinkExtractorTests`, `SocialMetadataTests`, `GeocodingServiceTests`, `AppGroupQueueTests`, `LegacyBackupImportTests`, `MultiLocationExtractionTests`, `TripItineraryTests`, `IntelligentCategorizerTests`, and `WaypointsUITests`.
3. **Provisioning Profiles & Code Signing**:
   - Provisioning App ID `com.waypoints.atlas` and Share Extension `com.waypoints.atlas.ShareExtension`.
   - Deploying signed `.ipa` to TestFlight via GitHub Actions runner.

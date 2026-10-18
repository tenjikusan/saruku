# Waypoints — Engineering Audit & Verification Matrix

**Last Audit:** October 18, 2026  
**Project:** `F:\App\Waypoints_iOS_Native`  
**Active Branch:** `feature/native-expansion`  
**Reference Expo Base:** `F:\App\Waypoints` (Preserved and intact)  

---

## 1. Classification Definitions

- **Implemented**: Full Swift/SwiftUI logic is written in the codebase.
- **Placeholder / Stub**: Scaffolding exists, but returns mock/hardcoded values or redirects to a fallback without executing the advertised service.
- **Compiled on macOS**: Confirmed to compile without errors on Xcode via a macOS runner or physical Mac.
- **Tested**: Verified via automated XCTest suite execution.
- **Device-Verified**: Installed and manually smoke-tested on a physical iPhone.

---

## 2. Feature-by-Feature Engineering Audit Matrix

| Feature Module | Implemented | Placeholder / Stub | Compiled (macOS) | Tested | Device-Verified | Current Status & Notes |
|---|:---:|:---:|:---:|:---:|:---:|---|
| **SwiftUI Tab Navigation** | YES | NO | Pending CI | Pending CI | NO | Implemented in `MainTabView.swift`. Deep linking wired via `DeepLinkRouter`. |
| **Native 3D SceneKit Globe** | YES | NO | Pending CI | NO | NO | Implemented in `SceneKitGlobeView.swift` (3D sphere, lighting, 3D pins, raycast hit-testing). Needs simulator visual check. |
| **Stylized Canvas Globe** | YES | NO | Pending CI | YES | NO | Implemented in `NativeGlobeView.swift`. Spherical projection math verified in `CoordinateMathTests`. |
| **Saved Places & Details** | YES | NO | Pending CI | Pending CI | NO | Implemented in `Place.swift`, `PlaceDetailView.swift`, `EditPlaceSheet.swift`. |
| **Discoveries Intake Inbox** | YES | NO | Pending CI | Pending CI | NO | Implemented in `Discovery.swift`, `DiscoveriesListView.swift`. Supports multi-screenshot files. |
| **URL Coordinate / Place Extraction** | YES | NO | Pending CI | YES | NO | Implemented in `LinkExtractor.swift`. Tested across 11 test cases in `LinkExtractorTests.swift`. |
| **Vision OCR Service** | YES | NO | Pending CI | Pending CI | NO | Implemented in `VisionOCRService.swift`. Uses `VNRecognizeTextRequest`. Requires macOS/iOS simulator to execute Vision framework. |
| **Apple NaturalLanguage Service** | YES | NO | Pending CI | YES | NO | Implemented in `NaturalLanguageService.swift`. Multi-location parsing tested in `MultiLocationExtractionTests.swift`. |
| **Apple Foundation Models** | NO | **YES (STUB)** | Pending CI | NO | NO | **STUB**: `isAvailableOnCurrentDevice` returns `false`; `parseWithFoundationModel` calls NaturalLanguage fallback. Not functional on iOS 17. |
| **Geocoding Engine** | YES | NO | Pending CI | YES | NO | Implemented in `GeocodingEngine.swift` (Photon OSM + LocationIQ fallback). Tested in `GeocodingServiceTests.swift`. |
| **Location Candidate Confirmation** | YES | NO | Pending CI | Pending CI | NO | Implemented in `LocationConfirmationSheet.swift`. Disambiguates multiple candidates before saving. |
| **iOS Share Extension** | YES | NO | Pending CI | Pending CI | NO | Implemented in `ShareViewController.swift` and `ShareExtensionQueue.swift`. Targets configured in `project.yml`. |
| **App Group Intake Queue** | YES | NO | Pending CI | YES | NO | Implemented in `AppGroupShareQueue.swift`. Atomic queue tested in `AppGroupQueueTests.swift`. |
| **SwiftData Schema (7 Models)** | YES | NO | Pending CI | Pending CI | NO | Models: `Place`, `Discovery`, `CollectionModel`, `Trip`, `ItineraryDay`, `ItineraryStop`, `JournalEntry`. Registered in `WaypointsApp`. |
| **Favorites & Visited Status** | YES | NO | Pending CI | Pending CI | NO | Implemented in `FavoritesView.swift`, `VisitedView.swift`, and `Place.swift`. |
| **Collections & Smart Folders** | YES | NO | Pending CI | Pending CI | NO | Implemented in `CollectionsView.swift`. Custom collections + 8 dynamic smart folders based on local SwiftData queries. |
| **Trips & Multi-day Itineraries** | YES | NO | Pending CI | YES | NO | Implemented in `Trip.swift`, `TripDetailView.swift`. Haversine distance and duration tested in `TripItineraryTests.swift`. |
| **Travel Journal & Memories** | YES | NO | Pending CI | Pending CI | NO | Implemented in `JournalListView.swift`, `JournalEntry.swift`. Star ratings, visit dates, image attachments. |
| **Unified Search** | YES | NO | Pending CI | Pending CI | NO | Implemented in `UnifiedSearchView.swift`. Local debounced SwiftData search + worldwide OSM Photon search. |
| **Nearby Places ("Near Me")** | YES | NO | Pending CI | Pending CI | NO | Implemented in `NearbyPlacesView.swift`, `LocationManager.swift`. Single-fix foreground CoreLocation. |
| **Home Screen Widgets (WidgetKit)** | YES | NO | Pending CI | Pending CI | NO | Implemented in `WaypointsWidget/` (4 widgets: Recently Saved, Favorite, Trip, Discoveries). Target added in `project.yml`. |
| **App Intents & App Shortcuts** | YES | NO | Pending CI | Pending CI | NO | Implemented in `WaypointsIntents.swift`. `OpenGlobeIntent`, `OpenFavoritesIntent`, `OpenTripIntent`, `SearchPlacesIntent`. |
| **URL Deep Linking** | YES | NO | Pending CI | Pending CI | NO | Implemented in `DeepLinkRouter.swift` and handled in `MainTabView.swift` via `.onOpenURL`. |
| **CloudKit Sync Service** | YES | **DISABLED** | Pending CI | NO | NO | **DISABLED BY DEFAULT**: Architecture refactored (remote fetch first, pagination, deletion propagation), but sync remains strictly disabled until validated. |
| **Legacy Expo Backup Import** | YES | NO | Pending CI | YES | NO | Implemented in `LegacyBackupImporter.swift`. Backward compatibility tested in `LegacyBackupImportTests.swift`. |
| **Native Backup & Media Archive** | YES | NO | Pending CI | Pending CI | NO | Implemented in `NativeBackupService.swift`. Schema `waypoints.native.v2` with portable base64 image data embedding. |
| **Sandboxed Media Storage** | YES | NO | Pending CI | Pending CI | NO | Implemented in `LocalMediaStorage.swift`. Sandboxed file storage in App Group container `WaypointsMedia/`. |
| **Duplicate Review** | YES | NO | Pending CI | Pending CI | NO | Implemented in `DuplicateReviewView.swift`. Proximity (≤ 200m) and string distance detection. User-controlled merge. |
| **Discovery Cleanup** | YES | NO | Pending CI | Pending CI | NO | Implemented in `DiscoveryCleanupView.swift`. Inbox review, retry failed items, bulk delete. |

---

## 3. Honest Status of Stubbed or Incomplete Modules

1. **Apple Foundation Models (`FoundationModelsService.swift`)**:
   - **Current Reality:** Apple Foundation Models / System Intelligence APIs require Apple Intelligence hardware (iPhone 15 Pro / A17 Pro or M-series) and iOS 18+. The code currently returns `isAvailableOnCurrentDevice = false` and redirects execution to `NaturalLanguageService`.
   - **Classification:** **Placeholder / Stub**. The actual functioning intelligence layer is `NaturalLanguageService` (Apple NaturalLanguage framework).

2. **CloudKit Synchronization (`CloudKitSyncService.swift`)**:
   - **Current Reality:** The service has been architecturally refactored to fetch remote records first, use cursor pagination, and support deletion propagation. However, live multi-device synchronization is untested without an active Apple Developer Team provisioning profile and CloudKit container setup.
   - **Classification:** **Disabled / Untested in Production**. It is strictly disabled by default (`isCloudSyncEnabled = false`). The app operates reliably in local-first mode using SwiftData SQLite.

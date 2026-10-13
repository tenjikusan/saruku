# Waypoints — Native iOS Application

> **Intelligent Location Discovery, Social Media Intake, and Interactive 3D Globe for iPhone**

Waypoints is a native iOS application built purely in **Swift, SwiftUI, SwiftData, Apple Vision, Apple NaturalLanguage, RealityKit, and an iOS Share Extension**. It replaces previous hybrid/web architectures with a native Apple experience.

---

## 🌟 Key Features

1. **Native 3D Interactive Globe**:
   - Orthographic spherical canvas with touch-drag rotation, inertial panning, and pinch zoom.
   - Exact mathematical inverse projection (`unproject`) allowing users to tap anywhere on Earth to drop a waypoint pin with real geographic coordinates.
   - Pin pulse animations and coordinate detail previews.

2. **Apple Native Intelligence (Zero Cloud Privacy Leaks)**:
   - **Apple Vision Framework**: On-device OCR (`VNRecognizeTextRequest`) instantly extracts text and location cues from travel screenshots, Instagram stories, TikTok video frames, and camera photos.
   - **Apple NaturalLanguage**: On-device named entity recognition (`NLTagger`) identifies place names, landmarks, cities, and regions from unstructured captions.
   - **Foundation Models Ready**: Adaptive capability detection for Apple Intelligence on supported hardware (iOS 18+ on A17 Pro/M-series).

3. **Worldwide Location Search (ODbL Compliant)**:
   - Real worldwide geocoding powered by **Photon / OpenStreetMap**.
   - Offline knowledge base with 50+ major destinations for zero-connectivity discovery.
   - In-memory thread-safe LRU caching to minimize network usage.
   - Optional LocationIQ key support for power users.
   - Zero hardcoded mock results masquerading as live searches.

4. **Native iOS Share Extension**:
   - Share directly into Waypoints from Safari, Instagram, TikTok, YouTube, Maps, and Twitter/X.
   - Inter-process communication via **App Groups** (`group.com.waypoints.atlas`).
   - Atomic file queue drains pending shares upon main app foregrounding.

5. **Strict Geospatial Data Integrity (SwiftData)**:
   - Absolute prevention of **Null Island** coercion: missing, null, or empty coordinates are never coerced to `(0, 0)`.
   - Every coordinate tracks its explicit `CoordinateProvenance` (`verifiedLink`, `geocodedResult`, `globeTap`, `userEntry`, or `demoData`).
   - Lossless import/export support for both legacy `vaypoints.backup.v1` and native `waypoints.native.v1` formats.

---

## 📁 Repository Structure

```
Waypoints_iOS_Native/
├── .github/
│   └── workflows/
│       ├── ios-build.yml            # Cloud macOS CI: XcodeGen, simulator build, test runner
│       └── testflight-release.yml   # Automated TestFlight cloud distribution
├── project.yml                      # Declarative XcodeGen project specification
├── Waypoints/
│   ├── App/
│   │   └── WaypointsApp.swift       # @main entry point, SwiftData container, App Group intake
│   ├── Models/
│   │   ├── Place.swift              # SwiftData @Model for saved waypoints
│   │   ├── Discovery.swift          # SwiftData @Model for incoming discoveries & candidates
│   │   ├── CollectionModel.swift    # SwiftData @Model for user collections
│   │   ├── CoordinateProvenance.swift
│   │   ├── LocationCandidate.swift
│   │   └── SchemaMigrationPlan.swift
│   ├── Services/
│   │   ├── Geospatial/              # CoordinateValidator & CoordinateMath (orthographic)
│   │   ├── Geocoding/               # Photon OSM, OfflineKnowledge, LRU GeocodingEngine
│   │   ├── DiscoveryEngine/         # ContentClassifier, LinkExtractor, SocialMetadata
│   │   ├── Intelligence/            # VisionOCRService, NaturalLanguageService, FoundationModels
│   │   ├── Sharing/                 # AppGroupShareQueue (IPC queue)
│   │   └── Backup/                  # LegacyBackupImporter, NativeBackupService
│   ├── Views/
│   │   ├── Navigation/              # MainTabView
│   │   ├── Globe/                   # NativeGlobeView, GlobeScreenView
│   │   ├── Discoveries/             # DiscoveriesListView, LocationConfirmationSheet, AddDiscoverySheet
│   │   ├── Places/                  # PlacesListView, PlaceDetailView, EditPlaceSheet
│   │   ├── Collections/             # CollectionsView, CollectionDetailView
│   │   ├── Favorites/               # FavoritesView
│   │   ├── Visited/                 # VisitedView (Travel passport)
│   │   ├── Settings/                # SettingsView, BackupRestoreView
│   │   └── Theme/                   # Colors, Typography, UIComponents
│   ├── Resources/
│   │   └── Assets.xcassets          # AppIcon, AccentColor (#244B3B Deep Forest)
│   ├── Entitlements/
│   └── Info.plist
├── WaypointsShare/                  # Native iOS Share Extension
│   ├── ShareViewController.swift
│   ├── ShareExtensionQueue.swift
│   ├── Entitlements/
│   └── Info.plist
├── WaypointsTests/                  # Comprehensive Unit Test Suite
│   ├── CoordinateMathTests.swift
│   ├── CoordinateValidatorTests.swift
│   ├── LinkExtractorTests.swift
│   ├── SocialMetadataTests.swift
│   ├── GeocodingServiceTests.swift
│   ├── AppGroupQueueTests.swift
│   └── LegacyBackupImportTests.swift
├── WaypointsUITests/                # Automated UI Test Suite
│   └── WaypointsUITests.swift
└── Docs/                            # Full Documentation Suite
```

---

## 🛠️ Building & Developing

See [Docs/DEVELOPMENT_ON_WINDOWS.md](file:///F:/App/Waypoints_iOS_Native/Docs/DEVELOPMENT_ON_WINDOWS.md) and [Docs/CLOUD_IOS_BUILD.md](file:///F:/App/Waypoints_iOS_Native/Docs/CLOUD_IOS_BUILD.md) for full instructions on developing on Windows and compiling via GitHub Actions macOS runners.

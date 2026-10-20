# Waypoints — Native Apple iOS Application

Waypoints is a native iPhone location discovery and bookmarking app built with Swift, SwiftUI, SwiftData, and SceneKit.

## Project Structure

```
waypoints apple/
├── Waypoints/             # Main iOS App (SwiftUI Views, SwiftData Models, Services, Intents)
│   ├── App/               # App Lifecycle & SwiftData ModelContainer
│   ├── Models/            # SwiftData Models (Place, Discovery, Trip, JournalEntry, etc.)
│   ├── Services/          # Discovery Engine, Geocoding, Vision OCR, NaturalLanguage
│   ├── Views/             # UI (Globe, Places, Trips, Collections, Journal, Search, Settings)
│   └── Entitlements/      # App Groups & CloudKit Entitlements
├── WaypointsShare/        # Native iOS Share Extension (Share URLs/Images to Waypoints)
├── WaypointsWidget/       # WidgetKit Extension (Home Screen Widgets)
├── WaypointsTests/        # Automated Unit Tests
├── WaypointsUITests/      # UI Integration Tests
├── .github/workflows/     # CI/CD Workflows (Unsigned Simulator Build & Test)
├── project.yml            # XcodeGen Project Definition
└── README.md
```

## Technology Stack

- **Platform:** iOS 17.0+ (iPhone)
- **Language:** Swift 5.9
- **UI & Graphics:** SwiftUI, SceneKit (3D GPU Earth Globe), SwiftUI Canvas (Cartographic Projection)
- **Local Persistence:** SwiftData (SQLite)
- **On-Device Intelligence:** Apple Vision Framework (`VNRecognizeTextRequest`), Apple NaturalLanguage (`NLTagger`)
- **Extensions:** WidgetKit, iOS Share Extension, AppIntents
- **Build System:** XcodeGen (`project.yml`) for clean source-controlled project generation

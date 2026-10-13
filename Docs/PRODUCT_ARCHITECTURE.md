# Waypoints iOS — Product Architecture Specification

## 1. Architectural Overview

Waypoints is an on-device-first native iOS application built purely in **Swift 5.9, SwiftUI, SwiftData, and Apple's native framework ecosystem**. The architecture decouples data intake, machine learning inference, geospatial indexing, and UI rendering into independent, testable subsystems:

```
+-------------------------------------------------------------------------------------------------+
|                                        APPLICATION UI (SwiftUI)                                 |
|  MainTabView                                                                                    |
|  ├── GlobeScreenView (3D Earth, Explore / Tap-to-Pin / Trip Focus Modes)                        |
|  ├── DiscoveriesListView (Inbox, Batch Import, Multi-Location Selection Sheet)                  |
|  ├── PlacesListView & PlaceDetailView (Waypoint Details, Photos Gallery, Content Sources)       |
|  ├── CollectionsView (Custom Collections, Smart Filters, Trips & Plans)                         |
|  └── SettingsView (Geocoding Controls, Duplicate Review, Cleanup, Journal, Near Me, Backups)    |
+-------------------------------------------------------------------------------------------------+
                                                 │
                                                 ▼
+-------------------------------------------------------------------------------------------------+
|                                     DISCOVERY ENGINE PIPELINE                                   |
|  DiscoveryPipeline                                                                              |
|  ├── LinkExtractor (Google bang !3d/!4d, Apple Maps ll=, OSM, CamelCase Hashtags)               |
|  ├── SocialMetadataService (YouTube oEmbed, OpenGraph, Login-wall disclosures)                  |
|  └── ContentClassifier (Link / Image / Unstructured Text Detection)                             |
+-------------------------------------------------------------------------------------------------+
        │                                        │                                       │
        ▼                                        ▼                                       ▼
+────────────────────────+             +────────────────────────+             +───────────────────+
|   APPLE NATIVE AI      |             |   GEOLOCATION ENGINE   |             |  DURABLE STORAGE  |
| - Vision OCR (Text)    |             | - Photon OpenStreetMap |             | - LocalMedia-     |
| - NaturalLanguage NER  |             | - Offline Knowledge    |             |   Storage (Disk)  |
| - Multi-Location List  |             | - Thread-Safe LRU Cache|             | - ImageMetadata-  |
| - Intelligent Category |             | - Strict Coordinate-   |             |   Extractor (EXIF)|
| - Foundation Models    |             |   Validator (No Null-  |             | - App Group Share |
|   Readiness            |             |   Island Coercion)     |             |   Queue (IPC)     |
+────────────────────────+             +────────────────────────+             +───────────────────+
                                                 │
                                                 ▼
+-------------------------------------------------------------------------------------------------+
|                                    PERSISTENCE & DATA LAYER                                     |
|  SwiftData ModelContainer:                                                                      |
|  Place • Discovery • CollectionModel • Trip • ItineraryDay • ItineraryStop • JournalEntry       |
+-------------------------------------------------------------------------------------------------+
```

---

## 2. Core Subsystems

### A. Discovery Engine
- **Intake**: Accommodates raw links (Safari, Instagram, YouTube, TikTok, X, Maps), copied text descriptions, camera screenshots, and App Group Share Extension items.
- **Multi-Location Resolution**: Unlike naive parsers that assume a post references only a single destination, the pipeline extracts lists, bulleted destinations, and comma-separated itineraries into distinct location candidates.
- **Idempotence**: Every discovery produces stable candidate identifiers (`place_\(discovery.id)_\(index)`) ensuring repeated taps or network retries never duplicate pins in SwiftData.

### B. Geospatial Mathematics & 3D Globe
- **Projection**: Forward orthographic projection mapping spherical coordinates \((\phi, \lambda)\) into 2D viewport coordinates.
- **Inverse Projection (`unproject`)**: Touch coordinate hit-testing calculates exact inverse trigonometry:
  \[
  \rho = \sqrt{x^2 + y^2}, \quad c = \arcsin\left(\frac{\rho}{R}\right)
  \]
  recovering latitude and longitude with \(\le 0.001^\circ\) accuracy.
- **3 Modes**:
  - `Explore`: Smooth rotation and inspecting all saved waypoints.
  - `Tap to Pin`: Crosshair hit-testing to place manual pins anywhere on Earth.
  - `Trip Focus`: Filters and focuses exclusively on destinations within a selected trip or collection.

### C. Durable Image Architecture
- High-resolution user photographs and travel screenshots are never stored as binary data blobs inside SwiftData SQLite records (which would cause database bloat and memory pressure).
- `LocalMediaStorage` writes compressed JPEGs to the shared App Group filesystem (`WaypointsMedia/`), storing only lightweight relative file strings inside `@Model` records.

### D. Trips and Itineraries
- Hierarchical relationship: `Trip` \(\rightarrow\) `ItineraryDay` \(\rightarrow\) `ItineraryStop`.
- Consecutive stop distance tracking computed via real mathematical **Haversine formula**, avoiding fabricated AI transit times.
- Independent completion tracking: marking an itinerary stop completed does not overwrite the general visited status of the underlying saved place.

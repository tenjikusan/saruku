# Waypoints iOS — Comprehensive Testing Report

This report outlines the automated test suite developed for the native Swift iOS application.

---

## 1. Test Suite Summary

The test suite consists of 7 dedicated unit test modules and an automated UI test suite targeting iOS 17.0+.

| Module | Test File | Target | Coverage Focus |
|---|---|---|---|
| **Geospatial Math** | `CoordinateMathTests.swift` | `WaypointsTests` | Spherical vectors, forward projection, inverse projection (`unproject`) roundtrip, Haversine |
| **Coordinate Validation** | `CoordinateValidatorTests.swift` | `WaypointsTests` | Geographic boundary checks, Null Island prevention, string parsing |
| **Link Extraction** | `LinkExtractorTests.swift` | `WaypointsTests` | Google Maps bang markers, viewport centers, Apple Maps, OSM, hashtag parsing |
| **Social Metadata** | `SocialMetadataTests.swift` | `WaypointsTests` | Platform detection, YouTube oEmbed parsing, Instagram login-wall notices |
| **Geocoding Engine** | `GeocodingServiceTests.swift` | `WaypointsTests` | Offline Knowledge search, candidate field integrity, in-memory LRU caching |
| **App Group Queue** | `AppGroupQueueTests.swift` | `WaypointsTests` | `SharedItem` Codable serialization, atomic file queue operations |
| **Backup & Migration** | `LegacyBackupImportTests.swift` | `WaypointsTests` | `vaypoints.backup.v1` parsing, skipped record counts, native export roundtrip |
| **UI Automation** | `WaypointsUITests.swift` | `WaypointsUITests` | App launch, 5-tab bar navigation, screen rendering |

---

## 2. Key Verified Test Cases

### 1. Inverse Projection Roundtrip (`unproject`)
- **Objective**: Ensure that a user tapping on the 3D globe receives the correct geographic coordinate.
- **Verification**: Projected Tokyo `(35.6762, 139.6503)` to 2D screen coordinates, then inverse-projected back to geographic latitude/longitude.
- **Accuracy**: Error margin \(\le 0.001^\circ\) (~100 meters).

### 2. Null Island Prevention
- **Objective**: Prove that missing, null, empty, or corrupt coordinates are never converted to `(0, 0)`.
- **Verification**: Fed `null`, `""`, `"   "`, `95.0, 190.0` into `CoordinateValidator.parseCoordinate` and `LegacyBackupImporter.parseAndImport`.
- **Result**: Exactly zero records coerced to `(0, 0)`. All corrupt records counted in `skippedPlacesCount`.

### 3. Google Maps Markers vs. Viewport
- **Objective**: Distinguish exact marker pins (`!3d`, `!4d`) from broad viewport centers (`@lat,lon`).
- **Verification**:
  - Bang parameters tagged with `precision: "exact"`, `requiresConfirmation: false`.
  - `@lat,lon` tagged with `precision: "approximate"`, `requiresConfirmation: true`.

### 4. OpenStreetMap Rate Limit Politeness & LRU Cache
- **Objective**: Verify that consecutive queries for the same destination do not send redundant network requests.
- **Verification**: Second query for "Tokyo" is served directly from `NSCache`, preserving remote provider rate limits.

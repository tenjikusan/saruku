# Waypoints iOS — Architectural Specification

## 1. Architectural Philosophy

Waypoints is engineered as a privacy-first, on-device-first native iOS application. Rather than sending user notes, photos, and travel bookmarks to unvetted third-party backend servers, the application leverages Apple's on-device silicon capabilities and open geospatial standards.

```
+-----------------------------------------------------------------------+
|                             USER INTERFACE                            |
|  MainTabView (SwiftUI)                                               |
|  ├── 3D Canvas Globe View (Orthographic Projection & Unprojection)   |
|  ├── Discoveries Inbox & Location Confirmation Workflow              |
|  ├── Waypoints & Collections Explorer (SwiftData @Query)             |
|  └── Settings & Lossless Backup Management                           |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                           DISCOVERY ENGINE                            |
|  DiscoveryPipeline                                                    |
|  ├── LinkExtractor (Google bang !3d/!4d, Apple Maps, OSM, Hashtags)  |
|  ├── SocialMetadataService (YouTube oEmbed, OpenGraph, Login Notice)  |
|  └── ContentClassifier (Link / Image / Text classifier)              |
+-----------------------------------------------------------------------+
           |                                              |
           v                                              v
+---------------------------+                +--------------------------+
|  APPLE ON-DEVICE ML       |                |  GEOLOCATION ENGINE      |
|  - Vision OCR             |                |  - Photon OSM Geocoder   |
|  - NaturalLanguage NER    |                |  - Offline Knowledge Base|
|  - Foundation Models Ready|                |  - In-Memory LRU Cache   |
+---------------------------+                +--------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                         PERSISTENCE & STORAGE                         |
|  SwiftData ModelContainer (Place, Discovery, CollectionModel)         |
|  App Group IPC Queue (SharedItem JSON queue via group.com.waypoints)  |
+-----------------------------------------------------------------------+
```

---

## 2. Geospatial Mathematics & Interactive 3D Globe

### Forward Orthographic Projection
The 3D globe simulates an Earth sphere viewed from space at an infinite distance (orthographic projection).
Given a point at latitude \(\phi\) and longitude \(\lambda\), centered at \((\phi_0, \lambda_0)\):

\[
c = \sin\phi_0 \sin\phi + \cos\phi_0 \cos\phi \cos(\lambda - \lambda_0)
\]

If \(c \ge 0\), the point is on the visible front hemisphere:
\[
x = R \cos\phi \sin(\lambda - \lambda_0)
\]
\[
y = R (\cos\phi_0 \sin\phi - \sin\phi_0 \cos\phi \cos(\lambda - \lambda_0))
\]

### Inverse Orthographic Projection (`unproject`)
To support manual tap-to-pin, when the user touches pixel coordinates \((x, y)\) relative to the globe disk center of radius \(R\):
\[
\rho = \sqrt{x^2 + y^2}
\]
If \(\rho > R\), the tap falls outside the Earth disk and is rejected.
Otherwise:
\[
c = \arcsin\left(\frac{\rho}{R}\right)
\]
\[
\phi = \arcsin\left(\cos c \sin\phi_0 + \frac{y \sin c \cos\phi_0}{\rho}\right)
\]
\[
\lambda = \lambda_0 + \arctan2\left(x \sin c, \rho \cos\phi_0 \cos c - y \sin\phi_0 \sin c\right)
\]

This allows the user to rotate the globe to any angle and accurately drop a pin on any geographic feature with mathematical precision.

---

## 3. Data Schema & SwiftData Design

### `Place`
- `id`: String (UUID)
- `name`: String
- `country`: String
- `latitude`: Double (strictly validated in `[-90, 90]`)
- `longitude`: Double (strictly validated in `[-180, 180]`)
- `precision`: String (`"exact"` or `"approximate"`)
- `provenanceRaw`: String (`CoordinateProvenance`)
- `sourceURL`: Optional String
- `note`: String
- `isFavorite`: Bool
- `isVisited`: Bool
- `theme`: String
- `source`: String
- `evidence`: String
- `discoveryId`: Optional String
- `collections`: Relationship to `[CollectionModel]`

### `Discovery`
- `id`: String
- `originalURL`: String
- `caption`: String
- `collectionName`: String
- `statusRaw`: String (`DiscoveryStatus`)
- `statusMessage`: String
- `candidatesJSON`: Serialized JSON array of `[LocationCandidate]`
- `selectedCandidateJSON`: Serialized JSON for chosen candidate
- `evidenceJSON`: Serialized JSON array of evidence strings
- `confirmedPlaceId`: Optional String linking to created `Place`

### Prevention of Null Island
A fatal bug in geospatial databases is coercing `nil`, `""`, or failed parses into `0.0, 0.0` (an arbitrary buoy location off the coast of Ghana known as "Null Island").
Waypoints strictly enforces:
1. `CoordinateValidator.isValidCoordinate` requires finite bounds `[-90, 90]` and `[-180, 180]`.
2. Any candidate or imported record lacking a valid number is marked as unlocated or skipped.
3. Zero coordinates are never inferred from empty strings.

---

## 4. On-Device Apple Intelligence

### Apple Vision OCR
- Uses `VNRecognizeTextRequest` with `.accurate` recognition level.
- Runs directly on Apple Neural Engine / GPU with zero network calls.
- Parses travel itineraries, screenshots of map pins, and social media captions.

### Apple NaturalLanguage
- Uses `NLTagger` with `.placeName` and `.organizationName` tags.
- Identifies geographical entities in multilingual text and user notes.

---

## 5. Share Extension & Inter-Process Communication

- The iOS Share Extension runs in a distinct sandbox with a 120MB memory limit.
- Main app and Share Extension communicate through the **App Group** `group.com.waypoints.atlas`.
- Queue file: `WaypointsShareQueue.json` inside the shared container.
- Synchronization is protected using POSIX atomic writes and file locks.
- Main app automatically drains and ingests pending shared links upon entering `.active` scene phase.

# Geospatial Data Migration & Integrity Strategy

This document describes how Waypoints safely imports and migrates data from the legacy Expo/JavaScript implementation (`vaypoints.backup.v1`) to the native SwiftData architecture (`waypoints.native.v1`).

---

## 1. The Core Principle: Preserving Provenance and Preventing Corruption

Legacy web and hybrid geocoding tools frequently suffered from two catastrophic failure modes:
1. **Null Island Coercion**: Converting `null`, `undefined`, or `""` coordinates into `(0.0, 0.0)`.
2. **Loss of Source Provenance**: Losing whether a coordinate was an exact pin from a map marker, an approximate city center, or a manual tap.

Waypoints completely resolves both issues.

---

## 2. Legacy Backup Format (`vaypoints.backup.v1`)

The legacy format structured records as follows:
```json
{
  "version": "vaypoints.backup.v1",
  "exportedAt": "2026-10-13T12:00:00.000Z",
  "data": {
    "places": [
      {
        "id": "place_123",
        "name": "Eiffel Tower",
        "country": "France",
        "lat": 48.8584,
        "lon": 2.2945,
        "precision": "exact",
        "provenance": "verified_link",
        "isFavorite": true,
        "visited": false,
        "url": "https://maps.apple.com/?ll=48.8584,2.2945"
      }
    ],
    "discoveries": [ ... ]
  }
}
```

---

## 3. Strict Validation and Skipped Record Reporting

`LegacyBackupImporter.swift` enforces strict type checking:
1. **Name Validation**: Places with missing or whitespace-only names are skipped.
2. **Coordinate Validation**:
   - `lat` and `lon` (or `latitude` and `longitude`) must exist and not be `NSNull`.
   - Must be valid floating-point numbers within `[-90, 90]` and `[-180, 180]`.
   - Any record failing coordinate bounds is skipped, NOT coerced to 0,0.
3. **Skipped Record Accounting**:
   - Returns a structured `LegacyImportResult` reporting exact counts of imported vs. skipped records.
   - The user is shown a detailed alert indicating how many invalid items were safely skipped.

---

## 4. Import Modes

Users can select between two modes in `BackupRestoreView`:
- **Merge Mode (Default)**: Keeps all existing local waypoints, discoveries, and collections. Adds new valid items from the backup.
- **Replace Mode**: Atomically replaces the current database with the backup content after user confirmation.

---

## 5. Native Format (`waypoints.native.v2`)

The native format exported by `NativeBackupService.swift` includes:
- Schema version: `waypoints.native.v2`
- Full `Place` models including `CoordinateProvenance` and linked collection references.
- Full `Discovery` models with serialized candidate lists and evidence records.
- Complete `CollectionModel` entities with custom SF Symbols and hex color codes.
- Multi-day `Trip` entities with `ItineraryDay` and `ItineraryStop` records.
- `JournalEntry` records with visit dates and star ratings.
- Portable base64 media attachment dictionary.

---

## 6. Verification Status

> [!NOTE]
> Backward-compatibility parsing of legacy Expo `vaypoints.backup.v1` records has been verified via unit tests in `LegacyBackupImportTests.swift`.
> However, **bidirectional cross-platform backup compatibility** (importing native v2 backups back into the Expo app, and roundtrip data preservation) remains **untested in both directions** and will be verified after the first stable iOS build.

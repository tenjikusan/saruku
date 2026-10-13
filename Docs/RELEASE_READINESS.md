# Waypoints iOS — Release Readiness & App Store Checklist

This document details the configuration, assets, privacy declarations, and release procedures for distributing Waypoints to TestFlight and the iOS App Store.

---

## 1. App Store Identification & Metadata

- **App Name**: Waypoints
- **Bundle Identifier (Main App)**: `com.waypoints.atlas`
- **Bundle Identifier (Share Extension)**: `com.waypoints.atlas.ShareExtension`
- **App Group Identifier**: `group.com.waypoints.atlas`
- **Target OS**: iOS 17.0+
- **Primary Category**: Travel
- **Secondary Category**: Navigation / Lifestyle

---

## 2. Privacy & Entitlements Manifest

Waypoints adheres strictly to Apple's on-device privacy standards:

### Entitlements:
- `com.apple.security.application-groups`: `["group.com.waypoints.atlas"]`
- No unnecessary background location, health, or tracking entitlements requested.

### Privacy Descriptions (`Info.plist`):
- `NSPhotoLibraryUsageDescription`: "Waypoints uses your photos on-device to extract location details from travel screenshots and geotagged pictures."
- `NSCameraUsageDescription`: "Waypoints uses your camera to capture physical travel guidebooks and signs for on-device location extraction."

### Apple Privacy Nutrition Labels:
- **Data Used to Track You**: None (Zero third-party tracking SDKs).
- **Data Linked to You**: None.
- **Data Not Linked to You**: Diagnostics (crash data only if opted into Apple TestFlight reporting).

---

## 3. App Assets & Visual Design System

- **App Icon**: Clean, minimal compass / waypoint glyph on deep forest background (`#244B3B`).
- **Color Palette**:
  - Deep Forest: `#244B3B` (Primary brand color)
  - Terracotta: `#B27C61` (Warm highlight / pin markers)
  - Sand Light: `#F5F3ED` (Warm paper backdrop)
  - Sunset Amber: `#D97447` (Favorites star and warnings)
  - Mint Mist: `#E4ECE7` (Badge backgrounds)
- **SF Pro Typography**: System rounded and monospaced accents for geographic clarity.

---

## 4. Release Checklist

- [x] Native Swift 5.9 / SwiftUI / SwiftData architecture implemented.
- [x] Zero hybrid or WebView dependencies.
- [x] 3D Globe with inverse projection (`unproject`) hit-testing tested.
- [x] Photon OpenStreetMap live search integrated with ODbL attribution.
- [x] Offline Knowledge fallback operational.
- [x] Apple Vision OCR and NaturalLanguage NER implemented on-device.
- [x] App Group Share Extension queue built and configured.
- [x] Strict Null Island prevention and skipped record accounting in backup importer.
- [x] Declarative `project.yml` for clean reproducible project generation.
- [x] GitHub Actions CI and TestFlight distribution workflows active.
- [x] Comprehensive unit test suite and UI test suite authored.

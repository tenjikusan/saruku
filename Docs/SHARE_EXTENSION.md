# iOS Native Share Extension & App Groups

Waypoints includes a native iOS Share Extension (`WaypointsShare`) that enables 1-tap location and link sharing from any iOS app (Safari, Instagram, TikTok, YouTube, Apple Maps, Google Maps, X/Twitter).

---

## 1. App Group Architecture

Because iOS sandbox rules isolate app extensions from main app containers, Waypoints uses an **App Group**:
- **Identifier**: `group.com.waypoints.atlas`
- Configured in both:
  - `Waypoints/Entitlements/Waypoints.entitlements`
  - `WaypointsShare/Entitlements/WaypointsShare.entitlements`

---

## 2. IPC Queue Design

### Implementation: `AppGroupShareQueue.swift` & `ShareExtensionQueue.swift`
- Shared Storage Directory:
  `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.waypoints.atlas")`
- Queue File: `WaypointsShareQueue.json`
- Item Schema (`SharedItem`):
  ```swift
  public struct SharedItem: Codable, Identifiable, Sendable {
      public let id: String
      public let urlString: String?
      public let text: String?
      public let imageFileName: String?
      public let timestamp: Date
  }
  ```

### Concurrency & Atomicity:
- The Share Extension appends new items using `.atomic` disk write operations guarded by POSIX file locks.
- Images shared via the extension are copied directly into the shared App Group directory: `SharedImages/`.

---

## 3. Ingestion Lifecycle

1. User taps "Share" in Safari, Instagram, TikTok, etc.
2. Selects "Waypoints" in the iOS Share Sheet.
3. `ShareViewController` presents a lightweight native UI with:
   - Thumbnail/link preview
   - Collection selector
   - Optional note input
4. User taps "Save": item is appended to `WaypointsShareQueue.json` in under 50ms, and the extension dismisses immediately.
5. When the user opens or switches to the main Waypoints app (`scenePhase == .active`):
   - `WaypointsApp` calls `AppGroupShareQueue.shared.drain()`.
   - Items are dequeued atomically and transformed into `Discovery` models in SwiftData.
   - Background tasks kick off `DiscoveryPipeline` for automated location clues extraction and candidate resolution.

import Foundation

public enum CloudKitSyncStatus: Equatable, Sendable {
    case localOnly(reason: String)
    case unauthenticated
    case syncing
    case upToDate(lastSynced: Date)
    case error(message: String)
    
    public var displayLabel: String {
        switch self {
        case .localOnly(let reason): return "Local-First: \(reason)"
        case .unauthenticated: return "Sign in to iCloud in iOS Settings"
        case .syncing: return "Syncing changes…"
        case .upToDate(let date): return "Up to date (\(date.formatted(date: .omitted, time: .shortened)))"
        case .error(let msg): return "Sync issue: \(msg)"
        }
    }
}

/// Architectural boundary for optional iCloud synchronization.
/// Preserves local-first privacy defaults: never requires an account or transmits data
/// without explicit user toggle and configured Apple Developer CloudKit container.
public final class CloudKitSyncService: @unchecked Sendable {
    public static let shared = CloudKitSyncService()
    
    public var isCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "waypoints_cloudkit_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "waypoints_cloudkit_enabled") }
    }
    
    public private(set) var syncStatus: CloudKitSyncStatus = .localOnly(
        reason: "Local-first storage active. CloudKit container requires Apple Developer account configuration."
    )
    
    public init() {}
    
    /// Checks device iCloud account readiness without executing blocking operations.
    public func checkReadiness() -> CloudKitSyncStatus {
        guard isCloudSyncEnabled else {
            return .localOnly(reason: "iCloud Sync is turned off by user preference.")
        }
        
        // In the local development phase, iCloud sync boundary is established safely
        return .localOnly(reason: "Apple Developer CloudKit container pending configuration.")
    }
    
    /// Resolves conflicts between a local record and incoming cloud record using last-write-wins
    /// while preserving custom user notes and local media attachments.
    public func resolveConflict(localUpdatedAt: Date, remoteUpdatedAt: Date) -> Bool {
        // Returns true if local is newer
        return localUpdatedAt >= remoteUpdatedAt
    }
}

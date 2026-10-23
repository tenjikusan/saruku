import Foundation

/// Explicit provenance tracking for all geographic coordinates in Waypoints.
/// Never obscures demo data or unverified inferences.
public enum CoordinateProvenance: String, Codable, CaseIterable, Sendable {
    /// Exact marker bang parameter from a verified map link (e.g. Google Maps !3d/!4d, OSM marker)
    case verifiedLink = "verified_link"
    
    /// Result returned by an authoritative, licensed geocoding provider (Photon / LocationIQ)
    case geocodedResult = "geocoded_result"
    
    /// User tapped directly on the interactive 3D globe using inverse orthographic projection
    case globeTap = "globe_tap"
    
    /// Manually typed or adjusted coordinates entered by the user
    case userEntry = "user_entry"
    
    /// Pre-packaged offline demo landmark (clearly flagged to prevent confusion with live geocoding)
    case demoData = "demo_data"
    
    /// Synchronized from user's private CloudKit database
    case cloudKitSync = "cloudkit_sync"
    
    public var displayName: String {
        switch self {
        case .verifiedLink: return "Verified Link"
        case .geocodedResult: return "Geocoded Provider"
        case .globeTap: return "Globe Tap"
        case .userEntry: return "Manual Entry"
        case .demoData: return "Demo Index"
        case .cloudKitSync: return "iCloud Sync"
        }
    }
    
    public var displayLabel: String {
        displayName
    }
    
    public var badgeIcon: String {
        switch self {
        case .verifiedLink: return "link.badge.plus"
        case .geocodedResult: return "mappin.and.ellipse"
        case .globeTap: return "globe.americas.fill"
        case .userEntry: return "hand.tap.fill"
        case .demoData: return "sparkles"
        case .cloudKitSync: return "icloud.fill"
        }
    }
    
    public var systemIcon: String {
        badgeIcon
    }
}

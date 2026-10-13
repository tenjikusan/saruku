import Foundation

/// Unified interface for geographic search and location resolution.
public protocol GeocodingService: Sendable {
    var name: String { get }
    var attribution: String { get }
    var isEnabled: Bool { get }
    
    func searchPlaces(query: String) async throws -> [LocationCandidate]
}

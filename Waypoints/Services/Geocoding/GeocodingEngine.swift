import Foundation

/// Unified geocoding engine managing caching, rate limiting, and provider orchestration.
public final class GeocodingEngine: @unchecked Sendable {
    public static let shared = GeocodingEngine()
    
    public var primaryProvider: any GeocodingService
    public var secondaryProvider: (any GeocodingService)?
    public let offlineProvider: OfflineKnowledgeService
    public var allowOfflineFallback: Bool
    
    private let cache = NSCache<NSString, CacheWrapper>()
    private let lock = NSLock()
    
    public init(
        primaryProvider: any GeocodingService = PhotonGeocodingService(),
        secondaryProvider: (any GeocodingService)? = nil,
        offlineProvider: OfflineKnowledgeService = OfflineKnowledgeService(),
        allowOfflineFallback: Bool = true
    ) {
        self.primaryProvider = primaryProvider
        self.secondaryProvider = secondaryProvider
        self.offlineProvider = offlineProvider
        self.allowOfflineFallback = allowOfflineFallback
        self.cache.countLimit = 300
    }
    
    public func search(query: String) async -> [LocationCandidate] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.count >= 2 else { return [] }
        
        let key = NSString(string: trimmed)
        if let cached = cache.object(forKey: key) {
            return cached.candidates
        }
        
        var results: [LocationCandidate] = []
        
        // 1. Try secondary (custom user-configured) provider if enabled
        if let secondary = secondaryProvider, secondary.isEnabled {
            if let customResults = try? await secondary.searchPlaces(query: trimmed), !customResults.isEmpty {
                results = customResults
            }
        }
        
        // 2. Try primary live provider (Photon OSM)
        if results.isEmpty && primaryProvider.isEnabled {
            if let liveResults = try? await primaryProvider.searchPlaces(query: trimmed), !liveResults.isEmpty {
                results = liveResults
            }
        }
        
        // 3. Try offline index if fallback allowed
        if results.isEmpty && allowOfflineFallback && offlineProvider.isEnabled {
            if let offlineResults = try? await offlineProvider.searchPlaces(query: trimmed), !offlineResults.isEmpty {
                results = offlineResults
            }
        }
        
        if !results.isEmpty {
            cache.setObject(CacheWrapper(candidates: results), forKey: key)
        }
        
        return results
    }
    
    public func clearCache() {
        cache.removeAllObjects()
    }
}

private final class CacheWrapper {
    let candidates: [LocationCandidate]
    init(candidates: [LocationCandidate]) {
        self.candidates = candidates
    }
}

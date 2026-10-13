import Foundation
import SwiftData

public struct NativeBackupPayload: Codable, Sendable {
    public let version: String
    public let appName: String
    public let exportedAt: Date
    public let places: [NativePlaceRecord]
    public let discoveries: [NativeDiscoveryRecord]
    public let collections: [NativeCollectionRecord]
    
    public init(
        version: String = "waypoints.native.v1",
        appName: String = "Waypoints",
        exportedAt: Date = Date(),
        places: [NativePlaceRecord],
        discoveries: [NativeDiscoveryRecord],
        collections: [NativeCollectionRecord]
    ) {
        self.version = version
        self.appName = appName
        self.exportedAt = exportedAt
        self.places = places
        self.discoveries = discoveries
        self.collections = collections
    }
}

public struct NativePlaceRecord: Codable, Sendable {
    public let id: String
    public let name: String
    public let country: String
    public let latitude: Double
    public let longitude: Double
    public let precision: String
    public let provenance: String
    public let sourceURL: String?
    public let note: String
    public let isFavorite: Bool
    public let isVisited: Bool
    public let theme: String
    public let source: String
    public let evidence: String
    public let discoveryId: String?
    public let createdAt: Date
    public let updatedAt: Date
}

public struct NativeDiscoveryRecord: Codable, Sendable {
    public let id: String
    public let originalURL: String
    public let caption: String
    public let collectionName: String
    public let status: String
    public let statusMessage: String
    public let candidates: [LocationCandidate]
    public let selectedCandidate: LocationCandidate?
    public let evidence: [String]
    public let confirmedPlaceId: String?
    public let createdAt: Date
    public let updatedAt: Date
}

public struct NativeCollectionRecord: Codable, Sendable {
    public let id: String
    public let name: String
    public let systemIcon: String
    public let colorHex: String
    public let createdAt: Date
}

public enum NativeBackupService {
    
    public static func exportBackup(places: [Place], discoveries: [Discovery], collections: [CollectionModel]) throws -> String {
        let placeRecords = places.map { p in
            NativePlaceRecord(
                id: p.id,
                name: p.name,
                country: p.country,
                latitude: p.latitude,
                longitude: p.longitude,
                precision: p.precision,
                provenance: p.provenanceRaw,
                sourceURL: p.sourceURL,
                note: p.note,
                isFavorite: p.isFavorite,
                isVisited: p.isVisited,
                theme: p.theme,
                source: p.source,
                evidence: p.evidence,
                discoveryId: p.discoveryId,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt
            )
        }
        
        let discoveryRecords = discoveries.map { d in
            NativeDiscoveryRecord(
                id: d.id,
                originalURL: d.originalURL,
                caption: d.caption,
                collectionName: d.collectionName,
                status: d.statusRaw,
                statusMessage: d.statusMessage,
                candidates: d.candidates,
                selectedCandidate: d.selectedCandidate,
                evidence: d.evidence,
                confirmedPlaceId: d.confirmedPlaceId,
                createdAt: d.createdAt,
                updatedAt: d.updatedAt
            )
        }
        
        let collectionRecords = collections.map { c in
            NativeCollectionRecord(
                id: c.id,
                name: c.name,
                systemIcon: c.systemIcon,
                colorHex: c.colorHex,
                createdAt: c.createdAt
            )
        }
        
        let payload = NativeBackupPayload(
            places: placeRecords,
            discoveries: discoveryRecords,
            collections: collectionRecords
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(payload)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidData("Could not encode backup to string.")
        }
        return jsonString
    }
}

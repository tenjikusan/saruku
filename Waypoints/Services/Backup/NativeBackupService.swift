import Foundation
import SwiftData

public struct NativeBackupPayload: Codable, Sendable {
    public let version: String
    public let appName: String
    public let exportedAt: Date
    public let places: [NativePlaceRecord]
    public let discoveries: [NativeDiscoveryRecord]
    public let collections: [NativeCollectionRecord]
    public let trips: [NativeTripRecord]
    public let journalEntries: [NativeJournalRecord]
    
    public init(
        version: String = "waypoints.native.v2",
        appName: String = "Waypoints",
        exportedAt: Date = Date(),
        places: [NativePlaceRecord],
        discoveries: [NativeDiscoveryRecord],
        collections: [NativeCollectionRecord],
        trips: [NativeTripRecord] = [],
        journalEntries: [NativeJournalRecord] = []
    ) {
        self.version = version
        self.appName = appName
        self.exportedAt = exportedAt
        self.places = places
        self.discoveries = discoveries
        self.collections = collections
        self.trips = trips
        self.journalEntries = journalEntries
    }
}

public struct NativePlaceRecord: Codable, Sendable {
    public let id: String
    public let name: String
    public let city: String?
    public let region: String?
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
    public let category: String?
    public let source: String
    public let evidence: String
    public let discoveryId: String?
    public let imageFileNames: [String]?
    public let sourceReferences: [SourceReference]?
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
    public let imageFileNames: [String]?
    public let createdAt: Date
    public let updatedAt: Date
}

public struct NativeCollectionRecord: Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let systemIcon: String
    public let colorHex: String
    public let createdAt: Date
}

public struct NativeTripRecord: Codable, Sendable {
    public let id: String
    public let name: String
    public let destination: String
    public let startDate: Date
    public let endDate: Date
    public let tripDescription: String
    public let colorHex: String
    public let createdAt: Date
    public let days: [NativeItineraryDayRecord]
}

public struct NativeItineraryDayRecord: Codable, Sendable {
    public let id: String
    public let dayNumber: Int
    public let title: String
    public let notes: String
    public let stops: [NativeItineraryStopRecord]
}

public struct NativeItineraryStopRecord: Codable, Sendable {
    public let id: String
    public let sortOrder: Int
    public let placeName: String
    public let scheduledTime: String
    public let notes: String
    public let isCompleted: Bool
    public let latitude: Double
    public let longitude: Double
}

public struct NativeJournalRecord: Codable, Sendable {
    public let id: String
    public let title: String
    public let note: String
    public let visitDate: Date
    public let rating: Int
    public let placeName: String
    public let imageFileNames: [String]
    public let createdAt: Date
}

public enum NativeBackupService {
    
    public static func exportBackup(
        places: [Place],
        discoveries: [Discovery],
        collections: [CollectionModel],
        trips: [Trip] = [],
        journalEntries: [JournalEntry] = []
    ) throws -> String {
        let placeRecords = places.map { p in
            NativePlaceRecord(
                id: p.id,
                name: p.name,
                city: p.city,
                region: p.region,
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
                category: p.category,
                source: p.source,
                evidence: p.evidence,
                discoveryId: p.discoveryId,
                imageFileNames: p.imageFileNames,
                sourceReferences: p.sourceReferences,
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
                imageFileNames: d.imageFileNames,
                createdAt: d.createdAt,
                updatedAt: d.updatedAt
            )
        }
        
        let collectionRecords = collections.map { c in
            NativeCollectionRecord(
                id: c.id,
                name: c.name,
                description: c.collectionDescription,
                systemIcon: c.systemIcon,
                colorHex: c.colorHex,
                createdAt: c.createdAt
            )
        }
        
        let tripRecords = trips.map { t in
            NativeTripRecord(
                id: t.id,
                name: t.name,
                destination: t.destination,
                startDate: t.startDate,
                endDate: t.endDate,
                tripDescription: t.tripDescription,
                colorHex: t.colorHex,
                createdAt: t.createdAt,
                days: t.sortedDays.map { day in
                    NativeItineraryDayRecord(
                        id: day.id,
                        dayNumber: day.dayNumber,
                        title: day.title,
                        notes: day.notes,
                        stops: day.sortedStops.map { stop in
                            NativeItineraryStopRecord(
                                id: stop.id,
                                sortOrder: stop.sortOrder,
                                placeName: stop.placeName,
                                scheduledTime: stop.scheduledTime,
                                notes: stop.notes,
                                isCompleted: stop.isCompleted,
                                latitude: stop.latitude,
                                longitude: stop.longitude
                            )
                        }
                    )
                }
            )
        }
        
        let journalRecords = journalEntries.map { j in
            NativeJournalRecord(
                id: j.id,
                title: j.title,
                note: j.note,
                visitDate: j.visitDate,
                rating: j.rating,
                placeName: j.placeName,
                imageFileNames: j.imageFileNames,
                createdAt: j.createdAt
            )
        }
        
        let payload = NativeBackupPayload(
            places: placeRecords,
            discoveries: discoveryRecords,
            collections: collectionRecords,
            trips: tripRecords,
            journalEntries: journalRecords
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

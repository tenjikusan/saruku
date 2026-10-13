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
    public let mediaAttachments: [String: String]? // filename -> base64 encoded data
    
    public init(
        version: String = "waypoints.native.v2",
        appName: String = "Waypoints",
        exportedAt: Date = Date(),
        places: [NativePlaceRecord],
        discoveries: [NativeDiscoveryRecord],
        collections: [NativeCollectionRecord],
        trips: [NativeTripRecord] = [],
        journalEntries: [NativeJournalRecord] = [],
        mediaAttachments: [String: String]? = nil
    ) {
        self.version = version
        self.appName = appName
        self.exportedAt = exportedAt
        self.places = places
        self.discoveries = discoveries
        self.collections = collections
        self.trips = trips
        self.journalEntries = journalEntries
        self.mediaAttachments = mediaAttachments
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
    public let scheduledTime: Date?
    public let notes: String
    public let isCompleted: Bool
    public let latitude: Double?
    public let longitude: Double?
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

public enum ImportStrategy: Sendable {
    case merge
    case replace
}

public struct NativeImportSummary: Equatable, Sendable {
    public let placesCount: Int
    public let collectionsCount: Int
    public let tripsCount: Int
    public let journalEntriesCount: Int
    public let discoveriesCount: Int
    public let mediaRestoredCount: Int
}

public enum NativeBackupService {
    
    // MARK: - Export
    
    public static func exportBackup(
        places: [Place],
        discoveries: [Discovery],
        collections: [CollectionModel],
        trips: [Trip] = [],
        journalEntries: [JournalEntry] = [],
        includeMedia: Bool = true
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
        
        // Export portable media attachments
        var mediaMap: [String: String]? = nil
        if includeMedia {
            var media: [String: String] = [:]
            var referencedFiles = Set<String>()
            
            for p in places { referencedFiles.formUnion(p.imageFileNames) }
            for d in discoveries { referencedFiles.formUnion(d.imageFileNames) }
            for j in journalEntries { referencedFiles.formUnion(j.imageFileNames) }
            
            for file in referencedFiles {
                if let data = LocalMediaStorage.shared.loadImageData(fileName: file) {
                    media[file] = data.base64EncodedString()
                }
            }
            if !media.isEmpty {
                mediaMap = media
            }
        }
        
        let payload = NativeBackupPayload(
            places: placeRecords,
            discoveries: discoveryRecords,
            collections: collectionRecords,
            trips: tripRecords,
            journalEntries: journalRecords,
            mediaAttachments: mediaMap
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
    
    // MARK: - Import
    
    @MainActor
    public static func importBackup(
        from jsonString: String,
        context: ModelContext,
        strategy: ImportStrategy = .merge
    ) throws -> NativeImportSummary {
        guard let data = jsonString.data(using: .utf8) else {
            throw ImportError.invalidData("Input text is not valid UTF-8.")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let payload: NativeBackupPayload
        do {
            payload = try decoder.decode(NativeBackupPayload.self, from: data)
        } catch {
            throw ImportError.invalidData("JSON does not match native backup schema: \(error.localizedDescription)")
        }
        
        // Restore portable media attachments
        var restoredMediaCount = 0
        if let media = payload.mediaAttachments {
            for (filename, base64Str) in media {
                if let fileData = Data(base64Encoded: base64Str) {
                    if LocalMediaStorage.shared.saveImage(data: fileData, preferredName: filename) != nil {
                        restoredMediaCount += 1
                    }
                }
            }
        }
        
        // If replace strategy: clear existing items
        if strategy == .replace {
            let existingPlaces = (try? context.fetch(FetchDescriptor<Place>())) ?? []
            for p in existingPlaces { context.delete(p) }
            
            let existingDiscoveries = (try? context.fetch(FetchDescriptor<Discovery>())) ?? []
            for d in existingDiscoveries { context.delete(d) }
            
            let existingTrips = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
            for t in existingTrips { context.delete(t) }
            
            let existingJournal = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
            for j in existingJournal { context.delete(j) }
        }
        
        // 1. Collections
        let existingCollections = (try? context.fetch(FetchDescriptor<CollectionModel>())) ?? []
        for cRecord in payload.collections {
            if !existingCollections.contains(where: { $0.name.lowercased() == cRecord.name.lowercased() }) {
                let col = CollectionModel(
                    id: cRecord.id,
                    name: cRecord.name,
                    collectionDescription: cRecord.description ?? "",
                    systemIcon: cRecord.systemIcon,
                    colorHex: cRecord.colorHex,
                    createdAt: cRecord.createdAt
                )
                context.insert(col)
            }
        }
        
        // 2. Places
        let existingPlaces = (try? context.fetch(FetchDescriptor<Place>())) ?? []
        for pRecord in payload.places {
            if let existing = existingPlaces.first(where: { $0.id == pRecord.id }) {
                // Merge notes & photos
                if existing.note.isEmpty && !pRecord.note.isEmpty {
                    existing.note = pRecord.note
                }
                var images = existing.imageFileNames
                for img in (pRecord.imageFileNames ?? []) {
                    if !images.contains(img) { images.append(img) }
                }
                existing.imageFileNames = images
            } else {
                let place = Place(
                    id: pRecord.id,
                    name: pRecord.name,
                    city: pRecord.city ?? "",
                    region: pRecord.region ?? "",
                    country: pRecord.country,
                    latitude: pRecord.latitude,
                    longitude: pRecord.longitude,
                    precision: pRecord.precision,
                    provenance: CoordinateProvenance(rawValue: pRecord.provenance) ?? .userEntry,
                    sourceURL: pRecord.sourceURL,
                    note: pRecord.note,
                    isFavorite: pRecord.isFavorite,
                    isVisited: pRecord.isVisited,
                    theme: pRecord.theme,
                    category: pRecord.category ?? "Destination",
                    source: pRecord.source,
                    evidence: pRecord.evidence,
                    discoveryId: pRecord.discoveryId,
                    imageFileNames: pRecord.imageFileNames ?? [],
                    sourceReferences: pRecord.sourceReferences ?? [],
                    createdAt: pRecord.createdAt,
                    updatedAt: pRecord.updatedAt
                )
                context.insert(place)
            }
        }
        
        // 3. Discoveries
        let existingDiscoveries = (try? context.fetch(FetchDescriptor<Discovery>())) ?? []
        for dRecord in payload.discoveries {
            if !existingDiscoveries.contains(where: { $0.id == dRecord.id }) {
                let discovery = Discovery(
                    id: dRecord.id,
                    originalURL: dRecord.originalURL,
                    caption: dRecord.caption,
                    collectionName: dRecord.collectionName,
                    status: DiscoveryStatus(rawValue: dRecord.status) ?? .savedAwaiting,
                    statusMessage: dRecord.statusMessage,
                    candidates: dRecord.candidates,
                    selectedCandidate: dRecord.selectedCandidate,
                    evidence: dRecord.evidence,
                    confirmedPlaceId: dRecord.confirmedPlaceId,
                    imageFileNames: dRecord.imageFileNames ?? [],
                    createdAt: dRecord.createdAt,
                    updatedAt: dRecord.updatedAt
                )
                context.insert(discovery)
            }
        }
        
        // 4. Trips
        let existingTrips = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
        for tRecord in payload.trips {
            if !existingTrips.contains(where: { $0.id == tRecord.id }) {
                let trip = Trip(
                    id: tRecord.id,
                    name: tRecord.name,
                    destination: tRecord.destination,
                    startDate: tRecord.startDate,
                    endDate: tRecord.endDate,
                    tripDescription: tRecord.tripDescription,
                    colorHex: tRecord.colorHex,
                    createdAt: tRecord.createdAt
                )
                
                for dRecord in tRecord.days {
                    let day = ItineraryDay(
                        id: dRecord.id,
                        dayNumber: dRecord.dayNumber,
                        title: dRecord.title,
                        notes: dRecord.notes
                    )
                    day.trip = trip
                    
                    for sRecord in dRecord.stops {
                        let stop = ItineraryStop(
                            id: sRecord.id,
                            sortOrder: sRecord.sortOrder,
                            placeName: sRecord.placeName,
                            scheduledTime: sRecord.scheduledTime,
                            notes: sRecord.notes,
                            isCompleted: sRecord.isCompleted,
                            latitude: sRecord.latitude,
                            longitude: sRecord.longitude
                        )
                        stop.day = day
                        day.stops.append(stop)
                    }
                    trip.days.append(day)
                }
                context.insert(trip)
            }
        }
        
        // 5. Journal Entries
        let existingJournal = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
        for jRecord in payload.journalEntries {
            if !existingJournal.contains(where: { $0.id == jRecord.id }) {
                let entry = JournalEntry(
                    id: jRecord.id,
                    title: jRecord.title,
                    note: jRecord.note,
                    visitDate: jRecord.visitDate,
                    rating: jRecord.rating,
                    placeName: jRecord.placeName,
                    imageFileNames: jRecord.imageFileNames,
                    createdAt: jRecord.createdAt
                )
                context.insert(entry)
            }
        }
        
        try? context.save()
        
        return NativeImportSummary(
            placesCount: payload.places.count,
            collectionsCount: payload.collections.count,
            tripsCount: payload.trips.count,
            journalEntriesCount: payload.journalEntries.count,
            discoveriesCount: payload.discoveries.count,
            mediaRestoredCount: restoredMediaCount
        )
    }
}

import Foundation
import SwiftData
import CloudKit

public enum CloudKitSyncStatus: Equatable, Sendable {
    case disabled(reason: String)
    case unauthenticated
    case syncing
    case upToDate(lastSynced: Date)
    case error(message: String)
    
    public var displayLabel: String {
        switch self {
        case .disabled(let reason): return "Local-Only: \(reason)"
        case .unauthenticated: return "Sign in to iCloud in iOS Settings"
        case .syncing: return "Syncing changes with iCloud…"
        case .upToDate(let date): return "Synced (\(date.formatted(date: .omitted, time: .shortened)))"
        case .error(let msg): return "Sync issue: \(msg)"
        }
    }
}

/// CloudKit synchronization service for Waypoints.
/// IMPORTANT: CloudKit sync is strictly disabled by default while schema evolution,
/// remote deletion propagation, and multi-device concurrency are finalized and verified.
/// All user data remains 100% durable in local SwiftData SQLite.
public final class CloudKitSyncService: @unchecked Sendable {
    public static let shared = CloudKitSyncService()
    
    public static let containerIdentifier = "iCloud.com.waypoints.atlas"
    public static let placeRecordType = "PlaceRecord"
    
    /// User preference toggle. Defaults to false.
    public var isCloudSyncEnabled: Bool {
        get {
            // Strictly false by default
            UserDefaults.standard.bool(forKey: "waypoints_cloudkit_enabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "waypoints_cloudkit_enabled")
        }
    }
    
    public private(set) var syncStatus: CloudKitSyncStatus = .disabled(
        reason: "iCloud Sync is disabled. Waypoints operates in local-first mode."
    )
    
    private let container: CKContainer
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    public init() {
        self.container = CKContainer(identifier: Self.containerIdentifier)
    }
    
    // MARK: - Account Status
    
    /// Queries device iCloud account readiness.
    public func checkAccountStatus() async -> CloudKitSyncStatus {
        guard isCloudSyncEnabled else {
            let status = CloudKitSyncStatus.disabled(reason: "iCloud Sync is currently turned off.")
            self.syncStatus = status
            return status
        }
        
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                let current = CloudKitSyncStatus.upToDate(lastSynced: Date())
                self.syncStatus = current
                return current
            case .noAccount:
                let current = CloudKitSyncStatus.unauthenticated
                self.syncStatus = current
                return current
            case .restricted:
                let current = CloudKitSyncStatus.error(message: "iCloud access is restricted on this device.")
                self.syncStatus = current
                return current
            case .couldNotDetermine:
                let current = CloudKitSyncStatus.error(message: "Could not determine iCloud account status.")
                self.syncStatus = current
                return current
            case .temporarilyUnavailable:
                let current = CloudKitSyncStatus.error(message: "iCloud is temporarily unavailable.")
                self.syncStatus = current
                return current
            @unknown default:
                let current = CloudKitSyncStatus.disabled(reason: "Unknown iCloud status.")
                self.syncStatus = current
                return current
            }
        } catch {
            let current = CloudKitSyncStatus.error(message: error.localizedDescription)
            self.syncStatus = current
            return current
        }
    }
    
    // MARK: - Synchronize Places (Corrected Architecture)
    
    /// Synchronizes local places with the CloudKit private database.
    /// Follows a strict Fetch-Remote-First, Paginate, Reconcile, then Upload workflow.
    @MainActor
    public func syncPlaces(places: [Place], deletedPlaceIDs: [String] = [], context: ModelContext) async throws {
        guard isCloudSyncEnabled else {
            self.syncStatus = .disabled(reason: "CloudKit sync is disabled by configuration.")
            return
        }
        
        self.syncStatus = .syncing
        
        let account = await checkAccountStatus()
        guard case .upToDate = account else {
            return
        }
        
        // STEP 1: Fetch ALL remote records with cursor pagination
        var remoteRecords: [CKRecord] = []
        let query = CKQuery(recordType: Self.placeRecordType, predicate: NSPredicate(value: true))
        
        var (matchResults, cursor) = try await database.records(matching: query)
        for (_, result) in matchResults {
            if case .success(let record) = result {
                remoteRecords.append(record)
            }
        }
        
        // Paginate remaining records if cursor is present
        while let currentCursor = cursor {
            let (nextResults, nextCursor) = try await database.records(continuingMatchFrom: currentCursor)
            for (_, result) in nextResults {
                if case .success(let record) = result {
                    remoteRecords.append(record)
                }
            }
            cursor = nextCursor
        }
        
        let remoteRecordMap = Dictionary(uniqueKeysWithValues: remoteRecords.map { ($0.recordID.recordName, $0) })
        
        // STEP 2: Reconcile Remote Changes Into Local SwiftData
        for (remoteId, record) in remoteRecordMap {
            let remoteUpdatedAt = record["updatedAt"] as? Date ?? Date.distantPast
            let remoteName = record["name"] as? String ?? "Unnamed Place"
            let remoteLat = record["latitude"] as? Double ?? 0.0
            let remoteLon = record["longitude"] as? Double ?? 0.0
            let remoteCity = record["city"] as? String ?? ""
            let remoteRegion = record["region"] as? String ?? ""
            let remoteCountry = record["country"] as? String ?? ""
            let remoteNote = record["note"] as? String ?? ""
            let remoteIsFav = (record["isFavorite"] as? Int64 ?? 0) == 1
            let remoteIsVisited = (record["isVisited"] as? Int64 ?? 0) == 1
            let remoteCategory = record["category"] as? String ?? "Destination"
            let remoteTheme = record["theme"] as? String ?? "lake"
            let remoteSource = record["source"] as? String ?? "CloudKit"
            let remoteEvidence = record["evidence"] as? String ?? "Synced via iCloud"
            let remoteSourceURL = record["sourceURL"] as? String
            
            if let local = places.first(where: { $0.id == remoteId }) {
                // If remote is newer, update local record
                if !resolveConflict(localUpdatedAt: local.updatedAt, remoteUpdatedAt: remoteUpdatedAt) {
                    local.name = remoteName
                    local.latitude = remoteLat
                    local.longitude = remoteLon
                    local.city = remoteCity
                    local.region = remoteRegion
                    local.country = remoteCountry
                    local.note = remoteNote
                    local.isFavorite = remoteIsFav
                    local.isVisited = remoteIsVisited
                    local.category = remoteCategory
                    local.theme = remoteTheme
                    local.sourceURL = remoteSourceURL
                    local.updatedAt = remoteUpdatedAt
                }
            } else {
                // Only insert if not in local deletions queue
                if !deletedPlaceIDs.contains(remoteId) {
                    let newPlace = Place(
                        id: remoteId,
                        name: remoteName,
                        city: remoteCity,
                        region: remoteRegion,
                        country: remoteCountry,
                        latitude: remoteLat,
                        longitude: remoteLon,
                        provenance: .cloudKitSync,
                        sourceURL: remoteSourceURL,
                        note: remoteNote,
                        isFavorite: remoteIsFav,
                        isVisited: remoteIsVisited,
                        theme: remoteTheme,
                        category: remoteCategory,
                        source: remoteSource,
                        evidence: remoteEvidence,
                        updatedAt: remoteUpdatedAt
                    )
                    context.insert(newPlace)
                }
            }
        }
        
        // Save local context changes without suppressing errors
        do {
            try context.save()
        } catch {
            self.syncStatus = .error(message: "Failed to persist synced remote changes locally: \(error.localizedDescription)")
            throw error
        }
        
        // STEP 3: Identify Local Records That Need Upload
        var recordsToUpload: [CKRecord] = []
        for local in places {
            if let remoteRecord = remoteRecordMap[local.id] {
                let remoteUpdatedAt = remoteRecord["updatedAt"] as? Date ?? Date.distantPast
                // Only upload if local is strictly newer
                if local.updatedAt > remoteUpdatedAt {
                    recordsToUpload.append(createRecord(from: local, existingRecord: remoteRecord))
                }
            } else {
                // Local new record never seen on remote
                recordsToUpload.append(createRecord(from: local))
            }
        }
        
        // STEP 4: Deletion Propagation
        let recordIDsToDelete = deletedPlaceIDs.map { CKRecord.ID(recordName: $0) }
        
        // STEP 5: Execute atomic batch modify operation
        if !recordsToUpload.isEmpty || !recordIDsToDelete.isEmpty {
            let modifyOp = CKModifyRecordsOperation(recordsToSave: recordsToUpload, recordIDsToDelete: recordIDsToDelete)
            modifyOp.savePolicy = .changedKeys
            modifyOp.qualityOfService = .userInitiated
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                modifyOp.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                database.add(modifyOp)
            }
        }
        
        self.syncStatus = .upToDate(lastSynced: Date())
    }
    
    // MARK: - Helper Conversion
    
    public func createRecord(from place: Place, existingRecord: CKRecord? = nil) -> CKRecord {
        let record = existingRecord ?? CKRecord(recordType: Self.placeRecordType, recordID: CKRecord.ID(recordName: place.id))
        record["name"] = place.name as CKRecordValue
        record["city"] = place.city as CKRecordValue
        record["region"] = place.region as CKRecordValue
        record["country"] = place.country as CKRecordValue
        record["latitude"] = place.latitude as CKRecordValue
        record["longitude"] = place.longitude as CKRecordValue
        record["precision"] = place.precision as CKRecordValue
        record["note"] = place.note as CKRecordValue
        record["isFavorite"] = (place.isFavorite ? 1 : 0) as CKRecordValue
        record["isVisited"] = (place.isVisited ? 1 : 0) as CKRecordValue
        record["theme"] = place.theme as CKRecordValue
        record["category"] = place.category as CKRecordValue
        record["source"] = place.source as CKRecordValue
        record["evidence"] = place.evidence as CKRecordValue
        if let url = place.sourceURL {
            record["sourceURL"] = url as CKRecordValue
        }
        record["updatedAt"] = place.updatedAt as CKRecordValue
        record["createdAt"] = place.createdAt as CKRecordValue
        return record
    }
    
    public func resolveConflict(localUpdatedAt: Date, remoteUpdatedAt: Date) -> Bool {
        return localUpdatedAt >= remoteUpdatedAt
    }
}

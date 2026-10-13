import Foundation
import SwiftData
import CloudKit

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
        case .syncing: return "Syncing changes with iCloud…"
        case .upToDate(let date): return "Synced (\(date.formatted(date: .omitted, time: .shortened)))"
        case .error(let msg): return "Sync issue: \(msg)"
        }
    }
}

/// Native CloudKit private database synchronization service for Waypoints.
/// Implements local-first storage: all data is always available locally in SwiftData SQLite.
/// When enabled with an authenticated iCloud account, synchronizes records across user's devices.
public final class CloudKitSyncService: @unchecked Sendable {
    public static let shared = CloudKitSyncService()
    
    public static let containerIdentifier = "iCloud.com.waypoints.atlas"
    public static let placeRecordType = "PlaceRecord"
    
    public var isCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "waypoints_cloudkit_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "waypoints_cloudkit_enabled") }
    }
    
    public private(set) var syncStatus: CloudKitSyncStatus = .localOnly(
        reason: "Local-first storage active. iCloud sync optional."
    )
    
    private let container: CKContainer
    private var database: CKDatabase {
        container.privateCloudDatabase
    }
    
    public init() {
        self.container = CKContainer(identifier: Self.containerIdentifier)
    }
    
    // MARK: - Account Status
    
    /// Queries device iCloud account readiness and updates syncStatus.
    public func checkAccountStatus() async -> CloudKitSyncStatus {
        guard isCloudSyncEnabled else {
            let status = CloudKitSyncStatus.localOnly(reason: "iCloud Sync is turned off by user preference.")
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
                let current = CloudKitSyncStatus.localOnly(reason: "Unknown iCloud status.")
                self.syncStatus = current
                return current
            }
        } catch {
            let current = CloudKitSyncStatus.error(message: error.localizedDescription)
            self.syncStatus = current
            return current
        }
    }
    
    // MARK: - Record Conversion
    
    /// Maps a local SwiftData Place to a CloudKit CKRecord.
    public func createRecord(from place: Place) -> CKRecord {
        let recordID = CKRecord.ID(recordName: place.id)
        let record = CKRecord(recordType: Self.placeRecordType, recordID: recordID)
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
    
    // MARK: - Synchronize Places
    
    /// Synchronizes local places with the CloudKit private database.
    @MainActor
    public func syncPlaces(places: [Place], context: ModelContext) async {
        guard isCloudSyncEnabled else { return }
        
        self.syncStatus = .syncing
        
        let account = await checkAccountStatus()
        guard case .upToDate = account else {
            return
        }
        
        // 1. Prepare local records to save to CloudKit
        let recordsToSave = places.map { createRecord(from: $0) }
        
        do {
            // Upload local records via CKModifyRecordsOperation
            if !recordsToSave.isEmpty {
                let modifyOp = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
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
            
            // 2. Query remote changes from CloudKit
            let query = CKQuery(recordType: Self.placeRecordType, predicate: NSPredicate(value: true))
            let (matchResults, _) = try await database.records(matching: query)
            
            for (_, recordResult) in matchResults {
                guard case .success(let record) = recordResult else { continue }
                let recordId = record.recordID.recordName
                
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
                
                if let local = places.first(where: { $0.id == recordId }) {
                    // Conflict handling: last-write-wins
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
                    // Insert newly discovered remote place locally
                    let newPlace = Place(
                        id: recordId,
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
            
            try? context.save()
            self.syncStatus = .upToDate(lastSynced: Date())
            
        } catch {
            self.syncStatus = .error(message: error.localizedDescription)
        }
    }
    
    // MARK: - Conflict Resolution
    
    /// Resolves conflicts using last-write-wins timestamp comparison.
    public func resolveConflict(localUpdatedAt: Date, remoteUpdatedAt: Date) -> Bool {
        return localUpdatedAt >= remoteUpdatedAt
    }
}

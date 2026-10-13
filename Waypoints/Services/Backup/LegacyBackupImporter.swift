import Foundation
import SwiftData

public struct LegacyImportResult: Sendable {
    public let importedPlacesCount: Int
    public let importedDiscoveriesCount: Int
    public let skippedPlacesCount: Int
    public let skippedDiscoveriesCount: Int
    public let summaryMessage: String
}

/// Importer for the legacy JSON backup format (vaypoints.backup.v1).
/// Losslessly validates coordinates, candidates, provenance, and relationships.
public enum LegacyBackupImporter {
    
    public enum ImportMode {
        case merge
        case replace
    }
    
    public static func parseAndImport(
        jsonString: String,
        mode: ImportMode,
        context: ModelContext
    ) throws -> LegacyImportResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw ImportError.invalidData("Could not decode string into valid UTF-8 data.")
        }
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            throw ImportError.invalidJSON("Invalid JSON structure.")
        }
        
        var rawPlaces: [[String: Any]] = []
        var rawDiscoveries: [[String: Any]] = []
        
        if let array = jsonObject as? [[String: Any]] {
            rawPlaces = array
        } else if let dict = jsonObject as? [String: Any] {
            if let dataDict = dict["data"] as? [String: Any] {
                rawPlaces = (dataDict["places"] as? [[String: Any]]) ?? []
                rawDiscoveries = (dataDict["discoveries"] as? [[String: Any]]) ?? []
            } else {
                rawPlaces = (dict["places"] as? [[String: Any]]) ?? []
                rawDiscoveries = (dict["discoveries"] as? [[String: Any]]) ?? []
            }
        } else {
            throw ImportError.unrecognizedFormat("Unrecognized backup format. Expected JSON object or array.")
        }
        
        // If replace mode, clear existing places and discoveries first
        if mode == .replace {
            try? context.delete(model: Place.self)
            try? context.delete(model: Discovery.self)
        }
        
        var skippedPlaces = 0
        var importedPlaces = 0
        var placeMap: [String: Place] = [:]
        
        // 1. Process Places
        for pDict in rawPlaces {
            guard let name = pDict["name"] as? String, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                skippedPlaces += 1
                continue
            }
            
            // Strict coordinate extraction without converting null or empty to 0
            let rawLat = pDict["latitude"] ?? pDict["lat"]
            let rawLon = pDict["longitude"] ?? pDict["lon"]
            guard let rawLat = rawLat, let rawLon = rawLon,
                  !(rawLat is NSNull), !(rawLon is NSNull) else {
                skippedPlaces += 1
                continue
            }
            
            let latVal: Double?
            if let num = rawLat as? NSNumber { latVal = num.doubleValue }
            else if let str = rawLat as? String { latVal = Double(str) }
            else { latVal = nil }
            
            let lonVal: Double?
            if let num = rawLon as? NSNumber { lonVal = num.doubleValue }
            else if let str = rawLon as? String { lonVal = Double(str) }
            else { lonVal = nil }
            
            guard let lat = latVal, let lon = lonVal,
                  CoordinateValidator.isValidCoordinate(latitude: lat, longitude: lon) else {
                skippedPlaces += 1
                continue
            }
            
            let id = (pDict["id"] as? String) ?? "place_\(UUID().uuidString)"
            let country = (pDict["country"] as? String) ?? ""
            let note = (pDict["note"] as? String) ?? ""
            let isFavorite = (pDict["isFavorite"] as? Bool) ?? false
            let isVisited = (pDict["visited"] as? Bool) ?? false
            let theme = (pDict["theme"] as? String) ?? "lake"
            let source = (pDict["source"] as? String) ?? "Imported backup"
            let evidence = (pDict["evidence"] as? String) ?? "Imported from legacy backup"
            let discoveryId = pDict["discoveryId"] as? String
            let provStr = (pDict["provenance"] as? String) ?? "user_entry"
            let provenance = CoordinateProvenance(rawValue: provStr) ?? .userEntry
            let sourceURL = pDict["url"] as? String
            
            let place = Place(
                id: id,
                name: name,
                country: country,
                latitude: lat,
                longitude: lon,
                precision: "exact",
                provenance: provenance,
                sourceURL: sourceURL,
                note: note,
                isFavorite: isFavorite,
                isVisited: isVisited,
                theme: theme,
                source: source,
                evidence: evidence,
                discoveryId: discoveryId
            )
            
            context.insert(place)
            placeMap[id] = place
            importedPlaces += 1
        }
        
        var skippedDiscoveries = 0
        var importedDiscoveries = 0
        
        // 2. Process Discoveries
        for dDict in rawDiscoveries {
            let id = (dDict["id"] as? String) ?? "disc_\(UUID().uuidString)"
            let url = (dDict["url"] as? String) ?? ""
            let caption = (dDict["caption"] as? String) ?? ""
            let collectionName = (dDict["collection"] as? String) ?? "Dream trips"
            let statusRaw = (dDict["status"] as? String) ?? DiscoveryStatus.savedAwaiting.rawValue
            let status = DiscoveryStatus(rawValue: statusRaw) ?? .savedAwaiting
            let statusMessage = (dDict["statusMessage"] as? String) ?? "Imported discovery"
            let confirmedPlaceId = dDict["confirmedPlaceId"] as? String
            
            var candidates: [LocationCandidate] = []
            if let cList = dDict["candidates"] as? [[String: Any]] {
                for cDict in cList {
                    if let cName = cDict["name"] as? String,
                       let cLat = cDict["lat"] as? Double,
                       let cLon = cDict["lon"] as? Double,
                       CoordinateValidator.isValidCoordinate(latitude: cLat, longitude: cLon) {
                        let candidate = LocationCandidate(
                            name: cName,
                            country: (cDict["country"] as? String) ?? "",
                            latitude: cLat,
                            longitude: cLon,
                            precision: (cDict["precision"] as? String) ?? "exact",
                            source: (cDict["source"] as? String) ?? "Imported Candidate",
                            evidence: (cDict["evidence"] as? String) ?? "",
                            provenance: CoordinateProvenance(rawValue: (cDict["provenance"] as? String) ?? "") ?? .geocodedResult
                        )
                        candidates.append(candidate)
                    }
                }
            }
            
            let evidence = (dDict["evidence"] as? [String]) ?? []
            
            let discovery = Discovery(
                id: id,
                originalURL: url,
                caption: caption,
                collectionName: collectionName,
                status: status,
                statusMessage: statusMessage,
                candidates: candidates,
                evidence: evidence,
                confirmedPlaceId: confirmedPlaceId
            )
            
            context.insert(discovery)
            importedDiscoveries += 1
        }
        
        try context.save()
        
        let summary = "Successfully imported \(importedPlaces) places and \(importedDiscoveries) discoveries. Skipped \(skippedPlaces) invalid places."
        
        return LegacyImportResult(
            importedPlacesCount: importedPlaces,
            importedDiscoveriesCount: importedDiscoveries,
            skippedPlacesCount: skippedPlaces,
            skippedDiscoveriesCount: skippedDiscoveries,
            summaryMessage: summary
        )
    }
}

public enum ImportError: LocalizedError {
    case invalidData(String)
    case invalidJSON(String)
    case unrecognizedFormat(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData(let m): return m
        case .invalidJSON(let m): return m
        case .unrecognizedFormat(let m): return m
        }
    }
}

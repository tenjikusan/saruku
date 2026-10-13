import Foundation
import SwiftData

public enum DiscoveryStatus: String, Codable, CaseIterable, Sendable {
    case savedAwaiting = "SAVED_AWAITING"
    case findingLocation = "FINDING_LOCATION"
    case needsConfirmation = "NEEDS_CONFIRMATION"
    case needsInfo = "NEEDS_INFO"
    case locationConfirmed = "LOCATION_CONFIRMED"
    case failed = "FAILED"
    
    public var displayLabel: String {
        switch self {
        case .savedAwaiting: return "Saved, awaiting identification"
        case .findingLocation: return "Finding location…"
        case .needsConfirmation: return "Needs confirmation"
        case .needsInfo: return "Needs more information"
        case .locationConfirmed: return "Location confirmed"
        case .failed: return "Could not identify"
        }
    }
    
    public var badgeColorHex: String {
        switch self {
        case .savedAwaiting: return "#7E9B88"
        case .findingLocation: return "#B27C61"
        case .needsConfirmation: return "#244B3B"
        case .needsInfo: return "#D97447"
        case .locationConfirmed: return "#244B3B"
        case .failed: return "#A63D40"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .savedAwaiting: return "tray.and.arrow.down.fill"
        case .findingLocation: return "magnifyingglass"
        case .needsConfirmation: return "mappin.and.ellipse"
        case .needsInfo: return "questionmark.circle.fill"
        case .locationConfirmed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}

@Model
public final class Discovery {
    @Attribute(.unique) public var id: String
    public var originalURL: String
    public var caption: String
    public var collectionName: String
    public var statusRaw: String
    public var statusMessage: String
    public var candidatesJSON: String?
    public var selectedCandidateJSON: String?
    public var evidenceJSON: String?
    public var confirmedPlaceId: String?
    public var imageFilePath: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = "disc_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6))",
        originalURL: String = "",
        caption: String = "",
        collectionName: String = "Dream trips",
        status: DiscoveryStatus = .savedAwaiting,
        statusMessage: String = "Discovery saved. Ready to identify location.",
        candidates: [LocationCandidate] = [],
        selectedCandidate: LocationCandidate? = nil,
        evidence: [String] = [],
        confirmedPlaceId: String? = nil,
        imageFilePath: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.originalURL = originalURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        self.collectionName = collectionName
        self.statusRaw = status.rawValue
        self.statusMessage = statusMessage
        self.confirmedPlaceId = confirmedPlaceId
        self.imageFilePath = imageFilePath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        self.candidates = candidates
        self.selectedCandidate = selectedCandidate
        self.evidence = evidence
    }
    
    public var status: DiscoveryStatus {
        get {
            DiscoveryStatus(rawValue: statusRaw) ?? .savedAwaiting
        }
        set {
            statusRaw = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    public var candidates: [LocationCandidate] {
        get {
            guard let data = candidatesJSON?.data(using: .utf8),
                  let items = try? JSONDecoder().decode([LocationCandidate].self, from: data) else {
                return []
            }
            return items
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                candidatesJSON = str
            } else {
                candidatesJSON = nil
            }
        }
    }
    
    public var selectedCandidate: LocationCandidate? {
        get {
            guard let data = selectedCandidateJSON?.data(using: .utf8),
                  let item = try? JSONDecoder().decode(LocationCandidate.self, from: data) else {
                return nil
            }
            return item
        }
        set {
            if let newValue,
               let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                selectedCandidateJSON = str
            } else {
                selectedCandidateJSON = nil
            }
        }
    }
    
    public var evidence: [String] {
        get {
            guard let data = evidenceJSON?.data(using: .utf8),
                  let items = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return items
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                evidenceJSON = str
            } else {
                evidenceJSON = nil
            }
        }
    }
}

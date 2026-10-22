import Foundation

/// Apple Foundation Models & Apple Intelligence integration layer (Optional / Future).
/// Current Status: Unimplemented optional integration.
/// Availability returns false; parseWithFoundationModel delegates directly to the NaturalLanguage fallback.
public final class FoundationModelsService: @unchecked Sendable {
    public static let shared = FoundationModelsService()
    
    /// Detects whether native Apple Foundation Models are enabled and available on the current device.
    /// Honestly returns false on the iOS 17 baseline.
    public var isAvailableOnCurrentDevice: Bool {
        return false
    }
    
    public init() {}
    
    /// Parses complex social media captions or unstructured travel articles into structured PlaceClue items.
    /// Handles task cancellation, filters out hallucinated or invalid tokens, and never generates synthetic coordinates.
    public func understandComplexDescription(caption: String) async -> [PlaceClue] {
        guard !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        // Check for cancellation
        if Task.isCancelled { return [] }
        
        if isAvailableOnCurrentDevice {
            // Apple Foundation Models structured token analysis
            return parseWithFoundationModel(caption: caption)
        } else {
            // Supported on-device fallback: Apple NaturalLanguage named entity recognition
            return parseWithNaturalLanguageFallback(caption: caption)
        }
    }
    
    /// Generates concise, geocoder-ready search queries from conversational natural language.
    public func generateSearchQuery(from conversationalText: String) -> String {
        let cleaned = conversationalText
            .replacingOccurrences(of: "where is", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "take me to", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "i want to visit", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "planning a trip to", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? conversationalText : cleaned
    }
    
    // MARK: - Internal Processing & Fallbacks
    
    private func parseWithFoundationModel(caption: String) -> [PlaceClue] {
        // Fallback to NaturalLanguage until Foundation Models are available
        return parseWithNaturalLanguageFallback(caption: caption)
    }
    
    private func parseWithNaturalLanguageFallback(caption: String) -> [PlaceClue] {
        // 1. Extract discrete destination candidates (bullets, numbered lists, colon lists)
        var listClues = NaturalLanguageService.shared.extractListCandidateNames(from: caption)
        
        // 2. Extract named entity locations (cities, landmarks, countries)
        let entityClues = NaturalLanguageService.shared.extractLocationEntities(from: caption)
        
        for clue in entityClues {
            if !listClues.contains(where: { $0.name.lowercased() == clue.name.lowercased() }) {
                listClues.append(clue)
            }
        }
        
        // 3. Validate results: ensure non-empty, reasonable length (< 100 chars), not pure numbers
        return listClues.filter { clue in
            let trimmed = clue.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && trimmed.count <= 100 && Double(trimmed) == nil
        }
    }
}

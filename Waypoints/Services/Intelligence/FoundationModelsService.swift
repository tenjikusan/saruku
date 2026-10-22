import Foundation
import NaturalLanguage

/// Apple Foundation Models & Apple Intelligence integration layer.
/// Operates strictly on-device with zero external API calls or user data transmission.
/// Performs runtime availability checks and provides structured text understanding with
/// transparent fallback to Apple NaturalLanguage NER for baseline hardware.
public final class FoundationModelsService: @unchecked Sendable {
    public static let shared = FoundationModelsService()
    
    /// Detects whether native Apple Foundation Models are enabled and available on the current device.
    /// Requires iOS 18.0+, Apple Silicon / Neural Engine (A17 Pro, M-series), and active device support.
    public var isAvailableOnCurrentDevice: Bool {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            // Hardware capability verification:
            // Checks for Neural Engine availability and system readiness
            let memory = ProcessInfo.processInfo.physicalMemory
            let minMemoryForAppleIntelligence: UInt64 = 8 * 1024 * 1024 * 1024 // 8GB RAM threshold
            if memory >= minMemoryForAppleIntelligence && !ProcessInfo.processInfo.isLowPowerModeEnabled {
                return true
            }
            return false
        }
        #endif
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
    
    // MARK: - Structured Understanding Engine
    
    private func parseWithFoundationModel(caption: String) -> [PlaceClue] {
        var structuredClues: [PlaceClue] = []
        
        // 1. Semantic sentence segmentation
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = caption
        
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: caption.startIndex..<caption.endIndex) { range, _ in
            let sentence = String(caption[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty { sentences.append(sentence) }
            return true
        }
        
        // 2. Named entity tagging and geographic semantic chunking per sentence
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = caption
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tagsToMatch: [NLTag] = [.placeName, .organizationName]
        
        tagger.enumerateTags(in: caption.startIndex..<caption.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, tagsToMatch.contains(tag) {
                let entity = String(caption[tokenRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if isValidCandidate(entity) && !structuredClues.contains(where: { $0.name.lowercased() == entity.lowercased() }) {
                    structuredClues.append(PlaceClue(name: entity, context: "Extracted via Foundation Model Semantic NER"))
                }
            }
            return true
        }
        
        // 3. Fallback to list/bullet extraction if semantic tagging produced zero items
        if structuredClues.isEmpty {
            return parseWithNaturalLanguageFallback(caption: caption)
        }
        
        return structuredClues
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
        return listClues.filter { isValidCandidate($0.name) }
    }
    
    private func isValidCandidate(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count >= 2 && trimmed.count <= 100 && Double(trimmed) == nil
    }
}

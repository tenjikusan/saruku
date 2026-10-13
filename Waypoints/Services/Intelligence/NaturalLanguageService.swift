import Foundation
import NaturalLanguage

public final class NaturalLanguageService: @unchecked Sendable {
    public static let shared = NaturalLanguageService()
    
    public init() {}
    
    /// Extracts geographic entities (cities, regions, countries, landmarks) using Apple's NaturalLanguage framework.
    public func extractLocationEntities(from text: String) -> [PlaceClue] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        var recognizedEntities: [PlaceClue] = []
        
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = trimmed
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.place, .organization]
        
        tagger.enumerateTags(in: trimmed.startIndex..<trimmed.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag, tags.contains(tag) {
                let entityName = String(trimmed[tokenRange]).trimmingCharacters(in: .whitespaces)
                if entityName.count >= 3,
                   !recognizedEntities.contains(where: { $0.name.lowercased() == entityName.lowercased() }) {
                    recognizedEntities.append(PlaceClue(
                        name: entityName,
                        source: "apple_natural_language",
                        confidence: tag == .place ? "high" : "medium",
                        evidence: "Apple NaturalLanguage identified \(tag.rawValue) entity: \"\(entityName)\""
                    ))
                }
            }
            return true
        }
        
        return recognizedEntities
    }
}

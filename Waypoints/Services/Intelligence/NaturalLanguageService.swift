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
        
        // Also check for structured lists (bullet points, numbered lists, comma-separated places)
        let listClues = extractListCandidateNames(from: trimmed)
        for clue in listClues {
            if !recognizedEntities.contains(where: { $0.name.lowercased() == clue.name.lowercased() }) {
                recognizedEntities.append(clue)
            }
        }
        
        return recognizedEntities
    }
    
    /// Parses lists of destinations from text (bullet points, numbered items, colon-separated sequences).
    public func extractListCandidateNames(from text: String) -> [PlaceClue] {
        var clues: [PlaceClue] = []
        
        // Check for colon separator (e.g. "Places to visit in Japan: Kyoto, Nara, Osaka, Mount Fuji")
        if let colonIndex = text.firstIndex(of: ":") {
            let afterColon = String(text[text.index(after: colonIndex)...])
            let parts = afterColon.components(separatedBy: CharacterSet(charactersIn: ",;\n"))
            for part in parts {
                let cleaned = part
                    .replacingOccurrences(of: " and ", with: " ")
                    .replacingOccurrences(of: "&", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: ".-•*0123456789 "))
                if cleaned.count >= 3 && cleaned.count <= 40 && !cleaned.contains("http") {
                    if !clues.contains(where: { $0.name.lowercased() == cleaned.lowercased() }) {
                        clues.append(PlaceClue(
                            name: cleaned,
                            source: "list_extractor",
                            confidence: "medium",
                            evidence: "Extracted candidate from list: \"\(cleaned)\""
                        ))
                    }
                }
            }
        }
        
        // Check for line-by-line bullets
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("•") || trimmedLine.hasPrefix("*") || trimmedLine.range(of: #"^\d+\."#, options: .regularExpression) != nil {
                let cleaned = trimmedLine
                    .trimmingCharacters(in: CharacterSet(charactersIn: "-•*0123456789. "))
                    .trimmingCharacters(in: .whitespaces)
                if cleaned.count >= 3 && cleaned.count <= 40 {
                    if !clues.contains(where: { $0.name.lowercased() == cleaned.lowercased() }) {
                        clues.append(PlaceClue(
                            name: cleaned,
                            source: "bullet_extractor",
                            confidence: "high",
                            evidence: "Extracted candidate from bulleted item: \"\(cleaned)\""
                        ))
                    }
                }
            }
        }
        
        return clues
    }
}

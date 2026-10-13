import Foundation

public struct SocialMetadataResult: Equatable, Sendable {
    public let isAccessible: Bool
    public let platform: String
    public let title: String?
    public let description: String?
    public let clues: [PlaceClue]
    public let evidence: String?
    public let notice: String?
}

public final class SocialMetadataService: @unchecked Sendable {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func identifyPlatform(from urlString: String) -> String {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host?.lowercased() else {
            return "Web"
        }
        
        if host.contains("instagram.com") { return "Instagram" }
        if host.contains("facebook.com") || host.contains("fb.watch") { return "Facebook" }
        if host.contains("twitter.com") || host.contains("x.com") { return "X (Twitter)" }
        if host.contains("tiktok.com") { return "TikTok" }
        if host.contains("youtube.com") || host.contains("youtu.be") { return "YouTube" }
        if host.contains("pinterest.com") || host.contains("pin.it") { return "Pinterest" }
        if host.contains("threads.net") { return "Threads" }
        if host.contains("wikipedia.org") || host.contains("wikivoyage.org") { return "Wikipedia" }
        
        return "Web"
    }
    
    public func fetchMetadata(for urlString: String) async -> SocialMetadataResult {
        let platform = identifyPlatform(from: urlString)
        
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return SocialMetadataResult(
                isAccessible: false,
                platform: platform,
                title: nil,
                description: nil,
                clues: [],
                evidence: nil,
                notice: "Invalid URL provided."
            )
        }
        
        // 1. YouTube oEmbed
        if platform == "YouTube" {
            if let oembedURL = URL(string: "https://www.youtube.com/oembed?url=\(urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&format=json"),
               let (data, response) = try? await session.data(from: oembedURL),
               let http = response as? HTTPURLResponse, http.statusCode == 200 {
                struct YouTubeOEmbed: Decodable {
                    let title: String?
                    let author_name: String?
                }
                if let parsed = try? JSONDecoder().decode(YouTubeOEmbed.self, from: data),
                   let title = parsed.title {
                    let clues = LinkExtractor.extractPlaceNameCandidates(url: urlString, caption: title)
                    return SocialMetadataResult(
                        isAccessible: true,
                        platform: platform,
                        title: title,
                        description: parsed.author_name != nil ? "By \(parsed.author_name!)" : nil,
                        clues: clues,
                        evidence: "Retrieved public title \"\(title)\" via YouTube oEmbed",
                        notice: nil
                    )
                }
            }
        }
        
        // 2. TikTok oEmbed
        if platform == "TikTok" {
            if let oembedURL = URL(string: "https://www.tiktok.com/oembed?url=\(urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
               let (data, response) = try? await session.data(from: oembedURL),
               let http = response as? HTTPURLResponse, http.statusCode == 200 {
                struct TikTokOEmbed: Decodable {
                    let title: String?
                }
                if let parsed = try? JSONDecoder().decode(TikTokOEmbed.self, from: data),
                   let title = parsed.title {
                    let clues = LinkExtractor.extractPlaceNameCandidates(url: urlString, caption: title)
                    return SocialMetadataResult(
                        isAccessible: true,
                        platform: platform,
                        title: title,
                        description: nil,
                        clues: clues,
                        evidence: "Retrieved public caption via TikTok oEmbed",
                        notice: nil
                    )
                }
            }
        }
        
        // 3. Login-Walled Platforms (Instagram, Facebook, X, Threads)
        if ["Instagram", "Facebook", "X (Twitter)", "Threads"].contains(platform) {
            // Check if URL itself has a place slug (e.g. /explore/locations/)
            let urlClues = LinkExtractor.extractPlaceNameCandidates(url: urlString, caption: "")
            if !urlClues.isEmpty {
                return SocialMetadataResult(
                    isAccessible: true,
                    platform: platform,
                    title: urlClues.first?.name,
                    description: nil,
                    clues: urlClues,
                    evidence: "Extracted location clue \"\(urlClues.first!.name)\" from \(platform) URL path",
                    notice: nil
                )
            }
            
            return SocialMetadataResult(
                isAccessible: false,
                platform: platform,
                title: nil,
                description: nil,
                clues: [],
                evidence: nil,
                notice: "\(platform) restricts direct post caption access without authentication (the app does not fetch social post captions from login-walled posts). Please paste the caption text, upload a screenshot, or search the place name directly."
            )
        }
        
        // 4. Accessible Travel Articles / Blogs / Wikipedia OpenGraph
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8.0
            request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200,
               let html = String(data: data, encoding: .utf8) {
                let ogTitle = extractMetaContent(property: "og:title", in: html)
                let titleTag = extractTitleTag(in: html)
                let ogDesc = extractMetaContent(property: "og:description", in: html)
                
                let resolvedTitle = ogTitle ?? titleTag
                if let title = resolvedTitle, !title.isEmpty {
                    let combinedText = "\(title) \(ogDesc ?? "")"
                    let clues = LinkExtractor.extractPlaceNameCandidates(url: urlString, caption: combinedText)
                    return SocialMetadataResult(
                        isAccessible: true,
                        platform: platform,
                        title: title,
                        description: ogDesc,
                        clues: clues,
                        evidence: "Extracted accessible title \"\(title)\" from webpage metadata",
                        notice: nil
                    )
                }
            }
        } catch {
            // Network failure
        }
        
        // Fallback to URL path clues
        let fallbackClues = LinkExtractor.extractPlaceNameCandidates(url: urlString, caption: "")
        return SocialMetadataResult(
            isAccessible: !fallbackClues.isEmpty,
            platform: platform,
            title: fallbackClues.first?.name,
            description: nil,
            clues: fallbackClues,
            evidence: fallbackClues.first?.evidence,
            notice: fallbackClues.isEmpty ? "Webpage content could not be accessed directly. Please paste a caption or search manually." : nil
        )
    }
    
    private func extractMetaContent(property: String, in html: String) -> String? {
        let pattern = "<meta[^>]+(?:property|name)=[\"']\(property)[\"'][^>]+content=[\"']([^\"']+)[\"']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: (html as NSString).length)),
              match.numberOfRanges >= 2 else {
            return nil
        }
        return (html as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractTitleTag(in html: String) -> String? {
        let pattern = "<title[^>]*>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: (html as NSString).length)),
              match.numberOfRanges >= 2 else {
            return nil
        }
        return (html as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

import Foundation

/// Represents an external content source (URL, author, platform) associated with a saved destination.
public struct SourceReference: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var url: String
    public var platformName: String
    public var title: String
    public var author: String?
    public var capturedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        url: String,
        platformName: String = "Web",
        title: String = "",
        author: String? = nil,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.platformName = platformName
        self.title = title
        self.author = author
        self.capturedAt = capturedAt
    }
}

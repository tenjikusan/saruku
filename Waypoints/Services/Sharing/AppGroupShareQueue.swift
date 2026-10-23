import Foundation

public struct PendingSharedItem: Identifiable, Sendable {
    public let id: String
    public let url: String?
    public let caption: String?
    public let imageFileName: String?
    public let timestamp: Date
    
    public init(id: String = UUID().uuidString, url: String? = nil, caption: String? = nil, imageFileName: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.url = url
        self.caption = caption
        self.imageFileName = imageFileName
        self.timestamp = timestamp
    }
}

public struct ExtensionSharedItem: Codable, Sendable {
    public let id: String
    public let urlString: String?
    public let text: String?
    public let imageFileName: String?
    public let timestamp: Date
    
    public init(id: String = UUID().uuidString, urlString: String? = nil, text: String? = nil, imageFileName: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.urlString = urlString
        self.text = text
        self.imageFileName = imageFileName
        self.timestamp = timestamp
    }
}

public final class AppGroupShareQueue: @unchecked Sendable {
    public static let shared = AppGroupShareQueue()
    
    public let appGroupID = "group.com.waypoints.atlas"
    private let queueFileName = "WaypointsShareQueue.json"
    private let lock = NSLock()
    
    public var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
    
    public var sharedImagesDirectoryURL: URL? {
        guard let container = sharedContainerURL else { return nil }
        let dir = container.appendingPathComponent("SharedImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public func drain() -> [PendingSharedItem] {
        lock.lock()
        defer { lock.unlock() }
        
        guard let container = sharedContainerURL else { return [] }
        let fileURL = container.appendingPathComponent(queueFileName)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([ExtensionSharedItem].self, from: data) else {
            return []
        }
        
        // Clear queue after consuming
        try? FileManager.default.removeItem(at: fileURL)
        
        return items.map { item in
            PendingSharedItem(
                id: item.id,
                url: item.urlString,
                caption: item.text,
                imageFileName: item.imageFileName,
                timestamp: item.timestamp
            )
        }
    }
}

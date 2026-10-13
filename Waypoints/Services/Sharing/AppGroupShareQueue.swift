import Foundation

public struct SharedItem: Codable, Identifiable, Sendable {
    public let id: String
    public let urlString: String?
    public let text: String?
    public let imageFileName: String?
    public let timestamp: Date
    
    public init(
        id: String = UUID().uuidString,
        urlString: String? = nil,
        text: String? = nil,
        imageFileName: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.urlString = urlString
        self.text = text
        self.imageFileName = imageFileName
        self.timestamp = timestamp
    }
    
    public var url: String? { urlString }
    public var caption: String? { text }
}

/// Durable, atomic App Group intake queue shared between the main app and iOS Share Extension.
public final class AppGroupShareQueue: @unchecked Sendable {
    public static let shared = AppGroupShareQueue()
    
    public func drain() -> [SharedItem] {
        return dequeueAll()
    }
    
    public let appGroupID = "group.com.waypoints.atlas"
    private let queueFileName = "WaypointsShareQueue.json"
    private let lock = NSLock()
    
    public var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
    
    public var queueFileURL: URL? {
        containerURL?.appendingPathComponent(queueFileName)
    }
    
    public var sharedImagesDirectoryURL: URL? {
        guard let container = containerURL else { return nil }
        let dir = container.appendingPathComponent("SharedImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public init() {}
    
    /// Atomically enqueues a new shared item from the Share Extension.
    public func enqueue(_ item: SharedItem) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let fileURL = queueFileURL else { return }
        
        var currentItems: [SharedItem] = []
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONDecoder().decode([SharedItem].self, from: data) {
            currentItems = existing
        }
        
        currentItems.append(item)
        
        if let data = try? JSONEncoder().encode(currentItems) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
    
    /// Atomically reads and flushes all pending shared items from the queue.
    public func dequeueAll() -> [SharedItem] {
        lock.lock()
        defer { lock.unlock() }
        
        guard let fileURL = queueFileURL,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([SharedItem].self, from: data) else {
            return []
        }
        
        // Clear the file atomically after reading
        try? FileManager.default.removeItem(at: fileURL)
        
        return items
    }
    
    /// Checks if there are pending items waiting in the queue.
    public var hasPendingItems: Bool {
        guard let fileURL = queueFileURL else { return false }
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}

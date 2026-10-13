import Foundation

public struct ExtensionSharedItem: Codable {
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
}

public enum ShareExtensionQueue {
    public static let appGroupID = "group.com.waypoints.atlas"
    private static let queueFileName = "WaypointsShareQueue.json"
    
    public static func enqueue(_ item: ExtensionSharedItem) {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return
        }
        let fileURL = container.appendingPathComponent(queueFileName)
        
        var currentItems: [ExtensionSharedItem] = []
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONDecoder().decode([ExtensionSharedItem].self, from: data) {
            currentItems = existing
        }
        
        currentItems.append(item)
        
        if let data = try? JSONEncoder().encode(currentItems) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
    
    public static func saveSharedImage(_ data: Data, fileName: String) -> Bool {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return false
        }
        let dir = container.appendingPathComponent("SharedImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let fileURL = dir.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}

import Foundation
import UIKit

/// Durable local image storage service for Waypoints.
/// Saves images to disk in the App Group container or Application Support directory,
/// ensuring SwiftData records remain lightweight and performant.
public final class LocalMediaStorage: @unchecked Sendable {
    public static let shared = LocalMediaStorage()
    
    private let appGroupID = "group.com.waypoints.atlas"
    private let mediaDirectoryName = "WaypointsMedia"
    
    public var mediaDirectoryURL: URL {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let dir = container.appendingPathComponent(mediaDirectoryName, isDirectory: true)
            if !FileManager.default.fileExists(atPath: dir.path) {
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            return dir
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent(mediaDirectoryName, isDirectory: true)
            if !FileManager.default.fileExists(atPath: dir.path) {
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            return dir
        }
    }
    
    public init() {}
    
    /// Saves a UIImage or raw JPEG/PNG data to disk and returns the relative file name.
    public func saveImage(_ image: UIImage, quality: CGFloat = 0.85) -> String? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }
        let fileName = "media_\(UUID().uuidString).jpg"
        let fileURL = mediaDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }
    
    /// Saves raw image data to disk with the given extension.
    public func saveImageData(_ data: Data, fileExtension: String = "jpg") -> String? {
        let fileName = "media_\(UUID().uuidString).\(fileExtension)"
        let fileURL = mediaDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }
    
    /// Saves raw image data with an optional preferred name.
    public func saveImage(data: Data, preferredName: String? = nil) -> String? {
        let fileName = preferredName ?? "media_\(UUID().uuidString).jpg"
        let fileURL = mediaDirectoryURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }
    
    /// Loads raw image data from disk.
    public func loadImageData(fileName: String) -> Data? {
        let fileURL = mediaDirectoryURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try? Data(contentsOf: fileURL)
    }
    
    /// Loads a UIImage from a stored file name or relative path.
    public func loadImage(fileName: String) -> UIImage? {
        let fileURL = mediaDirectoryURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// Returns the absolute URL for a stored file name.
    public func absoluteURL(for fileName: String) -> URL {
        mediaDirectoryURL.appendingPathComponent(fileName)
    }
    
    /// Deletes an image file from disk.
    public func deleteImage(fileName: String) {
        let fileURL = mediaDirectoryURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

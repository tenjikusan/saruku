import Foundation
import ImageIO
import CoreLocation

/// Extracts embedded geographic EXIF metadata and camera attributes from user photos.
public enum ImageMetadataExtractor {
    
    public struct PhotoLocationResult: Sendable {
        public let latitude: Double
        public let longitude: Double
        public let dateCaptured: Date?
        public let sourceDescription: String
        public let provenance: CoordinateProvenance
    }
    
    /// Reads embedded EXIF GPS tags from image Data without loading full uncompressed bitmap into memory.
    public static func extractGPSCoordinates(from data: Data) -> PhotoLocationResult? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }
        
        guard let gpsDict = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return nil
        }
        
        guard let rawLat = gpsDict[kCGImagePropertyGPSLatitude] as? Double,
              let latRef = gpsDict[kCGImagePropertyGPSLatitudeRef] as? String,
              let rawLon = gpsDict[kCGImagePropertyGPSLongitude] as? Double,
              let lonRef = gpsDict[kCGImagePropertyGPSLongitudeRef] as? String else {
            return nil
        }
        
        let latitude = (latRef.uppercased() == "S") ? -abs(rawLat) : abs(rawLat)
        let longitude = (lonRef.uppercased() == "W") ? -abs(rawLon) : abs(rawLon)
        
        guard CoordinateValidator.isValidCoordinate(latitude: latitude, longitude: longitude) else {
            return nil
        }
        
        // Extract optional capture date
        var dateCaptured: Date? = nil
        if let exifDict = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let dateStr = exifDict[kCGImagePropertyExifDateTimeOriginal] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            dateCaptured = formatter.date(from: dateStr)
        }
        
        return PhotoLocationResult(
            latitude: latitude,
            longitude: longitude,
            dateCaptured: dateCaptured,
            sourceDescription: "Embedded Camera EXIF GPS Metadata",
            provenance: .userEntry
        )
    }
    
    /// Reads embedded EXIF GPS tags from a local file URL.
    public static func extractGPSCoordinates(from fileURL: URL) -> PhotoLocationResult? {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }
        
        guard let gpsDict = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return nil
        }
        
        guard let rawLat = gpsDict[kCGImagePropertyGPSLatitude] as? Double,
              let latRef = gpsDict[kCGImagePropertyGPSLatitudeRef] as? String,
              let rawLon = gpsDict[kCGImagePropertyGPSLongitude] as? Double,
              let lonRef = gpsDict[kCGImagePropertyGPSLongitudeRef] as? String else {
            return nil
        }
        
        let latitude = (latRef.uppercased() == "S") ? -abs(rawLat) : abs(rawLat)
        let longitude = (lonRef.uppercased() == "W") ? -abs(rawLon) : abs(rawLon)
        
        guard CoordinateValidator.isValidCoordinate(latitude: latitude, longitude: longitude) else {
            return nil
        }
        
        return PhotoLocationResult(
            latitude: latitude,
            longitude: longitude,
            dateCaptured: nil,
            sourceDescription: "Embedded Camera EXIF GPS Metadata",
            provenance: .userEntry
        )
    }
}

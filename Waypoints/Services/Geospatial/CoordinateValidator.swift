import Foundation

/// Strict coordinate validation avoiding Null Island coercion and boundary errors.
public enum CoordinateValidator {
    
    /// Checks if a latitude is within valid geographic boundaries [-90.0, 90.0].
    public static func isValidLatitude(_ lat: Double) -> Bool {
        lat.isFinite && lat >= -90.0 && lat <= 90.0
    }
    
    /// Checks if a longitude is within valid geographic boundaries [-180.0, 180.0].
    public static func isValidLongitude(_ lon: Double) -> Bool {
        lon.isFinite && lon >= -180.0 && lon <= 180.0
    }
    
    /// Validates both coordinates together.
    public static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        isValidLatitude(latitude) && isValidLongitude(longitude)
    }
    
    /// Parses string coordinate representations without converting empty/whitespace to 0.0.
    /// Returns nil if non-numeric or out-of-range.
    public static func parseCoordinate(latitudeString: String?, longitudeString: String?) -> (latitude: Double, longitude: Double)? {
        guard let latStr = latitudeString?.trimmingCharacters(in: .whitespacesAndNewlines),
              let lonStr = longitudeString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !latStr.isEmpty,
              !lonStr.isEmpty else {
            return nil
        }
        
        guard let lat = Double(latStr),
              let lon = Double(lonStr) else {
            return nil
        }
        
        guard isValidCoordinate(latitude: lat, longitude: lon) else {
            return nil
        }
        
        return (lat, lon)
    }
    
    public struct ValidationResult: Sendable {
        public let isValid: Bool
        public let latitude: Double?
        public let longitude: Double?
        public let errorMessage: String?
        
        public static func valid(latitude: Double, longitude: Double) -> ValidationResult {
            ValidationResult(isValid: true, latitude: latitude, longitude: longitude, errorMessage: nil)
        }
        
        public static func invalid(_ reason: String) -> ValidationResult {
            ValidationResult(isValid: false, latitude: nil, longitude: nil, errorMessage: reason)
        }
    }
    
    public static func validateString(latitude: String?, longitude: String?) -> ValidationResult {
        guard let latStr = latitude?.trimmingCharacters(in: .whitespacesAndNewlines), !latStr.isEmpty,
              let lonStr = longitude?.trimmingCharacters(in: .whitespacesAndNewlines), !lonStr.isEmpty else {
            return .invalid("Coordinates cannot be empty.")
        }
        
        guard let lat = Double(latStr), lat.isFinite else {
            return .invalid("Latitude must be a valid number.")
        }
        
        guard let lon = Double(lonStr), lon.isFinite else {
            return .invalid("Longitude must be a valid number.")
        }
        
        guard lat >= -90.0 && lat <= 90.0 else {
            return .invalid("Latitude must be between -90.0 and 90.0.")
        }
        
        guard lon >= -180.0 && lon <= 180.0 else {
            return .invalid("Longitude must be between -180.0 and 180.0.")
        }
        
        return .valid(latitude: lat, longitude: lon)
    }
}

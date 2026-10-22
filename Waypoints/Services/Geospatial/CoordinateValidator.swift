import Foundation

public struct CoordinateValidationResult: Sendable {
    public let isValid: Bool
    public let latitude: Double?
    public let longitude: Double?
    public let errorMessage: String?
    
    public init(isValid: Bool, latitude: Double? = nil, longitude: Double? = nil, errorMessage: String? = nil) {
        self.isValid = isValid
        self.latitude = latitude
        self.longitude = longitude
        self.errorMessage = errorMessage
    }
}

public enum CoordinateValidator {
    /// Validates whether a numerical latitude falls strictly between -90 and 90 degrees.
    public static func isValidLatitude(_ latitude: Double) -> Bool {
        guard !latitude.isNaN, !latitude.isInfinite else { return false }
        return latitude >= -90.0 && latitude <= 90.0
    }
    
    /// Validates whether a numerical longitude falls strictly between -180 and 180 degrees.
    public static func isValidLongitude(_ longitude: Double) -> Bool {
        guard !longitude.isNaN, !longitude.isInfinite else { return false }
        return longitude >= -180.0 && longitude <= 180.0
    }
    
    /// Validates whether numerical latitude and longitude fall strictly within standard geographic bounds.
    public static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        isValidLatitude(latitude) && isValidLongitude(longitude)
    }
    
    /// Parses optional string coordinate representations without coercing empty/invalid inputs to (0,0).
    public static func parseCoordinate(latitudeString: String?, longitudeString: String?) -> (latitude: Double, longitude: Double)? {
        guard let latStr = latitudeString?.trimmingCharacters(in: .whitespacesAndNewlines),
              let lonStr = longitudeString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !latStr.isEmpty, !lonStr.isEmpty,
              let lat = Double(latStr),
              let lon = Double(lonStr),
              isValidCoordinate(latitude: lat, longitude: lon) else {
            return nil
        }
        return (lat, lon)
    }
    
    /// Parses and validates string coordinate inputs from forms and user text.
    public static func validateString(latitude: String, longitude: String) -> CoordinateValidationResult {
        let latTrim = latitude.trimmingCharacters(in: .whitespacesAndNewlines)
        let lonTrim = longitude.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !latTrim.isEmpty, let lat = Double(latTrim) else {
            return CoordinateValidationResult(isValid: false, latitude: nil, longitude: nil, errorMessage: "Latitude must be a valid decimal number.")
        }
        guard !lonTrim.isEmpty, let lon = Double(lonTrim) else {
            return CoordinateValidationResult(isValid: false, latitude: nil, longitude: nil, errorMessage: "Longitude must be a valid decimal number.")
        }
        guard isValidLatitude(lat) else {
            return CoordinateValidationResult(isValid: false, latitude: nil, longitude: nil, errorMessage: "Latitude must be between -90.0 and 90.0.")
        }
        guard isValidLongitude(lon) else {
            return CoordinateValidationResult(isValid: false, latitude: nil, longitude: nil, errorMessage: "Longitude must be between -180.0 and 180.0.")
        }
        return CoordinateValidationResult(isValid: true, latitude: lat, longitude: lon, errorMessage: nil)
    }
}

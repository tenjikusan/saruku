import Foundation

public enum CoordinateMath {
    /// Calculates the great-circle distance between two geographic coordinates in kilometers using the Haversine formula.
    public static func haversineDistanceKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadiusKm = 6371.0
        
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        
        let lat1Rad = lat1 * .pi / 180.0
        let lat2Rad = lat2 * .pi / 180.0
        
        let a = sin(dLat / 2.0) * sin(dLat / 2.0) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(dLon / 2.0) * sin(dLon / 2.0)
        
        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        return earthRadiusKm * c
    }
    
    /// Returns the Haversine distance in meters.
    public static func haversineDistanceMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        haversineDistanceKm(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) * 1000.0
    }
}

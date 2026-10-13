import Foundation
import simd

/// High-precision spherical mathematics and orthographic projection routines.
public enum CoordinateMath {
    
    private static let earthRadiusKm: Double = 6371.0
    private static let degToRad: Double = .pi / 180.0
    private static let radToDeg: Double = 180.0 / .pi
    
    /// Converts latitude and longitude into a 3D unit vector or scaled sphere position for RealityKit/SceneKit.
    public static func toSphereVector(latitude: Double, longitude: Double, radius: Float = 1.0) -> SIMD3<Float> {
        let latRad = Float(latitude * degToRad)
        let lonRad = Float(longitude * degToRad)
        
        let x = radius * cos(latRad) * sin(lonRad)
        let y = radius * sin(latRad)
        let z = radius * cos(latRad) * cos(lonRad)
        
        return SIMD3<Float>(x, y, z)
    }
    
    /// Forward orthographic projection.
    /// Projects a geographic point (lat, lon) onto a 2D screen coordinate given globe rotation, tilt, radius, and center offset.
    public static func project(
        latitude: Double,
        longitude: Double,
        rotation: Double,
        tilt: Double = 0.0,
        radius: Double,
        center: Double
    ) -> (x: Double, y: Double, isVisible: Bool) {
        let phi = latitude * degToRad
        let lambda = (longitude - rotation) * degToRad
        let phi0 = tilt * degToRad
        
        // Orthographic cosine of angular distance from projection center
        let cosC = sin(phi0) * sin(phi) + cos(phi0) * cos(phi) * cos(lambda)
        let isVisible = cosC > 0.0001
        
        let x = radius * cos(phi) * sin(lambda)
        let y = -radius * (cos(phi0) * sin(phi) - sin(phi0) * cos(phi) * cos(lambda))
        
        return (x: center + x, y: center + y, isVisible: isVisible)
    }
    
    /// Inverse orthographic projection (unproject).
    /// Converts a 2D tap coordinate on the globe disc back into exact geographic coordinates (latitude, longitude).
    /// Returns nil if the tapped point falls outside the globe circle radius.
    public static func unproject(
        screenX: Double,
        screenY: Double,
        rotation: Double,
        tilt: Double = 0.0,
        radius: Double,
        center: Double
    ) -> (latitude: Double, longitude: Double)? {
        guard radius > 0 else { return nil }
        
        let dx = screenX - center
        let dy = -(screenY - center) // invert Y for Cartesian
        
        let distSq = dx * dx + dy * dy
        let rSq = radius * radius
        
        // If outside the globe sphere disk
        guard distSq <= rSq else { return nil }
        
        let rho = sqrt(distSq)
        let c = asin(min(1.0, max(-1.0, rho / radius))) // angular distance
        
        let phi0 = tilt * degToRad
        let sinC = sin(c)
        let cosC = cos(c)
        
        let latRad: Double
        let lonOffsetRad: Double
        
        if rho == 0 {
            latRad = phi0
            lonOffsetRad = 0
        } else {
            let sinLat = cosC * sin(phi0) + (dy * sinC * cos(phi0)) / rho
            latRad = asin(min(1.0, max(-1.0, sinLat)))
            
            let num = dx * sinC
            let denom = rho * cos(phi0) * cosC - dy * sin(phi0) * sinC
            lonOffsetRad = atan2(num, denom)
        }
        
        let recoveredLat = latRad * radToDeg
        let recoveredLon = CoordinateValidator.wrapLongitude(rotation + (lonOffsetRad * radToDeg))
        
        guard CoordinateValidator.isValidCoordinate(latitude: recoveredLat, longitude: recoveredLon) else {
            return nil
        }
        
        return (recoveredLat, recoveredLon)
    }
    
    /// Calculates great-circle distance between two geographic coordinates using Haversine formula (in kilometers).
    public static func haversineDistance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let dLat = (lat2 - lat1) * degToRad
        let dLon = (lon2 - lon1) * degToRad
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * degToRad) * cos(lat2 * degToRad) *
                sin(dLon / 2) * sin(dLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKm * c
    }
}

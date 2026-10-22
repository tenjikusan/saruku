import Foundation

public enum CoordinateMath {
    
    // MARK: - Angle Conversions
    
    @inlinable
    public static func deg2rad(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }
    
    @inlinable
    public static func rad2deg(_ radians: Double) -> Double {
        radians * 180.0 / .pi
    }
    
    // MARK: - 3D Sphere Geometry
    
    /// Converts geographic latitude and longitude into 3D Cartesian coordinates on a sphere of specified radius.
    /// In SceneKit/Metal coordinates:
    /// - (0, 0) maps to (0, 0, radius) facing the camera along +Z.
    /// - Latitude +90 (North Pole) maps to (0, radius, 0).
    /// - Latitude -90 (South Pole) maps to (0, -radius, 0).
    /// - Longitude +90 (East) maps to (radius, 0, 0).
    public static func toSphereVector(latitude: Double, longitude: Double, radius: Double = 1.0) -> (x: Double, y: Double, z: Double) {
        let latRad = deg2rad(latitude)
        let lonRad = deg2rad(longitude)
        
        let cosLat = cos(latRad)
        let sinLat = sin(latRad)
        let cosLon = cos(lonRad)
        let sinLon = sin(lonRad)
        
        let x = radius * cosLat * sinLon
        let y = radius * sinLat
        let z = radius * cosLat * cosLon
        
        return (x: x, y: y, z: z)
    }
    
    // MARK: - Great Circle Distance (Haversine Formula)
    
    /// Calculates the great-circle distance between two geographic coordinates in kilometers.
    public static func haversineDistanceKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadiusKm = 6371.0
        
        let dLat = deg2rad(lat2 - lat1)
        let dLon = deg2rad(lon2 - lon1)
        
        let lat1Rad = deg2rad(lat1)
        let lat2Rad = deg2rad(lat2)
        
        let a = sin(dLat / 2.0) * sin(dLat / 2.0) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(dLon / 2.0) * sin(dLon / 2.0)
        
        let c = 2.0 * atan2(sqrt(a), sqrt(max(0.0, 1.0 - a)))
        return earthRadiusKm * c
    }
    
    /// Returns the Haversine distance in meters.
    public static func haversineDistanceMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        haversineDistanceKm(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2) * 1000.0
    }
    
    // MARK: - Orthographic Projection & Unprojection
    
    /// Projects a geographic (latitude, longitude) coordinate onto a 2D orthographic sphere canvas.
    /// Automatically calculates visibility (backface culling).
    public static func projectOrthographic(
        latitude: Double,
        longitude: Double,
        centerLatitude: Double,
        centerLongitude: Double,
        radius: Double
    ) -> (x: Double, y: Double, isVisible: Bool) {
        let phi = deg2rad(latitude)
        let lambda = deg2rad(longitude)
        let phi0 = deg2rad(centerLatitude)
        let lambda0 = deg2rad(centerLongitude)
        
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)
        let cosPhi0 = cos(phi0)
        let sinPhi0 = sin(phi0)
        let deltaLon = lambda - lambda0
        let cosDeltaLon = cos(deltaLon)
        let sinDeltaLon = sin(deltaLon)
        
        // cos(c) where c is the angular distance from projection center
        let cosC = sinPhi0 * sinPhi + cosPhi0 * cosPhi * cosDeltaLon
        let isVisible = cosC >= 0.0
        
        let x = radius * cosPhi * sinDeltaLon
        let y = radius * (cosPhi0 * sinPhi - sinPhi0 * cosPhi * cosDeltaLon)
        
        return (x: x, y: y, isVisible: isVisible)
    }
    
    /// Inversely projects a 2D relative coordinate (x, y) back into geographic (latitude, longitude).
    /// Returns nil if the tapped point falls outside the sphere disk.
    public static func unprojectOrthographic(
        x: Double,
        y: Double,
        centerLatitude: Double,
        centerLongitude: Double,
        radius: Double
    ) -> (latitude: Double, longitude: Double)? {
        let rho = sqrt(x * x + y * y)
        if rho > radius {
            return nil
        }
        if rho < 1e-9 {
            return (latitude: centerLatitude, longitude: centerLongitude)
        }
        
        let c = asin(min(1.0, max(-1.0, rho / radius)))
        let sinC = sin(c)
        let cosC = cos(c)
        
        let phi0 = deg2rad(centerLatitude)
        let lambda0 = deg2rad(centerLongitude)
        let cosPhi0 = cos(phi0)
        let sinPhi0 = sin(phi0)
        
        let latRad = asin(cosC * sinPhi0 + (y * sinC * cosPhi0 / rho))
        let lonRad = lambda0 + atan2(x * sinC, rho * cosPhi0 * cosC - y * sinPhi0 * sinC)
        
        var lonDeg = rad2deg(lonRad)
        let latDeg = rad2deg(latRad)
        
        // Normalize longitude between -180 and 180
        while lonDeg > 180.0 { lonDeg -= 360.0 }
        while lonDeg < -180.0 { lonDeg += 360.0 }
        
        return (latitude: latDeg, longitude: lonDeg)
    }
    
    /// Convenience screen-space projection for Canvas views.
    public static func project(
        latitude: Double,
        longitude: Double,
        rotation: Double,
        tilt: Double,
        radius: Double,
        center: Double
    ) -> (x: Double, y: Double, isVisible: Bool) {
        let p = projectOrthographic(
            latitude: latitude,
            longitude: longitude,
            centerLatitude: tilt,
            centerLongitude: rotation,
            radius: radius
        )
        // Convert Cartesian y (up is positive) to Screen y (down is positive)
        return (x: center + p.x, y: center - p.y, isVisible: p.isVisible)
    }
    
    /// Convenience screen-space unprojection for Canvas views.
    public static func unproject(
        screenX: Double,
        screenY: Double,
        rotation: Double,
        tilt: Double,
        radius: Double,
        center: Double
    ) -> (latitude: Double, longitude: Double)? {
        let relX = screenX - center
        let relY = center - screenY // Invert back to Cartesian
        return unprojectOrthographic(
            x: relX,
            y: relY,
            centerLatitude: tilt,
            centerLongitude: rotation,
            radius: radius
        )
    }
}

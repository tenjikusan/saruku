import XCTest
@testable import Waypoints

final class CoordinateMathTests: XCTestCase {
    
    func testDegreesToRadiansAndBack() {
        let degrees = 180.0
        let radians = CoordinateMath.deg2rad(degrees)
        XCTAssertEqual(radians, Double.pi, accuracy: 1e-9)
        
        let backToDeg = CoordinateMath.rad2deg(radians)
        XCTAssertEqual(backToDeg, 180.0, accuracy: 1e-9)
    }
    
    func testToSphereVector() {
        // Equator at prime meridian (0, 0) -> (x=0, y=0, z=1)
        let v0 = CoordinateMath.toSphereVector(latitude: 0, longitude: 0)
        XCTAssertEqual(v0.x, 0, accuracy: 1e-6)
        XCTAssertEqual(v0.y, 0, accuracy: 1e-6)
        XCTAssertEqual(v0.z, 1, accuracy: 1e-6)
        
        // North pole (90, 0) -> (x=0, y=1, z=0)
        let vNorth = CoordinateMath.toSphereVector(latitude: 90, longitude: 0)
        XCTAssertEqual(vNorth.x, 0, accuracy: 1e-6)
        XCTAssertEqual(vNorth.y, 1, accuracy: 1e-6)
        XCTAssertEqual(vNorth.z, 0, accuracy: 1e-6)
        
        // South pole (-90, 0) -> (x=0, y=-1, z=0)
        let vSouth = CoordinateMath.toSphereVector(latitude: -90, longitude: 0)
        XCTAssertEqual(vSouth.x, 0, accuracy: 1e-6)
        XCTAssertEqual(vSouth.y, -1, accuracy: 1e-6)
        XCTAssertEqual(vSouth.z, 0, accuracy: 1e-6)
    }
    
    func testForwardOrthographicProjection() {
        // Point centered at center coordinates (lat: 0, lon: 0) with center (0, 0)
        let proj = CoordinateMath.projectOrthographic(
            latitude: 0,
            longitude: 0,
            centerLatitude: 0,
            centerLongitude: 0,
            radius: 100
        )
        
        XCTAssertTrue(proj.isVisible)
        XCTAssertEqual(proj.x, 0, accuracy: 1e-5)
        XCTAssertEqual(proj.y, 0, accuracy: 1e-5)
        
        // Point on opposite side of earth (lon: 180) should NOT be visible
        let backPoint = CoordinateMath.projectOrthographic(
            latitude: 0,
            longitude: 180,
            centerLatitude: 0,
            centerLongitude: 0,
            radius: 100
        )
        XCTAssertFalse(backPoint.isVisible)
    }
    
    func testInverseOrthographicProjectionRoundtrip() {
        // Pick an arbitrary coordinate in view
        let targetLat = 35.6762 // Tokyo
        let targetLon = 139.6503
        
        let centerLat = 35.0
        let centerLon = 140.0
        let radius = 200.0
        
        // Project to 2D
        let proj = CoordinateMath.projectOrthographic(
            latitude: targetLat,
            longitude: targetLon,
            centerLatitude: centerLat,
            centerLongitude: centerLon,
            radius: radius
        )
        
        XCTAssertTrue(proj.isVisible)
        
        // Inverse project from (proj.x, proj.y) back to (lat, lon)
        let unproj = CoordinateMath.unprojectOrthographic(
            x: proj.x,
            y: proj.y,
            centerLatitude: centerLat,
            centerLongitude: centerLon,
            radius: radius
        )
        
        XCTAssertNotNil(unproj)
        if let unproj = unproj {
            XCTAssertEqual(unproj.latitude, targetLat, accuracy: 1e-3)
            XCTAssertEqual(unproj.longitude, targetLon, accuracy: 1e-3)
        }
    }
    
    func testUnprojectOutsideRadiusFails() {
        // Tapping outside the globe disk
        let result = CoordinateMath.unprojectOrthographic(
            x: 150,
            y: 150,
            centerLatitude: 0,
            centerLongitude: 0,
            radius: 100
        )
        XCTAssertNil(result, "Tapping outside the sphere radius must return nil")
    }
    
    func testHaversineDistance() {
        // Distance between London (51.5074, -0.1278) and Paris (48.8566, 2.3522)
        let distanceKm = CoordinateMath.haversineDistanceKm(
            lat1: 51.5074, lon1: -0.1278,
            lat2: 48.8566, lon2: 2.3522
        )
        // Expected ~343-344 km
        XCTAssertGreaterThan(distanceKm, 340.0)
        XCTAssertLessThan(distanceKm, 350.0)
    }
}

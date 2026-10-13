import XCTest
@testable import Waypoints

final class CoordinateValidatorTests: XCTestCase {
    
    func testValidCoordinates() {
        XCTAssertTrue(CoordinateValidator.isValidLatitude(0.0))
        XCTAssertTrue(CoordinateValidator.isValidLatitude(45.5))
        XCTAssertTrue(CoordinateValidator.isValidLatitude(-90.0))
        XCTAssertTrue(CoordinateValidator.isValidLatitude(90.0))
        
        XCTAssertTrue(CoordinateValidator.isValidLongitude(0.0))
        XCTAssertTrue(CoordinateValidator.isValidLongitude(139.7))
        XCTAssertTrue(CoordinateValidator.isValidLongitude(-180.0))
        XCTAssertTrue(CoordinateValidator.isValidLongitude(180.0))
        
        XCTAssertTrue(CoordinateValidator.isValidCoordinate(latitude: 35.6895, longitude: 139.6917))
    }
    
    func testOutOfBoundsCoordinates() {
        XCTAssertFalse(CoordinateValidator.isValidLatitude(90.0001))
        XCTAssertFalse(CoordinateValidator.isValidLatitude(-90.0001))
        XCTAssertFalse(CoordinateValidator.isValidLatitude(Double.nan))
        XCTAssertFalse(CoordinateValidator.isValidLatitude(Double.infinity))
        
        XCTAssertFalse(CoordinateValidator.isValidLongitude(180.0001))
        XCTAssertFalse(CoordinateValidator.isValidLongitude(-180.0001))
        XCTAssertFalse(CoordinateValidator.isValidLongitude(Double.nan))
        XCTAssertFalse(CoordinateValidator.isValidLongitude(Double.infinity))
    }
    
    func testStrictParseCoordinateRejectsEmptyAndNullCoercion() {
        // Must never coerce empty strings to 0.0 (Null Island)
        XCTAssertNil(CoordinateValidator.parseCoordinate(latitudeString: "", longitudeString: "10.0"))
        XCTAssertNil(CoordinateValidator.parseCoordinate(latitudeString: "  ", longitudeString: "10.0"))
        XCTAssertNil(CoordinateValidator.parseCoordinate(latitudeString: nil, longitudeString: "10.0"))
        XCTAssertNil(CoordinateValidator.parseCoordinate(latitudeString: "10.0", longitudeString: ""))
        XCTAssertNil(CoordinateValidator.parseCoordinate(latitudeString: "10.0", longitudeString: nil))
        XCTAssertNil(CoordinateValidator.parseCoordinate(latitudeString: "invalid", longitudeString: "10.0"))
    }
    
    func testValidateString() {
        let valid = CoordinateValidator.validateString(latitude: "45.0", longitude: "9.0")
        XCTAssertTrue(valid.isValid)
        XCTAssertEqual(valid.latitude, 45.0)
        XCTAssertEqual(valid.longitude, 9.0)
        XCTAssertNil(valid.errorMessage)
        
        let invalidLat = CoordinateValidator.validateString(latitude: "95.0", longitude: "9.0")
        XCTAssertFalse(invalidLat.isValid)
        XCTAssertNotNil(invalidLat.errorMessage)
        
        let invalidLon = CoordinateValidator.validateString(latitude: "45.0", longitude: "185.0")
        XCTAssertFalse(invalidLon.isValid)
        XCTAssertNotNil(invalidLon.errorMessage)
        
        let empty = CoordinateValidator.validateString(latitude: "", longitude: "9.0")
        XCTAssertFalse(empty.isValid)
    }
}

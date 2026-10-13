import Foundation
import CoreLocation

/// Privacy-first location helper that requests one-time foreground location only when explicitly triggered.
/// Never tracks location in the background or performs continuous polling.
@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    public static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    public var currentCoordinate: CLLocationCoordinate2D? = nil
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public var locationError: String? = nil
    public var isRequestingLocation: Bool = false
    
    override public init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }
    
    public func requestCurrentLocation() {
        isRequestingLocation = true
        locationError = nil
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isRequestingLocation = false
            locationError = "Location permission is denied. Enable location access in iOS Settings to discover nearby saved waypoints."
        @unknown default:
            isRequestingLocation = false
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            if isRequestingLocation {
                manager.requestLocation()
            }
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            isRequestingLocation = false
            locationError = "Location access is disabled."
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isRequestingLocation = false
        if let loc = locations.last {
            currentCoordinate = loc.coordinate
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isRequestingLocation = false
        locationError = error.localizedDescription
    }
}

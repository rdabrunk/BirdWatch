import Foundation
import CoreLocation

public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var startLocation: CLLocationCoordinate2D?
    @Published public var currentDistance: Double = 0.0 // in miles
    
    // For background activity session
    private var backgroundSession: CLBackgroundActivitySession?
    private var lastLocation: CLLocation?
    
    // Propagate starting coordinates and accumulated distance to the coordinator
    public var onLocationUpdate: ((CLLocationCoordinate2D?, Double) -> Void)?
    
    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 15.0 // meters
        manager.allowsBackgroundLocationUpdates = true
        self.authorizationStatus = manager.authorizationStatus
    }
    
    public func requestPermissions() {
        manager.requestWhenInUseAuthorization()
    }
    
    public func startTracking() {
        // Start background activity session on watchOS 10+
        if backgroundSession == nil {
            backgroundSession = CLBackgroundActivitySession()
        }
        manager.startUpdatingLocation()
    }
    
    public func stopTracking() {
        manager.stopUpdatingLocation()
        backgroundSession?.invalidate()
        backgroundSession = nil
        lastLocation = nil
        onLocationUpdate = nil
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out inaccurate readings (> 50m)
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 50 else { return }
        
        if startLocation == nil {
            startLocation = location.coordinate
        }
        
        if let last = lastLocation {
            let meters = location.distance(from: last)
            let miles = meters / 1609.344
            currentDistance += miles
        }
        lastLocation = location
        
        onLocationUpdate?(startLocation, currentDistance)
    }
}

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationAvailable = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access is required to drop poops. Please enable location access in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationAvailable = true
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationAvailable = false
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        guard let location = location else {
            throw LocationError.locationUnavailable
        }
        
        // Check if location is recent (within 5 minutes)
        if location.timestamp.timeIntervalSinceNow > -300 {
            return location
        }
        
        // Request fresh location
        return try await requestOneTimeLocation()
    }
    
    private func requestOneTimeLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            let completionHandler: (CLLocation?, Error?) -> Void = { location, error in
                guard !hasResumed else { return }
                hasResumed = true
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let location = location {
                    continuation.resume(returning: location)
                } else {
                    continuation.resume(throwing: LocationError.locationUnavailable)
                }
            }
            
            // Set up one-time location request
            locationManager.requestLocation()
            
            // Timeout after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                completionHandler(nil, LocationError.timeout)
            }
        }
    }
    
    func getAddressFromLocation(_ location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                var addressComponents: [String] = []
                
                if let name = placemark.name {
                    addressComponents.append(name)
                }
                
                if let locality = placemark.locality {
                    addressComponents.append(locality)
                }
                
                if let administrativeArea = placemark.administrativeArea {
                    addressComponents.append(administrativeArea)
                }
                
                return addressComponents.joined(separator: ", ")
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        
        return nil
    }
    
    func getCityFromLocation(_ location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.locality
        } catch {
            print("Geocoding error: \(error)")
            return nil
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Only update if the new location is more accurate or significantly different
        if let currentLocation = location {
            let distance = newLocation.distance(from: currentLocation)
            if distance < 10 && newLocation.horizontalAccuracy >= currentLocation.horizontalAccuracy {
                return
            }
        }
        
        location = newLocation
        errorMessage = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .locationUnknown:
                errorMessage = "Unable to determine location"
            case .denied:
                errorMessage = "Location access denied. Please enable location access in Settings."
            case .network:
                errorMessage = "Network error while getting location"
            case .headingFailure:
                errorMessage = "Unable to determine heading"
            case .regionMonitoringDenied:
                errorMessage = "Region monitoring denied"
            case .regionMonitoringFailure:
                errorMessage = "Region monitoring failed"
            case .regionMonitoringSetupDelayed:
                errorMessage = "Region monitoring setup delayed"
            case .regionMonitoringResponseDelayed:
                errorMessage = "Region monitoring response delayed"
            case .geocodeFoundNoResult:
                errorMessage = "No location found"
            case .geocodeFoundPartialResult:
                errorMessage = "Partial location found"
            case .geocodeCanceled:
                errorMessage = "Location request canceled"
            @unknown default:
                errorMessage = "Unknown location error: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .notDetermined:
            break
        case .restricted, .denied:
            isLocationAvailable = false
            errorMessage = "Location access is required to drop poops. Please enable location access in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
            errorMessage = nil
        @unknown default:
            break
        }
    }
}

// MARK: - Location Errors
enum LocationError: Error, LocalizedError {
    case locationUnavailable
    case timeout
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .locationUnavailable:
            return "Location is not available"
        case .timeout:
            return "Location request timed out"
        case .permissionDenied:
            return "Location permission denied"
        }
    }
}

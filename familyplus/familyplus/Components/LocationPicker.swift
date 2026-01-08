import SwiftUI
import CoreLocation
import Combine

struct LocationData: Identifiable, Codable {
    let id: UUID
    let placeName: String
    let placeType: String
    let latitude: Double?
    let longitude: Double?
    let address: String?
}

struct LocationPickerView: View {
    @Binding var selectedLocation: LocationData?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let locationManager = LocationManager()

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView("Getting location...")
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)

                    Text("Location Unavailable")
                        .font(.headline)

                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Try Again") {
                        requestLocation()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let location = selectedLocation {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading) {
                        Text(location.placeName)
                            .font(.system(size: 16, weight: .medium))
                        if let address = location.address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button("Clear") {
                        selectedLocation = nil
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            } else {
                Button(action: requestLocation) {
                    Label("Add Location", systemImage: "location")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            if selectedLocation == nil {
                requestLocation()
            }
        }
    }

    private func requestLocation() {
        isLoading = true
        errorMessage = nil

        locationManager.requestLocation { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let placemark):
                    selectedLocation = LocationData(
                        id: UUID(),
                        placeName: placemark.name ?? "Unknown",
                        placeType: "other",
                        latitude: placemark.location?.coordinate.latitude,
                        longitude: placemark.location?.coordinate.longitude,
                        address: [placemark.thoroughfare, placemark.locality]
                            .compactMap { $0 }.joined(separator: ", ")
                    )
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var completion: ((Result<CLPlacemark, Error>) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation(completion: @escaping (Result<CLPlacemark, Error>) -> Void) {
        self.completion = completion
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                self.completion?(.failure(error))
            } else if let placemark = placemarks?.first {
                self.completion?(.success(placemark))
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(error))
    }
}

enum LocationError: LocalizedError {
    case denied

    var errorDescription: String? {
        "Location access denied"
    }
}

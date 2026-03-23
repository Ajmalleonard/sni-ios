import SwiftUI
import GoogleMaps
import CoreLocation

struct RouteSelectionView: View {
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var placesService = GooglePlacesService()
    @StateObject private var directionsService = DirectionsService()
    
    @State private var mapPosition = GMSCameraPosition.camera(withLatitude: -6.7924, longitude: 39.2083, zoom: 15.0)
    
    // Search States
    @State private var pickupText: String = ""
    @State private var dropoffText: String = ""
    @State private var pickupLocation: SearchLocation?
    @State private var dropoffLocation: SearchLocation?
    
    // UI States
    @State private var activeField: Field? = .pickup
    @State private var predictions: [PlacePrediction] = []
    @State private var isLoadingRoute = false
    @State private var routeInfo: RouteInfo?
    @State private var navigateToCarSelection = false
    
    // Keyboard Focus
    enum Field {
        case pickup
        case dropoff
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Map Background
                GoogleMapsView(mapPosition: $mapPosition, polylineToDraw: routeInfo?.routePolyline)
                    .ignoresSafeArea()
                
                // Search Inputs Card
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60) // Safe area
                    
                    VStack(spacing: 16) {
                        // Input Fields Container
                        VStack(spacing: 0) {
                            inputRow(title: "From", text: $pickupText, field: .pickup, icon: "circle.fill", color: .blue)
                            
                            Divider()
                                .padding(.leading, 50)
                                .opacity(0.5)
                            
                            inputRow(title: "To", text: $dropoffText, field: .dropoff, icon: "square.fill", color: .black)
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Predictions List
                        if !predictions.isEmpty {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(predictions) { prediction in
                                        Button {
                                            selectPrediction(prediction)
                                        } label: {
                                            HStack(spacing: 15) {
                                                Image(systemName: "mappin.circle.fill")
                                                    .font(.title3)
                                                    .foregroundColor(Color("AppSecondary"))
                                                    .frame(width: 30)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(prediction.mainText)
                                                        .font(.body)
                                                        .foregroundColor(.primary)
                                                        .fontWeight(.medium)
                                                    
                                                    Text(prediction.secondaryText)
                                                        .font(.footnote)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                                Spacer()
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        if prediction.id != predictions.last?.id {
                                            Divider().padding(.leading, 50)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .frame(maxHeight: 250)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Confirm Button
                        if let _ = pickupLocation, let _ = dropoffLocation, predictions.isEmpty {
                            Button {
                                fetchRouteAndProceed()
                            } label: {
                                if isLoadingRoute {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Confirm Route")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                }
                            }
                            .background(Color("AppSecondary"))
                            .foregroundColor(Color("AppPrimary"))
                            .clipShape(Capsule())
                            .shadow(color: Color("AppSecondary").opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationDestination(isPresented: $navigateToCarSelection) {
                if let route = routeInfo {
                    CarSelectionView(routeInfo: route)
                        .environmentObject(authModel)
                }
            }
        }
        .onChange(of: pickupText) { _, newValue in
            if activeField == .pickup {
                searchPlaces(query: newValue)
            }
        }
        .onChange(of: dropoffText) { _, newValue in
            if activeField == .dropoff {
                searchPlaces(query: newValue)
            }
        }
    }
    
    // MARK: - Subviews
    private func inputRow(title: String, text: Binding<String>, field: Field, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
                .frame(width: 20)
            
            TextField(title, text: text)
                .onTapGesture {
                    activeField = field
                    predictions = [] // Clear previous predictions
                }
            
            if !text.wrappedValue.isEmpty && activeField == field {
                Button {
                    text.wrappedValue = ""
                    if field == .pickup { pickupLocation = nil }
                    if field == .dropoff { dropoffLocation = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Logic
    private func searchPlaces(query: String) {
        guard !query.isEmpty else {
            predictions = []
            return
        }
        
        Task {
            do {
                let results = try await placesService.fetchPlacePredictions(query: query)
                await MainActor.run {
                    self.predictions = results
                }
            } catch {
                print("Error searching places: \(error)")
            }
        }
    }
    
    private func selectPrediction(_ prediction: PlacePrediction) {
        Task {
            do {
                let details = try await placesService.fetchPlaceDetails(placeId: prediction.placeId)
                
                await MainActor.run {
                    if activeField == .pickup {
                        pickupText = details.name
                        pickupLocation = details
                    } else {
                        dropoffText = details.name
                        dropoffLocation = details
                    }
                    predictions = []
                    
                    // Update camera
                    mapPosition = GMSCameraPosition.camera(withLatitude: details.latitude, longitude: details.longitude, zoom: 15.0)
                }
            } catch {
                print("Error fetching details: \(error)")
            }
        }
    }
    
    private func fetchRouteAndProceed() {
        guard let start = pickupLocation, let end = dropoffLocation else { return }
        
        isLoadingRoute = true
        Task {
            do {
                let route = try await directionsService.fetchDirections(from: start, to: end)
                await MainActor.run {
                    self.routeInfo = route
                    self.isLoadingRoute = false
                    self.navigateToCarSelection = true
                }
            } catch {
                print("Error fetching route: \(error)")
                await MainActor.run { isLoadingRoute = false }
            }
        }
    }
}

#Preview {
    RouteSelectionView()
        .environmentObject(AuthModel())
}

import SwiftUI
import GoogleMaps

struct CarSelectionView: View {
    let routeInfo: RouteInfo
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var vehicleDataManager = VehicleDataManager.shared
    
    @State private var selectedVehicleType: VehicleType? = nil
    @State private var mapPosition: GMSCameraPosition
    @State private var showBookingView = false
    @State private var selectedCar: Car?
    
    init(routeInfo: RouteInfo) {
        self.routeInfo = routeInfo
        // Initialize map centered on pickup or route bounds (simplified to pickup for now)
        _mapPosition = State(initialValue: GMSCameraPosition.camera(withLatitude: routeInfo.fromLocation.latitude, longitude: routeInfo.fromLocation.longitude, zoom: 12.0))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Top Half Map
            GeometryReader { geometry in
                GoogleMapsView(mapPosition: $mapPosition, polylineToDraw: routeInfo.routePolyline)
                    .frame(height: geometry.size.height * 0.55)
                    .edgesIgnoringSafeArea(.top)
            }
            
            // Bottom Sheet
            VStack(spacing: 20) {
                // Route Summary Banner (Floating Pill)
                HStack(spacing: 20) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color("AppSecondary"))
                        Text(routeInfo.duration)
                            .fontWeight(.semibold)
                    }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 20)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .foregroundColor(Color("AppSecondary"))
                        Text(routeInfo.distance)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .offset(y: -40)
                
                // Main Content
                VStack(spacing: 0) {
                    // Handle Bar
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    
                    // Vehicle Types
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(VehicleType.allCases, id: \.self) { type in
                                VehicleTypeButton(type: type, isSelected: selectedVehicleType == type) {
                                    withAnimation(.spring()) {
                                        selectedVehicleType = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 15)
                    
                    // Cars List
                    List {
                        ForEach(filteredCars) { car in
                            Button {
                                selectedCar = car
                                showBookingView = true
                            } label: {
                                CarRowItem(car: car)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .background(.ultraThinMaterial)
                .background(Color("AppPrimary").opacity(0.5)) // Tint
                .mask(RoundedRectangle(cornerRadius: 35, style: .continuous).edgesIgnoringSafeArea(.bottom))
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                .frame(height: UIScreen.main.bounds.height * 0.5)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
        }
        .sheet(item: $selectedCar) { car in
             BookingView(car: car, routeInfo: routeInfo)
                 .environmentObject(authModel)
         }
        .onAppear {
            Task {
                await vehicleDataManager.initialFetch()
            }
        }
    }
    
    private var filteredCars: [Car] {
        if let type = selectedVehicleType {
            return vehicleDataManager.getAvailableVehiclesByType(type)
        }
        return vehicleDataManager.getAvailableVehicles()
    }
}

// MARK: - Subviews
struct VehicleTypeButton: View {
    let type: VehicleType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Color("AppSecondary"))
                    .frame(width: 60, height: 60)
                    .background(
                        isSelected ? Color("AppSecondary") : Color("AppSecondary").opacity(0.1)
                    )
                    .clipShape(Circle())
                    .shadow(color: isSelected ? Color("AppSecondary").opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Color("AppSecondary") : .secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

struct CarRowItem: View {
    let car: Car
    
    var body: some View {
        HStack(spacing: 16) {
            // Car Image
            if let imageURLString = car.primaryImage, let url = URL(string: imageURLString) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(width: 100, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "car.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 65)
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(car.displayName)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack {
                    Text("$\(String(format: "%.0f", car.price))")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color("AppSecondary"))
                    
                    Text("/ day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    // Mock Data
    let mockLocation = SearchLocation(placeId: "1", name: "Test", address: "Test Addr", latitude: 0, longitude: 0, city: nil, country: nil, postalCode: nil)
    let mockRoute = RouteInfo(fromLocation: mockLocation, toLocation: mockLocation, distance: "10 km", duration: "15 min", estimatedCost: "$10", routePolyline: nil)
    
    CarSelectionView(routeInfo: mockRoute)
        .environmentObject(AuthModel())
}

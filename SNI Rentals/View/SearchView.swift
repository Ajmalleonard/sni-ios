//
//  HomeView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 16/04/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

/// Dar es Salaam Coordinates
extension MKCoordinateRegion {
    static let darEsSalaam = MKCoordinateRegion(
        center: .init(latitude: -6.7924, longitude: 39.2083),
        latitudinalMeters: 1000,
        longitudinalMeters: 1000
    )
}

// Make CLLocationCoordinate2D conform to Equatable
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// Navigation destination enum
enum NavigationDestination: Hashable {
    case profile
    case chat
    case notifications
}

struct HomeView: View {
    @EnvironmentObject var authModel: AuthModel
    @State private var showProfileSheet: Bool = false
    
    /// Bottom Sheet Properties - Simplified
    @State private var showBottomSheet: Bool = true
    @State private var sheetDetent: PresentationDetent = .height(80)
    @State private var toolbarOpacity: CGFloat = 1
    
    /// Profile Sheet Properties
    @State private var profileSheetDetent: PresentationDetent = .large
    
    /// Location Properties
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var mapPosition = MapCameraPosition.region(.darEsSalaam)
    @State private var showPermissionAlert = false
    
    // Navigation path for programmatic navigation
    @State private var navigationPath = NavigationPath()
    
    // Track if we're showing profile to hide bottom sheet
    @State private var isShowingProfile = false
    
    // Pre-computed iOS version check
    private let isModernIOS = {
        if #available(iOS 26, *) {
            return true
        } else {
            return false
        }
    }()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Map(position: $mapPosition) {
                // Show user location with UserAnnotation
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard(elevation: .realistic))
            .sheet(isPresented: .constant(showBottomSheet && !isShowingProfile)) {
                BottomSheetViews(sheetDetent: $sheetDetent, navigationPath: $navigationPath)
                    .presentationDetents([.height(80), .height(350), .large], selection: $sheetDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationCornerRadius(isModernIOS ? nil : 30)
                    .presentationDragIndicator(.visible)
                    .presentationBackground {
                        if !isModernIOS {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .interactiveDismissDisabled()
                    .environmentObject(authModel)
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .profile:
                ProfileView()
                    .environmentObject(authModel)
                        .onAppear {
                            print("🟢 ProfileView appeared via NavigationStack")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowingProfile = true
                            }
                        }
                        .onDisappear {
                            print("🔙 ProfileView disappeared - showing bottom sheet")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowingProfile = false
                            }
                        }
                case .chat:
                    ChatScreen()
                        .environmentObject(authModel)
                        .onAppear {
                            print("💬 ChatScreen appeared via NavigationStack")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowingProfile = true
                    }
            }
                        .onDisappear {
                            print("🔙 ChatScreen disappeared - showing bottom sheet")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowingProfile = false
                            }
                        }
                case .notifications:
                    NotificationView()
                        .environmentObject(authModel)
                        .onAppear {
                            print("🔔 NotificationView appeared via NavigationStack")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowingProfile = true
                            }
                        }
                        .onDisappear {
                            print("🔙 NotificationView disappeared - showing bottom sheet")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowingProfile = false
                            }
                        }
                }
            }
        
            .overlay(alignment: .topLeading) {
                WeatherWidget()
                    .opacity(isShowingProfile ? 0 : toolbarOpacity)
                    .scaleEffect(isShowingProfile ? 0.8 : 1.0)
                    .padding([.leading, .top], 15)
                    .animation(.easeInOut(duration: 0.3), value: isShowingProfile)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 12) {
                    // Notification Button
                    NotificationButton(navigationPath: $navigationPath, viewModel: notificationViewModel)
                        .opacity(isShowingProfile ? 0 : toolbarOpacity)
                        .scaleEffect(isShowingProfile ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isShowingProfile)
                    
                    // Message Button
                    FloatingMessageButton(navigationPath: $navigationPath)
                        .opacity(isShowingProfile ? 0 : toolbarOpacity)
                        .scaleEffect(isShowingProfile ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isShowingProfile)
                }
                .padding([.trailing, .top], 15)
            }
            .onChange(of: sheetDetent) { _, newValue in
                // Simplified opacity calculation
                withAnimation(.easeInOut(duration: 0.2)) {
                    toolbarOpacity = newValue == .height(80) ? 1.0 : 0.3
                }
            }
            .onAppear {
                locationManager.requestLocationPermission()
                
                // Observe userLocation changes
                locationManager.onLocationUpdate = { location in
                    // Center map on user's location when it updates
                    withAnimation(.easeInOut(duration: 0.5)) {
                        mapPosition = .region(
                            MKCoordinateRegion(
                                center: location,
                                latitudinalMeters: 1000,
                                longitudinalMeters: 1000
                            )
                        )
                    }
                }
                
                // Initialize notification listener
                if let userId = authModel.currentUser?.id {
                    notificationViewModel.authModel = authModel
                    notificationViewModel.refreshUnreadCount(for: userId)
                    notificationViewModel.startNotificationListener(for: userId)
                }
            }
            .onChange(of: locationManager.authorizationStatus) { _, status in
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    locationManager.startUpdatingLocation()
                } else if status == .denied || status == .restricted {
                    showPermissionAlert = true
            }
        }
            .onChange(of: navigationPath) { _, newValue in
                print("🔄 navigationPath changed. Count: \(newValue.count)")
            }
            .onChange(of: isShowingProfile) { _, newValue in
                print("🎭 isShowingProfile changed to: \(newValue)")
                print("📱 Bottom sheet will be: \(newValue ? "hidden" : "shown")")
                print("🔧 Floating tools will be: \(newValue ? "hidden" : "shown")")
            }
            .alert("Location Access Required", isPresented: $showPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please allow location access to see your position on the map and find nearby rentals.")
            }
        }
    }
    
    /// Weather Widget - Simplified
    @ViewBuilder
    private func WeatherWidget() -> some View {
        HStack(spacing: 4) {
            Image(systemName: "cloud.fill")
            Text("28°")
        }
        .font(.caption)
        .padding(8)
        .background(isModernIOS ? 
            AnyView(Rectangle().fill(.clear)) : 
            AnyView(Rectangle().fill(.ultraThinMaterial))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location every 10 meters
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.onLocationUpdate?(location.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

// MARK: - Optimized Floating Button
struct FloatingButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}


// MARK: - Optimized Profile Image Component
struct ProfileImage: View {
    let url: String?
    let displayName: String
    let size: CGFloat
    
    var body: some View {
        Group {
            if let url = url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProfileInitials(displayName: displayName)
                }
            } else {
                ProfileInitials(displayName: displayName)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Profile Initials Fallback
struct ProfileInitials: View {
    let displayName: String
    
    var body: some View {
        Circle()
            .fill(Color("Accent").opacity(0.3))
            .overlay(
                Text(displayName.prefix(1).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                           .linearGradient(
                               colors: [.blue, .white],
                               startPoint: .top,
                               endPoint: .trailing
                           )
                       )
            )
    }
}

// MARK: - Bottom Sheet View - Optimized
struct BottomSheetViews: View {
    @Binding var sheetDetent: PresentationDetent
    @EnvironmentObject var authModel: AuthModel
    @State private var searchTerm: String = ""
    @State private var fromLocation: String = ""
    @State private var toLocation: String = ""
    @State private var isSearchActive: Bool = false
    
    // Add binding to control profile navigation from parent
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        // Extract content into separate views to reduce complexity
        contentView
    }
    
    // Main content view based on state
    private var contentView: some View {
        VStack(spacing: 15) {
            if sheetDetent == .height(80) {
                collapsedView
            } else if isSearchActive {
                searchView
            } else {
                expandedView
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // Collapsed state view
    private var collapsedView: some View {
        HStack(spacing: 12) {
            searchButton
            profileButton
        }
        .padding(.horizontal, 20)
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    // Search button
    private var searchButton: some View {
        Button {
            isSearchActive = true
            if sheetDetent == .height(80) {
                sheetDetent = .large
            }
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.black)
                Text("Where to?")
                    .foregroundColor(.black)
                Spacer()
            }
            .padding()
            .frame(height: 55)
            .background(Color.gray.opacity(0.2))
            .clipShape(Capsule())
        }
    }
    
    // Profile button
    private var profileButton: some View {
        Button {
            print("🔵 Avatar button tapped in bottom sheet!")
            print("🔵 Navigating to profile via NavigationStack")
            navigationPath.append(NavigationDestination.profile)
        } label: {
            ProfileImage(
                url: authModel.currentUser?.profilePicture,
                displayName: authModel.currentUser?.displayName ?? "User",
                size: 55
            )
        }
    }
    
    // Search view
    private var searchView: some View {
        ScrollView {
            VStack(spacing: 24) {
                searchHeader
                searchFields
                recentSearches
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Search header
    private var searchHeader: some View {
        HStack {
            Text("Plan Your Trip")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
            
            Button {
                isSearchActive = false
                if sheetDetent == .large {
                    sheetDetent = .height(80)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }
        }
        .padding(.top, 16)
    }
    
    // Search fields
    private var searchFields: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(width: 30)
                
                VStack(spacing: 20) {
                    TextField("From", text: $fromLocation)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                    
                    TextField("To", text: $toLocation)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            Button {
                // Implement search action
            } label: {
                Text("Search")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 16)
    }
    
    // Recent searches
    private var recentSearches: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Searches")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 16)
            
            ForEach(["Dodoma to City Center", "Hotel Zone to Beach", "Sinza to Mall"], id: \.self) { search in
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.black)
                    Text(search)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
    
    // Expanded state view
    private var expandedView: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                titleView
                vehicleCategories
                featuredRentalsSection
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Title view
    private var titleView: some View {
                    Text("Available Rentals")
            .font(.title)
                        .fontWeight(.bold)
            .foregroundColor(.black)
            .padding(.top, 8)
            .padding(.bottom, 8)
    }
    
    // Vehicle categories
    private var vehicleCategories: some View {
        VStack(spacing: 16) {
            VehicleCategoryRow(
                title: "Coasters",
                description: "Compact and efficient city cars",
                icon: "coaster"
            )
            
            VehicleCategoryRow(
                title: "SUVs",
                description: "Spacious vehicles for any terrain",
                icon: "suv"
            )
            
            VehicleCategoryRow(
                title: "Huge Vehicles",
                description: "Large capacity for groups and cargo",
                icon: "truck"
            )
        }
    }
    
    // Featured rentals section
    private var featuredRentalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Rentals")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.top, 8)
            
                    LazyVStack(spacing: 12) {
                        ForEach(rentalData, id: \.id) { rental in
                            RentalCard(rental: rental)
                        }
            }
        }
    }
    
    // Static rental data to avoid recreating arrays
    private let rentalData: [RentalData] = [
        RentalData(id: 1, carName: "Tesla Model 3", price: "$89/day", distance: "0.2 mi"),
        RentalData(id: 2, carName: "BMW X5", price: "$120/day", distance: "0.5 mi"),
        RentalData(id: 3, carName: "Mercedes C-Class", price: "$95/day", distance: "0.8 mi")
    ]
}

// MARK: - Vehicle Category Row
struct VehicleCategoryRow: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        Button(action: {
            // Action to explore this category
        }) {
            HStack {
                Image(icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .padding(.horizontal,20)
                   
                    
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.black)
            }
            .padding()
            .padding(.leading,10)
            .background(Color.gray.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Rental Data Model
struct RentalData {
    let id: Int
    let carName: String
    let price: String
    let distance: String
}



// MARK: - Optimized Rental Card
struct RentalCard: View {
    let rental: RentalData
    
    var body: some View {
        HStack {
            // Simplified car placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.3))
                .frame(width: 60, height: 40)
                .overlay(
                    Image(systemName: "car.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 16))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(rental.carName)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(rental.distance)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(rental.price)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Button("Rent") {
                    // Rent action
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.black)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Floating Message Button
struct FloatingMessageButton: View {
    @Binding var navigationPath: NavigationPath
    @State private var hasUnreadMessages = true // This will be connected to Firebase later
    
    var body: some View {
        Button {
            print("💬 Message button tapped!")
            print("💬 Navigating to chat screen")
            navigationPath.append(NavigationDestination.chat)
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Image(systemName: "message.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                // Notification badge
                if hasUnreadMessages {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 18, y: -18)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthModel())
}





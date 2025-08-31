//
//  HomeView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 16/04/25.
//

import SwiftUI
import GoogleMaps
import CoreLocation



let darEsSalaam = GMSCameraPosition.camera(
        withLatitude: -6.7924,
        longitude: 39.2083,
        zoom: 15.0
    )




// Make CLLocationCoordinate2D conform to Equatable
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}



// Route information model
struct RouteInfo {
    let fromLocation: SearchLocation
    let toLocation: SearchLocation
    let distance: String
    let duration: String
    let estimatedCost: String
    let routePolyline: String? // For drawing the route on map
    
    var summary: String {
        "\(distance) • \(duration) • \(estimatedCost)"
    }
}

// Enums moved to SharedTypes.swift

struct SearchView: View {
    @EnvironmentObject var authModel: AuthModel
    @State private var showProfileSheet: Bool = false
    
    /// UI State Properties
    @State private var toolbarOpacity: CGFloat = 1
    
    /// Location Properties
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var mapPosition = darEsSalaam
    @State private var showPermissionAlert = false
    
    // Navigation path for programmatic navigation
    @State private var navigationPath = NavigationPath()
    
    // Track if we're showing profile to hide bottom sheet
    @State private var isShowingProfile = false
    
    // Search screen presentation
    @State private var showingSearchScreen = false
    
    // Route information from search
    @State private var selectedRoute: RouteInfo?
    @State private var showRouteOverlay = false
    
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
            GoogleMapsView(mapPosition: $mapPosition)
                .ignoresSafeArea()
                .onAppear {
                    GoogleMapsConfiguration.configure()
                }
            .overlay(alignment: .bottom) {
                if !isShowingProfile && !showingSearchScreen {
                    SearchBottomSheet(
                        navigationPath: $navigationPath,
                        showingSearchScreen: $showingSearchScreen,
                        onProfileTap: {
                            navigationPath.append(NavigationDestination.profile)
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
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
            .overlay(alignment: .bottom) {
                if let route = selectedRoute, showRouteOverlay {
                    RouteOverlayView(
                        route: route,
                        onClose: {
                            selectedRoute = nil
                            showRouteOverlay = false

                        },
                        onBookRide: {
                            // Handle ride booking
                            print("Booking ride for route: \(route.summary)")
                        }
                    )
                    .padding(.bottom, 100) // Above the bottom sheet
                    .animation(.spring(response: 0.6), value: showRouteOverlay)
                }
            }
      

            .onAppear {
                locationManager.requestLocationPermission()
                
                // Observe userLocation changes
                locationManager.onLocationUpdate = { location in
                    // Center map on user's location when it updates
                    withAnimation(.easeInOut(duration: 0.5)) {
                        mapPosition = GMSCameraPosition.camera(
                            withLatitude: location.latitude,
                            longitude: location.longitude,
                            zoom: 15.0
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
            .sheet(isPresented: $showingSearchScreen) {
                SearchScreen(
                    onRouteSelected: { fromLocation, toLocation in
                        // Create route info (in real app, this would come from routing API)
                        let route = RouteInfo(
                            fromLocation: fromLocation,
                            toLocation: toLocation,
                            distance: "12.5 km",
                            duration: "18 min",
                            estimatedCost: "$15-20",
                            routePolyline: nil
                        )
                        
                        selectedRoute = route
                        showRouteOverlay = true
                        showingSearchScreen = false
                        
                        // Hide bottom sheet when showing route
                        
                    },
                    isPreview: authModel.isPreview
                )
                .environmentObject(authModel)
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




// ProfileImage moved to Components/ProfileImage.swift

// BottomSheetViews moved to Components/BottomSheetViews.swift

// MARK: - Route Overlay View (Uber-style)
struct RouteOverlayView: View {
    let route: RouteInfo
    let onClose: () -> Void
    let onBookRide: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Route information
            VStack(spacing: 16) {
                // Route header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Route Preview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(route.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // From and To locations
                VStack(spacing: 12) {
                    LocationRow(
                        icon: "circle.fill",
                        iconColor: .green,
                        title: "From",
                        location: route.fromLocation.name,
                        subtitle: route.fromLocation.address
                    )
                    
                    // Dotted line
                    VStack {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 4, height: 4)
                        }
                    }
                    
                    LocationRow(
                        icon: "circle.fill",
                        iconColor: .red,
                        title: "To",
                        location: route.toLocation.name,
                        subtitle: route.toLocation.address
                    )
                }
                .padding(.vertical, 8)
                
                // Route details
                HStack(spacing: 20) {
                    RouteDetailItem(
                        icon: "location.fill",
                        title: "Distance",
                        value: route.distance
                    )
                    
                    RouteDetailItem(
                        icon: "clock.fill",
                        title: "Duration",
                        value: route.duration
                    )
                    
                    RouteDetailItem(
                        icon: "dollarsign.circle.fill",
                        title: "Cost",
                        value: route.estimatedCost
                    )
                }
                .padding(.horizontal)
                
                // Book ride button
                Button(action: onBookRide) {
                    Text("Book This Ride")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Location Row
struct LocationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let location: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(location)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
}

// MARK: - Route Detail Item
struct RouteDetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color("Secondary"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}



#Preview {
    // Use a mock AuthModel for previews to avoid network calls
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    
    return SearchView()
        .environmentObject(mockAuthModel)
}



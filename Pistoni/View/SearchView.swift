//
//  HomeView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 16/04/25.
//

import SwiftUI
import GoogleMaps
import CoreLocation


// Make CLLocationCoordinate2D conform to Equatable
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

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
    
 
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            BaseMapView(
                mapPosition: $mapPosition,
                isShowingProfile: $isShowingProfile,
                showingSearchScreen: $showingSearchScreen,
                selectedRoute: $selectedRoute,
                showRouteOverlay: $showRouteOverlay,
                toolbarOpacity: toolbarOpacity,
                navigationPath: $navigationPath,
                authModel: authModel,
                locationManager: locationManager,
                notificationViewModel: notificationViewModel,
                showPermissionAlert: $showPermissionAlert
            )
            .navigationDestination(for: NavigationDestination.self) { destination in
                DestinationView(
                    destination: destination,
                    authModel: authModel,
                    isShowingProfile: $isShowingProfile
                )
            }
            .sheet(isPresented: $showingSearchScreen) {
                buildSearchSheet()
            }
        }
    }
    
    // MARK: - Extracted Builders
    @ViewBuilder
    private func buildSearchSheet() -> some View {
        SheetSearchScreen(
            onRouteSelected: { fromLocation, toLocation in
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
            },
            isPreview: authModel.isPreview
        )
        .environmentObject(authModel)
    }
    
    private func handleLocationAuthorizationChange(_ status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else if status == .denied || status == .restricted {
            showPermissionAlert = true
        }
    }
    
    // MARK: - Extracted Subviews
    private struct BaseMapView: View {
        @Binding var mapPosition: GMSCameraPosition
        @Binding var isShowingProfile: Bool
        @Binding var showingSearchScreen: Bool
        @Binding var selectedRoute: RouteInfo?
        @Binding var showRouteOverlay: Bool
        let toolbarOpacity: CGFloat
        @Binding var navigationPath: NavigationPath

        var authModel: AuthModel
        @ObservedObject var locationManager: LocationManager
        @ObservedObject var notificationViewModel: NotificationViewModel
        @Binding var showPermissionAlert: Bool

        var body: some View {
            GoogleMapsView(mapPosition: $mapPosition)
                .ignoresSafeArea()
                .onAppear {
                    GoogleMapsConfiguration.configure()
                    setupLocationAndNotifications()
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
                .overlay(alignment: .topLeading) {
                    MoreButton()
                        .opacity(isShowingProfile ? 0 : toolbarOpacity)
                        .scaleEffect(isShowingProfile ? 0.8 : 1.0)
                        .padding([ .leading], 10)
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
                                print("Booking ride for route: \(route.summary)")
                            }
                        )
                        .padding(.bottom, 100)
                        .animation(.spring(response: 0.6), value: showRouteOverlay)
                    }
                }
                .onChange(of: locationManager.authorizationStatus) { _, status in
                    handleAuthorizationChange(status)
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

        private func setupLocationAndNotifications() {
            locationManager.requestLocationPermission()
            locationManager.onLocationUpdate = { location in
                withAnimation(.easeInOut(duration: 0.5)) {
                    mapPosition = GMSCameraPosition.camera(
                        withLatitude: location.latitude,
                        longitude: location.longitude,
                        zoom: 15.0
                    )
                }
            }
            if let userId = authModel.currentUser?.id {
                notificationViewModel.authModel = authModel
                notificationViewModel.refreshUnreadCount(for: userId)
                notificationViewModel.startNotificationListener(for: userId)
            }
        }

        private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                locationManager.startUpdatingLocation()
            } else if status == .denied || status == .restricted {
                showPermissionAlert = true
            }
        }
    }

    private struct DestinationView: View {
        let destination: NavigationDestination
        let authModel: AuthModel
        @Binding var isShowingProfile: Bool

        var body: some View {
            Group {
                switch destination {
                case .profile:
                    ProfileView()
                        .environmentObject(authModel)
                        .onAppear { withAnimation(.easeInOut(duration: 0.3)) { isShowingProfile = true } }
                        .onDisappear { withAnimation(.easeInOut(duration: 0.3)) { isShowingProfile = false } }

                case .notifications:
                    NotificationView()
                        .environmentObject(authModel)
                        .onAppear { withAnimation(.easeInOut(duration: 0.3)) { isShowingProfile = true } }
                        .onDisappear { withAnimation(.easeInOut(duration: 0.3)) { isShowingProfile = false } }
                
                default:
                    EmptyView()
                        .onAppear { withAnimation(.easeInOut(duration: 0.3)) { isShowingProfile = false } }
                }
            }
        }
    }
    
    private struct MoreButton: View {
        @State private var showProfile = false

        var body: some View {
            Button {
                showProfile = true
            } label: {
                
                if #available(iOS 26.0, *) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(20)
                        .frame(width:40,height: 40)
                        .glassEffect()
                } else {
                    // Fallback on earlier versions
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(20)
                        .background(
                            .ultraThickMaterial, // iOS glass effect
                            in: RoundedRectangle(cornerRadius: 50, style: .continuous)
                        )
                }
                
                   
            }
            
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .presentationDetents([.large])              // takes big part of screen
                    .presentationDragIndicator(.visible)         // iOS 16+ style drag bar
            }
        }
    }
}

#Preview {
    // Use a mock AuthModel for previews to avoid network calls
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    
    return SearchView()
        .environmentObject(mockAuthModel)
}


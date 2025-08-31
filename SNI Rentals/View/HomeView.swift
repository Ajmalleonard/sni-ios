//
//  HomeView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 21/07/2025.
//

import SwiftUI

// Simplified HomeTab enum with only 3 tabs
enum HomeTab: String, CaseIterable {
    case home = "house"
    case chat = "message"
    case explore = "explore"
    case profile = "person"
}

// Vehicle Type for filtering
enum VehicleTypeFilter: String, CaseIterable {
    case all = "All"
    case suv = "SUV"
    case coaster = "COASTER"
    case longVehicle = "LONG_VEHICLE"
    
    var displayName: String {
        switch self {
        case .all: return "All Cars"
        case .suv: return "SUVs"
        case .coaster: return "Coasters"
        case .longVehicle: return "Long Vehicles"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "car.2.fill"
        case .suv: return "car.fill"
        case .coaster: return "bus.fill"
        case .longVehicle: return "truck.box.fill"
        }
    }
    
    var vehicleType: VehicleType? {
        switch self {
        case .all: return nil
        case .suv: return .suv
        case .coaster: return .coaster
        case .longVehicle: return .longVehicle
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var authModel: AuthModel
    @StateObject private var vehicleDataManager = VehicleDataManager.shared
    @State private var selectedTab: HomeTab = .home
    @State private var selectedVehicleFilter: VehicleTypeFilter = .all
    @State private var showSearch = false
    @State private var searchText: String = ""
    @State private var showScheduleTrip = false
    @State private var hasNotifications: Bool = true // Set to true for preview
    @State private var showNotifications = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content based on selected tab
                        switch selectedTab {
                        case .home:
                            homeContent
                case .chat:
                    ChatScreen()
                case .profile:
                    ProfileView()
                        case .explore:
                            SearchView()
                        }
                
                // Bottom Navigation - Hide when SearchView is active
                if selectedTab != .explore {
                    BottomNavigationBar(selectedTab: $selectedTab)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showScheduleTrip) {
            ScheduleTripView()
        }
        .sheet(isPresented: $showSearch) {
            SearchScreen()
                .environmentObject(authModel)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationView()
                .environmentObject(authModel)
        }
        .onAppear {
            Task {
                await vehicleDataManager.initialFetch()
            }
        }
    }
    
    // MARK: - Home Content (ProfileView Style)
    var homeContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section (ProfileView Style)
                headerSection
                
                // Main Content
                VStack(spacing: 15) {
                    // Vehicle Type Filter Section
                    vehicleTypeFilterSection
                    
                    // Cars Display Section
                    carsDisplaySection
                    
                    // Quick Actions Section
                    QuickAction(showScheduleTrip: $showScheduleTrip)
                }
                .padding(.top, 25)
                .padding(.horizontal, 10)
                .padding(.bottom, 100) // Space for bottom navigation
            }
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            Task {
                await vehicleDataManager.manualRefresh()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HomeHeaderView(
            showSearch: $showSearch,
            showNotifications: $showNotifications,
            hasNotifications: hasNotifications
        )
        .padding(.horizontal, 5)
    }
    
    // MARK: - Vehicle Type Filter Section (ProfileView Style)
    private var vehicleTypeFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
        
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(VehicleTypeFilter.allCases, id: \.rawValue) { filter in
                        VehicleFilterButton(
                            filter: filter,
                            isSelected: selectedVehicleFilter == filter
                        ) {
                            selectedVehicleFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 25)
            }
        }
    }
    
    // MARK: - Cars Display Section (ProfileView Style)
    private var carsDisplaySection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            
            
            if vehicleDataManager.isLoading {
                LoadingView()
                    .padding(.vertical, 40)
            } else if filteredCars.isEmpty {
                EmptyStateView(
                    icon: selectedVehicleFilter.icon,
                    title: "No \(selectedVehicleFilter.displayName) Found",
                    subtitle: "Try selecting a different vehicle type or check back later"
                )
                .padding(.vertical, 40)
            } else {
                ForEach(Array(filteredCars.prefix(10).enumerated()), id: \.element.id) { index, car in
                    VStack(spacing: 16) {
                        CarListItem(car: car) {
                            // Handle car selection - could navigate to detail view
                            print("Selected car: \(car.displayName)")
                        }
                        
                       
                    }
                }
            }
           
          
           
            
        }
        
    }
    
    
    // MARK: - Computed Properties
    private var filteredCars: [Car] {
        if let vehicleType = selectedVehicleFilter.vehicleType {
            return vehicleDataManager.getAvailableVehiclesByType(vehicleType)
        } else {
            return vehicleDataManager.getAvailableVehicles()
        }
    }
}

// MARK: - Vehicle Filter Button
struct VehicleFilterButton: View {
    let filter: VehicleTypeFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : Color("Secondary"))
                
                Text(filter.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : Color("Secondary"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                isSelected ? Color("Secondary") : Color("Primary")
            )
            .clipShape(Capsule())
            
        }
        .buttonStyle(PlainButtonStyle())
    }
}




// MARK: - Home Header View
struct HomeHeaderView: View {
    @EnvironmentObject var authModel: AuthModel
    @Binding var showSearch: Bool
    @Binding var showNotifications: Bool
    let hasNotifications: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                // Profile Picture
                AsyncImage(url: URL(string: authModel.currentUser?.profilePicture ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.black.opacity(0.1))
                        .overlay(
                            Text(authModel.currentUser?.displayName.prefix(1).uppercased() ?? "U")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                // Name and Welcome Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hello, \(authModel.currentUser?.displayName.split(separator: " ").first ?? "User")!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Ready for your next adventure?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Search Button
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showSearch = true
                        }
                    } label: {
                        Image("search")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color("Secondary"))
                            .frame(width: 20, height: 20)
                            .padding(12)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    // Notification Button
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showNotifications = true
                        }
                    } label: {
                        ZStack {
                            Image("notify")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color("Secondary"))
                                .frame(width: 20, height: 20)
                                .padding(12)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                            
                            // Notification Badge
                            if hasNotifications {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -12)
                                    .shadow(color: .white, radius: 1)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
}

#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return HomeView()
        .environmentObject(mockAuthModel)
}


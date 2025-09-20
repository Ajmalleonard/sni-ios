//
//  HomeView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 21/07/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authModel: AuthModel
    @StateObject private var vehicleDataManager = VehicleDataManager.shared
    @State private var selectedVehicleFilter: VehicleTypeFilter = .all
    @State private var showSearch = false
    @State private var searchText: String = ""
    @State private var showScheduleTrip = false
    @State private var hasNotifications: Bool = true
    @State private var showNotifications = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
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
        .toolbar{
            ToolbarItem(placement: .topBarTrailing){
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
        .sheet(isPresented: $showScheduleTrip) {
            ScheduleTripView()
        }
        .sheet(isPresented: $showSearch) {
            SearchScreen()
                .environmentObject(authModel)
        }
        .fullScreenCover(
            isPresented: $showNotifications,
            onDismiss: { showNotifications = false }   // <- closure
        ) {
            NotificationView()
                .environmentObject(authModel)
        }
        .onAppear {
            Task {
                await vehicleDataManager.initialFetch()
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
    
    // MARK: - Vehicle Type Filter Section
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
    
    // MARK: - Cars Display Section
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
                ForEach(Array(filteredCars.enumerated()), id: \.element.id) { index, car in
                    VStack(spacing: 16) {
                        CarListItem(car: car) {
                            // Handle car selection
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

#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return HomeView()
        .environmentObject(mockAuthModel)
}

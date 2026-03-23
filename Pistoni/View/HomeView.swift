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
    @State private var showRouteSelection = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            //MARK: Main Content
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                    
                    // Route Selection Enty Point
                    routeSelectionSection
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

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
                    .padding(.bottom, 100) //
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
            ToolbarItemGroup(placement: .topBarTrailing){
                
                Button {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showNotifications = true
                    }
                } label: {
                    ZStack {
                        Image("notify")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color("AppSecondary"))
                            .frame(width: 20, height: 20)
                            .padding(12)
                        
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
                
                
                
            }}
        .sheet(isPresented: $showScheduleTrip) {
            ScheduleTripView()
        }
        .fullScreenCover(
            isPresented: $showNotifications,
            onDismiss: { showNotifications = false }   // <- closure
        ) {
            NotificationView()
                .environmentObject(authModel)
        }
        .fullScreenCover(isPresented: $showRouteSelection) {
            RouteSelectionView()
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
    
    // MARK: - Route Selection Section
    private var routeSelectionSection: some View {
        Button {
            showRouteSelection = true
        } label: {
            HStack(spacing: 15) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundColor(Color("AppSecondary"))
                    .frame(width: 40, height: 40)
                    .background(Color("AppSecondary").opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Where to?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Anywhere via Pistoni")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
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
                    NavigationLink(value: car) {
                        VStack(spacing: 16) {
                            CarListItem(car: car) {
                                // Optional: handle auxiliary actions (e.g., Book Now)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
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
                    .foregroundColor(isSelected ? .white : Color("AppSecondary"))
                
                Text(filter.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : Color("AppSecondary"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                isSelected ? Color("AppSecondary") : Color("AppPrimary")
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

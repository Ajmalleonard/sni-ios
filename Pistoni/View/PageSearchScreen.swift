//
//  PageSearchScreen.swift
//  Pistoni
//
//  Created for ContentView navigation with route confirmation and car selection
//

import SwiftUI
import CoreLocation

struct PageSearchScreen: View {
    @EnvironmentObject var authModel: AuthModel
    @StateObject private var searchService: SearchService
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    @Binding var searchText: String
    @State private var selectedSearchType: SearchType = .general
    @State private var showingLocationPicker = false
    @State private var selectedPrediction: PlacePrediction?
    @State private var fromLocation: SearchLocation?
    @State private var toLocation: SearchLocation?
    
    // New state variables for dual fields
    @State private var pickupText: String = ""
    @State private var destinationText: String = ""
    @State private var activeField: LocationField = .none
    
    // Route confirmation and navigation states
    @State private var showRouteConfirmation = false
    @State private var estimatedCost: String = ""
    @State private var routeDistance: String = ""
    @State private var routeDuration: String = ""
    @State private var navigateToCarSelection = false
    
    // Callback for route selection (optional for this version)
    let onRouteSelected: ((SearchLocation, SearchLocation) -> Void)?
    
    // Enum to track which field is active
    enum LocationField {
        case pickup, destination, none
    }
    
    init(searchText: Binding<String> = .constant(""), onRouteSelected: ((SearchLocation, SearchLocation) -> Void)? = nil, isPreview: Bool = false) {
        self._searchText = searchText
        self.onRouteSelected = onRouteSelected
        
        // Check if running in preview mode
        let isPreviewMode = isPreview || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        // Initialize SearchService with preview flag
        _searchService = StateObject(wrappedValue: SearchService(isPreview: isPreviewMode))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: 25) {
                        // Search input section (no search bar since ContentView has one)
                        searchInputSection
                        
                        // Show route confirmation if both locations are selected
                        if showRouteConfirmation && fromLocation != nil && toLocation != nil {
                            routeConfirmationSection
                        }
                        
                        // Content based on state
                        if activeField != .none && searchService.searchState.isSearching {
                            loadingSection
                        } else if activeField != .none && !searchService.searchState.predictions.isEmpty {
                            searchResultsSection
                        } else if activeField != .none && !searchText.isEmpty {
                            noResultsSection
                        } else if activeField == .none && !showRouteConfirmation {
                            // Show recent and popular searches only when no route is being confirmed
                            recentSearchesSection
                            popularSearchesSection
                        }
                    }
                    .padding(.top, 25)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(.white)
            .navigationTitle("Plan Your Trip")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(selectedLocation: .constant(nil))
        }
        .navigationDestination(isPresented: $navigateToCarSelection) {
            if let fromLoc = fromLocation, let toLoc = toLocation {
                LegacyCarSelectionView(
                    fromLocation: fromLoc,
                    toLocation: toLoc,
                    estimatedCost: estimatedCost,
                    routeDistance: routeDistance,
                    routeDuration: routeDuration
                )
            } else {
                // Fallback view if locations are nil
                VStack {
                    Text("Error: Missing location data")
                        .foregroundColor(.red)
                    Button("Go Back") {
                        navigateToCarSelection = false
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var searchInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where to?")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 12) {
                // Pickup Location Field
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(width: 20, height: 20)
                        
                        Button(action: {
                            print("🎯 Pickup button tapped - setting activeField to .pickup")
                            activeField = .pickup
                            searchText = ""
                            searchService.clearSearchState()
                            showRouteConfirmation = false
                        }) {
                            HStack {
                                Text(pickupText.isEmpty ? "Pickup Location" : pickupText)
                                    .font(.body)
                                    .foregroundColor(pickupText.isEmpty ? .secondary : .primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if !pickupText.isEmpty {
                            Button {
                                pickupText = ""
                                fromLocation = nil
                                if activeField == .pickup {
                                    searchText = ""
                                    searchService.clearSearchState()
                                }
                                showRouteConfirmation = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color("AppPrimary"))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(activeField == .pickup ? Color.green.opacity(0.9) : Color.gray.opacity(0.3), lineWidth: activeField == .pickup ? 2 : 1)
                )
                
                // Destination Field
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(width: 20, height: 20)
                        
                        Button(action: {
                            print("🎯 Destination button tapped - setting activeField to .destination")
                            activeField = .destination
                            searchText = ""
                            searchService.clearSearchState()
                            showRouteConfirmation = false
                        }) {
                            HStack {
                                Text(destinationText.isEmpty ? "Destination" : destinationText)
                                    .font(.body)
                                    .foregroundColor(destinationText.isEmpty ? .secondary : .primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if !destinationText.isEmpty {
                            Button {
                                destinationText = ""
                                toLocation = nil
                                if activeField == .destination {
                                    searchText = ""
                                    searchService.clearSearchState()
                                }
                                showRouteConfirmation = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color("AppPrimary"))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(activeField == .destination ? Color.red.opacity(0.9) : Color.gray.opacity(0.3), lineWidth: activeField == .destination ? 2 : 1)
                )
                
                // Search TextField (only show when a field is active)
                if activeField != .none {
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Image("maper")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color(.systemBlue))
                            
                            TextField("Search for \(activeField == .pickup ? "pickup" : "destination") location", text: $searchText)
                                .font(.body)
                                .foregroundColor(.primary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.words)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    searchService.clearSearchState()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .background(Color("AppPrimary"))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue.opacity(0.9), lineWidth: 2)
                    )
                }
            }
        }
    }
    
    private var routeConfirmationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Route Summary")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Route info card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text(fromLocation?.name ?? "Pickup Location")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                Text(toLocation?.name ?? "Destination")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(routeDistance)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(routeDuration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Cost estimation
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Estimated Cost")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(estimatedCost)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            navigateToCarSelection = true
                        }) {
                            Text("Choose Car")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color("AppSecondary"))
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                    }
                }
                .padding(20)
                .background(Color("AppPrimary"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 15) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching locations...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color("AppPrimary"))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Search Results")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Text("\(searchService.searchState.predictions.count) found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 25)
            
            VStack(spacing: 0) {
                ForEach(Array(searchService.searchState.predictions.enumerated()), id: \.element.id) { index, prediction in
                    VStack(spacing: 0) {
                        SearchResultItem(
                            prediction: prediction,
                            action: {
                                selectPrediction(prediction, at: index)
                            }
                        )
                        
                        if index < searchService.searchState.predictions.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .background(Color("AppPrimary"))
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
    
    private var noResultsSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "location.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Results Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try adjusting your search terms or check your spelling")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color("AppPrimary"))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    private var recentSearchesSection: some View {
        Group {
            if !searchService.searchState.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Searches")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Button("Clear All") {
                            // Clear recent searches from the state
                            searchService.searchState.recentSearches = []
                        }
                        .font(.caption)
                        .foregroundColor(Color("AppSecondary"))
                    }
                    .padding(.horizontal, 25)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(searchService.searchState.recentSearches.prefix(5).enumerated()), id: \.element.id) { index, search in
                            VStack(spacing: 0) {
                                RecentSearchItem(
                                    search: search,
                                    action: {
                                        useRecentSearch(search)
                                    }
                                )
                                
                                if index < min(4, searchService.searchState.recentSearches.count - 1) {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                    }
                    .background(Color("AppPrimary"))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
            }
        }
    }
    
    private var popularSearchesSection: some View {
        Group {
            if !searchService.searchState.popularSearches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Popular Searches")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 25)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(searchService.searchState.popularSearches.prefix(5).enumerated()), id: \.element.id) { index, search in
                            VStack(spacing: 0) {
                                PopularSearchItem(
                                    search: search,
                                    action: {
                                        usePopularSearch(search)
                                    }
                                )
                                
                                if index < min(4, searchService.searchState.popularSearches.count - 1) {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                    }
                    .background(Color("AppPrimary"))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadInitialData() async {
        // Load recent and popular searches
        await searchService.fetchRecentSearches(userId: authModel.currentUser?.id ?? "", limit: 10)
        await searchService.fetchPopularSearches(limit: 10)
        
        // Request location permission
        locationManager.requestLocationPermission()
    }
    
    private func performSearch(query: String) {
        print("🔍 PageSearchScreen.performSearch called with query: '\(query)'")
        print("   Active field: \(activeField)")
        
        guard !query.isEmpty else {
            print("   ❌ Empty query, skipping search")
            return
        }
        
        guard let userId = authModel.currentUser?.id else {
            print("   ❌ No user ID found")
            print("   Current user: \(String(describing: authModel.currentUser))")
            print("   Is authenticated: \(authModel.authState.isAuthenticated)")
            return
        }
        
        print("   ✅ User ID: \(userId)")
        
        let userLocation = locationManager.currentLocation?.coordinate
        print("   📍 User location: \(String(describing: userLocation))")
        
        searchService.searchWithDebounce(
            query: query,
            searchType: selectedSearchType,
            userId: userId,
            userLocation: userLocation
        )
    }
    
    private func selectPrediction(_ prediction: PlacePrediction, at index: Int) {
        let location = SearchLocation(
            placeId: prediction.placeId,
            name: prediction.mainText,
            address: prediction.secondaryText,
            latitude: 0.0, // Will be updated with actual coordinates
            longitude: 0.0, // Will be updated with actual coordinates
            city: nil,
            country: nil,
            postalCode: nil
        )
        
        if activeField == .pickup {
            fromLocation = location
            pickupText = prediction.mainText
            activeField = .destination
            searchText = ""
            searchService.clearSearchState()
        } else if activeField == .destination {
            toLocation = location
            destinationText = prediction.mainText
            activeField = .none
            searchText = ""
            searchService.clearSearchState()
            
            // Check if both locations are set to show route confirmation
            if fromLocation != nil && toLocation != nil {
                calculateRouteEstimation()
                showRouteConfirmation = true
            }
        }
        
        // Save search query
        Task {
            await searchService.confirmSearch(
                prediction: prediction,
                searchType: selectedSearchType,
                userId: authModel.currentUser?.id ?? "",
                selectedIndex: index
            )
        }
    }
    
    private func calculateRouteEstimation() {
        // Static data for now - in real app, this would come from routing API
        let distances = ["5.2 km", "12.8 km", "8.7 km", "15.3 km", "6.9 km"]
        let durations = ["12 min", "25 min", "18 min", "32 min", "15 min"]
        let costs = ["$8-12", "$18-25", "$12-18", "$25-35", "$10-15"]
        
        let randomIndex = Int.random(in: 0..<distances.count)
        
        routeDistance = distances[randomIndex]
        routeDuration = durations[randomIndex]
        estimatedCost = costs[randomIndex]
    }
    
    private func useRecentSearch(_ search: SearchQuery) {
        searchText = search.searchText
        selectedSearchType = search.searchType
    }
    
    private func usePopularSearch(_ search: SearchQuery) {
        searchText = search.searchText
        selectedSearchType = search.searchType
    }
}

// MARK: - Car Selection View

struct LegacyCarSelectionView: View {
    let fromLocation: SearchLocation
    let toLocation: SearchLocation
    let estimatedCost: String
    let routeDistance: String
    let routeDuration: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Map with polyline (placeholder for now)
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                
                VStack {
                    Text("Route Map")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Polyline will be displayed here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Car selection content
            ScrollView {
                VStack(spacing: 20) {
                    // Route summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Route")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                    Text(fromLocation.name)
                                        .font(.subheadline)
                                }
                                
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                    Text(toLocation.name)
                                        .font(.subheadline)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(routeDistance)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(routeDuration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color("AppPrimary"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Car options (placeholder)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Your Ride")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Sample car options
                        ForEach(0..<3) { index in
                            CarOptionRow(
                                carType: ["Economy", "Comfort", "Premium"][index],
                                estimatedTime: ["5-10 min", "3-8 min", "2-5 min"][index],
                                price: estimatedCost
                            )
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Choose Car")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
        }
    }
}

struct CarOptionRow: View {
    let carType: String
    let estimatedTime: String
    let price: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundColor(Color("AppSecondary"))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(carType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(estimatedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(price)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(16)
        .background(Color("AppPrimary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    @Previewable @State var searchText = ""
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    
    return PageSearchScreen(searchText: $searchText, isPreview: true)
        .environmentObject(mockAuthModel)
}
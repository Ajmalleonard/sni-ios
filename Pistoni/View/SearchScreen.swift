//
//  HomeView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 16/04/25.
//

import SwiftUI
import CoreLocation

struct SearchScreen: View {
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
    @State private var activeField: LocationField = .pickup
    
    // Callback for route selection
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
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                   
                  
                    
                    // Main Content
                    VStack(spacing: 25) {
                        // Search Input Section
                       
                            
                            searchInputSection
                           
                            
                       
                    
                        
                        // Search Results or Suggestions
                        if activeField != .none && searchService.searchState.isSearching {
                            loadingSection
                        } else if activeField != .none && !searchService.searchState.predictions.isEmpty {
                            searchResultsSection
                        } else if activeField != .none && !searchText.isEmpty {
                            noResultsSection
                        } else if activeField == .none {
                            // Recent and Popular Searches (only when no field is active)
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
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
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
    }
    
 
    
    // MARK: - Search Input Section
    private var searchInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where to?")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 12) {
                // Pickup Field
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(width: 20, height: 20)
                        
                        Button(action: {
                            print("🎯 Pickup button tapped - setting activeField to .pickup")
                            print("   Current searchText: '\(searchText)'")
                            print("   Current activeField: \(activeField)")
                            activeField = .pickup
                            searchText = "" // Clear search text when switching fields
                            searchService.clearSearchState()
                            print("   New activeField: \(activeField)")
                            print("   Cleared searchText: '\(searchText)'")
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
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color("Primary"))
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
                            print("   Current searchText: '\(searchText)'")
                            print("   Current activeField: \(activeField)")
                            activeField = .destination
                            searchText = "" // Clear search text when switching fields
                            searchService.clearSearchState()
                            print("   New activeField: \(activeField)")
                            print("   Cleared searchText: '\(searchText)'")
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
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color("Primary"))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(activeField == .destination ? Color.red.opacity(0.9) : Color.gray.opacity(0.3), lineWidth: activeField == .destination ? 2 : 1)
                )
                
//                // Search Field (only shown when a field is active)
//                if activeField != .none {
//                    VStack(spacing: 0) {
//                        HStack(spacing: 12) {
//                            Image("maper")
//                                .renderingMode(.template)
//                                .resizable()
//                                .frame(width: 20, height: 20)
//                                .foregroundColor(Color(.systemBlue))
//                            
//                            TextField("Search for \(activeField == .pickup ? "pickup" : "destination") location", text: $searchText)
//                                .font(.body)
//                                .foregroundColor(.primary)
//                                .autocorrectionDisabled()
//                                .textInputAutocapitalization(.words)
//                            
//                            if !searchText.isEmpty {
//                                Button {
//                                    searchText = ""
//                                    searchService.clearSearchState()
//                                } label: {
//                                    Image(systemName: "xmark.circle.fill")
//                                        .foregroundColor(.gray)
//                                }
//                            }
//                        }
//                        .padding(.horizontal, 20)
//                        .padding(.vertical, 16)
//                    }
//                    .background(Color("Primary"))
//                    .clipShape(RoundedRectangle(cornerRadius: 15))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 15)
//                            .stroke(Color.blue.opacity(0.9), lineWidth: 2)
//                    )
//                }
            }
        }
    }
    

    
    // MARK: - Loading Section
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
        .background(Color("Primary"))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    // MARK: - Search Results Section
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
            .background(Color("Primary"))
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
    
    // MARK: - No Results Section
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
        .background(Color("Primary"))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    // MARK: - Recent Searches Section
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
                            // Clear recent searches
                        }
                        .font(.caption)
                        .foregroundColor(Color("Secondary"))
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
                    .background(Color("Primary"))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
            }
        }
    }
    
    // MARK: - Popular Searches Section
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
                    .background(Color("Primary"))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadInitialData() async {
        guard let userId = authModel.currentUser?.id else { return }
        
        async let recentSearches: Void = searchService.fetchRecentSearches(userId: userId)
        async let popularSearches: Void = searchService.fetchPopularSearches()
        
        _ = await (recentSearches, popularSearches)
    }
    
    private func performSearch(query: String) {
        print("🔍 SearchScreen.performSearch called with query: '\(query)'")
        print("   Active field: \(activeField)")
        print("   Query length: \(query.count)")
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
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
        
        print("   🚀 Calling searchService.searchWithDebounce...")
        searchService.searchWithDebounce(
            query: query,
            searchType: selectedSearchType,
            userId: userId,
            userLocation: userLocation
        )
        print("   ✅ searchWithDebounce called successfully")
    }
    
    private func selectPrediction(_ prediction: PlacePrediction, at index: Int) {
        guard let userId = authModel.currentUser?.id else { return }
        
        selectedPrediction = prediction
        
        Task {
            await searchService.confirmSearch(
                prediction: prediction,
                searchType: selectedSearchType,
                userId: userId,
                selectedIndex: index
            )
            
            // Get the selected location details
            if let locationService = try? await GooglePlacesService().fetchPlaceDetails(placeId: prediction.placeId) {
                
                // Handle field selection based on active field
                switch activeField {
                case .pickup:
                    fromLocation = locationService
                    pickupText = prediction.mainText
                    // Clear search and switch to destination
                    searchText = ""
                    searchService.clearSearchState()
                    activeField = .destination
                    
                case .destination:
                    toLocation = locationService
                    destinationText = prediction.mainText
                    // Clear search and deactivate field
                    searchText = ""
                    searchService.clearSearchState()
                    activeField = .none
                    
                    // If we have both locations, trigger route selection
                    if let from = fromLocation {
                        onRouteSelected?(from, locationService)
                        dismiss()
                    }
                    
                case .none:
                    // Fallback to original behavior
                    toLocation = locationService
                    destinationText = prediction.mainText
                }
                
                // If we only have destination but no pickup, create current location as pickup
                if fromLocation == nil && toLocation != nil && activeField == .none {
                    let currentLocation = SearchLocation(
                        placeId: nil,
                        name: "Current Location",
                        address: "Your current location",
                        latitude: locationManager.currentLocation?.coordinate.latitude ?? -6.7924,
                        longitude: locationManager.currentLocation?.coordinate.longitude ?? 39.2083,
                        city: "Dar es Salaam",
                        country: "Tanzania",
                        postalCode: nil
                    )
                    fromLocation = currentLocation
                    pickupText = "Current Location"
                    
                    if let to = toLocation {
                        onRouteSelected?(currentLocation, to)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func useRecentSearch(_ search: SearchQuery) {
        searchText = search.searchText
        selectedSearchType = search.searchType
        performSearch(query: search.searchText)
    }
    
    private func usePopularSearch(_ search: SearchQuery) {
        searchText = search.searchText
        selectedSearchType = search.searchType
        performSearch(query: search.searchText)
    }
    
    private func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }
}

// MARK: - Search Type Button
struct SearchTypeButton: View {
    let searchType: SearchType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: iconForSearchType(searchType))
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : Color("Secondary"))
                
                Text(searchType.displayName)
                    .font(.body)
                   
                    .foregroundColor(isSelected ? .white : Color("Secondary"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                isSelected ? Color("Secondary") : Color("Primary")
            )
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForSearchType(_ type: SearchType) -> String {
        switch type {
        case .pickup: return "location.circle"
        case .destination: return "flag.circle"
        case .general: return "magnifyingglass.circle"
        case .nearbyVehicles: return "car.circle"
        }
    }
}

// MARK: - Search Result Item
struct SearchResultItem: View {
    let prediction: PlacePrediction
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "location.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color("Secondary"))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(prediction.mainText)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if !prediction.secondaryText.isEmpty {
                        Text(prediction.secondaryText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(45))
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Search Item
struct RecentSearchItem: View {
    let search: SearchQuery
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "clock.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(search.searchText)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 4) {
                        Text(search.searchType.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(search.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Popular Search Item
struct PopularSearchItem: View {
    let search: SearchQuery
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "flame.circle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(search.searchText)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("Popular destination")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Location Picker View (Placeholder)
struct LocationPickerView: View {
    @Binding var selectedLocation: SearchLocation?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Location Picker")
                .navigationTitle("Pick Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    @Previewable @State var searchText = ""
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    
    return SearchScreen(searchText: $searchText, isPreview: true)
        .environmentObject(mockAuthModel)
}





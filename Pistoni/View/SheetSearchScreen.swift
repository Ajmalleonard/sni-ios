//
//  SheetSearchScreen.swift
//  Pistoni
//
//  Created for SearchView with suggestions and polyline route display
//

import SwiftUI
import GoogleMaps
import CoreLocation

struct SheetSearchScreen: View {
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
    
    // Route display states
    @State private var showRouteView = false
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var mapPosition = GMSCameraPosition.camera(
        withLatitude: 37.7749,
        longitude: -122.4194,
        zoom: 15.0
    )
    
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
        NavigationStack {
            ZStack {
                if showRouteView && fromLocation != nil && toLocation != nil {
                    // Route view with polyline map
                    routeMapView
                } else {
                    // Search interface
                    searchInterfaceView
                }
            }
            .navigationTitle(showRouteView ? "Your Route" : "Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(showRouteView ? "Back" : "Cancel") {
                        if showRouteView {
                            showRouteView = false
                            // Reset to allow new search
                            fromLocation = nil
                            toLocation = nil
                            pickupText = ""
                            destinationText = ""
                            activeField = .none
                            searchText = ""
                            searchService.clearSearchState()
                        } else {
                            dismiss()
                        }
                    }
                }
                
                if showRouteView {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            if let from = fromLocation, let to = toLocation {
                                onRouteSelected?(from, to)
                            }
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
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
    
    // MARK: - Route Map View
    
    private var routeMapView: some View {
        VStack(spacing: 0) {
            // Google Maps with route
            GoogleMapsView(mapPosition: $mapPosition)
                .frame(height: 300)
            
            // Route details
            ScrollView {
                VStack(spacing: 20) {
                    // Route summary card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Route Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("From")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(fromLocation?.name ?? "Pickup Location")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("To")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(toLocation?.name ?? "Destination")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            // Route stats
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Distance")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("8.5 km")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .center, spacing: 4) {
                                    Text("Duration")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("15 min")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Est. Cost")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$12-18")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color("Secondary"))
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color("Primary"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // Confirm route action
                            if let from = fromLocation, let to = toLocation {
                                onRouteSelected?(from, to)
                            }
                            dismiss()
                        }) {
                            Text("Confirm Route")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color("Secondary"))
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                        
                        Button(action: {
                            showRouteView = false
                            // Reset for new search
                            fromLocation = nil
                            toLocation = nil
                            pickupText = ""
                            destinationText = ""
                            activeField = .none
                            searchText = ""
                            searchService.clearSearchState()
                        }) {
                            Text("Search Again")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color("Secondary"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color("Primary"))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color("Secondary"), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Search Interface View
    
    private var searchInterfaceView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 25) {
                    // Search input section
                    searchInputSection
                    
                    // Content based on state
                    if activeField != .none && searchService.searchState.isSearching {
                        loadingSection
                    } else if activeField != .none && !searchService.searchState.predictions.isEmpty {
                        searchResultsSection
                    } else if activeField != .none && !searchText.isEmpty {
                        noResultsSection
                    } else if activeField == .none {
                        // Show recent and popular searches when no field is active
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
    }
    
    // MARK: - UI Sections
    
    private var searchInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plan Your Trip")
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
                            activeField = .destination
                            searchText = ""
                            searchService.clearSearchState()
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
                    .background(Color("Primary"))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue.opacity(0.9), lineWidth: 2)
                    )
                }
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
        .background(Color("Primary"))
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
            .background(Color("Primary"))
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
        .background(Color("Primary"))
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
                            searchService.searchState.recentSearches = []
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
    
    // MARK: - Helper Functions
    
    private func loadInitialData() async {
        // Load recent and popular searches
        if let userId = authModel.currentUser?.id {
            await searchService.fetchRecentSearches(userId: userId, limit: 10)
            await searchService.fetchPopularSearches(limit: 10)
        }
        
        // Request location permission
        locationManager.requestLocationPermission()
    }
    
    private func performSearch(query: String) {
        print("🔍 SheetSearchScreen.performSearch called with query: '\(query)'")
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
            placeId: prediction.id,
            name: prediction.mainText,
            address: prediction.secondaryText,
            latitude: 0.0, // Will be updated with actual coordinates
            longitude: 0.0,
            city: "",
            country: "",
            postalCode: ""
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
            
            // Check if both locations are set to show route view
            if fromLocation != nil && toLocation != nil {
                generateRouteCoordinates()
                showRouteView = true
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
    
    private func generateRouteCoordinates() {
        // Generate sample polyline coordinates for demonstration
        // In a real app, this would come from a routing service
        let startLat = 37.7749
        let startLng = -122.4194
        let endLat = 37.7849
        let endLng = -122.4094
        
        var coordinates: [CLLocationCoordinate2D] = []
        let steps = 20
        
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            let lat = startLat + (endLat - startLat) * progress
            let lng = startLng + (endLng - startLng) * progress
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
        
        routeCoordinates = coordinates
        
        // Update map position to show the route
        let centerLat = (startLat + endLat) / 2
        let centerLng = (startLng + endLng) / 2
        
        mapPosition = GMSCameraPosition.camera(
            withLatitude: centerLat,
            longitude: centerLng,
            zoom: 13.0
        )
    }
    
    private var routeAnnotations: [RouteAnnotation] {
        var annotations: [RouteAnnotation] = []
        
        if let from = fromLocation {
            annotations.append(RouteAnnotation(
                id: "pickup",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                title: from.name,
                isPickup: true
            ))
        }
        
        if let to = toLocation {
            annotations.append(RouteAnnotation(
                id: "destination",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                title: to.name,
                isPickup: false
            ))
        }
        
        return annotations
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

// MARK: - Supporting Types

struct RouteAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let isPickup: Bool
}

#Preview {
    @Previewable @State var searchText = ""
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    
    return SheetSearchScreen(searchText: $searchText, isPreview: true)
        .environmentObject(mockAuthModel)
}
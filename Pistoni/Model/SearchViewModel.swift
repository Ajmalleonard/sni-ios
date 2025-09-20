import Foundation
import Combine
import CoreLocation

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchState = SearchState()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFromLocation: SearchLocation?
    @Published var selectedToLocation: SearchLocation?
    
    // MARK: - Private Properties
    private let searchService: SearchService?
    private let googlePlacesService: GooglePlacesService?
    private var cancellables = Set<AnyCancellable>()
    
    // Flag to indicate if this instance is being used in a preview
    var isPreview: Bool = false
    
    // MARK: - Initialization
    init(searchService: SearchService? = nil, googlePlacesService: GooglePlacesService? = nil) {
        // Check if running in preview mode
        let isPreviewMode = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreviewMode {
            self.isPreview = true
            self.searchService = nil
            self.googlePlacesService = nil
        } else {
            self.searchService = searchService ?? SearchService()
            self.googlePlacesService = googlePlacesService ?? GooglePlacesService()
            // Set up bindings only in production mode
            setupBindings()
        }
    }
    
    // Sets up preview mode (no mock data)
    private func setupPreviewData() {
        // Preview mode setup without mock data
        guard isPreview else { return }
        // No mock data - let the app show real empty state
    }
    
    // MARK: - Setup Bindings
    private func setupBindings() {
        guard let searchService = searchService else { return }
        
        // Bind search service state to view model
        searchService.$searchState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchState in
                self?.searchState = searchState
                
                // Update selected locations based on search state
                self?.selectedFromLocation = searchState.fromLocation
                self?.selectedToLocation = searchState.toLocation
            }
            .store(in: &cancellables)
        
        searchService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        searchService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    private func mockSearchResults(for query: String) -> [SearchLocation] {
        return [
            SearchLocation(
                placeId: "place_1",
                name: "Sample Location 1",
                address: "123 Main St, City",
                latitude: 37.7749,
                longitude: -122.4194,
                city: "City",
                country: "USA",
                postalCode: "12345"
            ),
            SearchLocation(
                placeId: "place_2",
                name: "Sample Location 2",
                address: "456 Oak Ave, Town",
                latitude: 37.7849,
                longitude: -122.4094,
                city: "Town",
                country: "USA",
                postalCode: "67890"
            )
        ]
    }
    
    // MARK: - Search Methods
    func performSearch(
        query: String,
        searchType: SearchType = .general,
        userId: String,
        userLocation: CLLocationCoordinate2D? = nil
    ) {
        // Skip network calls in preview mode
        if isPreview {
            return
        }
        
        guard let searchService = searchService else { return }
        
        searchService.searchWithDebounce(
            query: query,
            searchType: searchType,
            userId: userId,
            userLocation: userLocation
        )
    }
    
    func confirmSearchSelection(
        prediction: PlacePrediction,
        searchType: SearchType,
        userId: String,
        selectedIndex: Int
    ) async {
        // Skip network calls in preview mode
        if isPreview {
            return
        }
        
        guard let searchService = searchService else { return }
        
        await searchService.confirmSearch(
            prediction: prediction,
            searchType: searchType,
            userId: userId,
            selectedIndex: selectedIndex
        )
    }
    
    func clearSearch() {
        if !isPreview {
            searchService?.clearSearchState()
        }
        selectedFromLocation = nil
        selectedToLocation = nil
    }
    
    // MARK: - Location Selection Methods
    func selectFromLocation(_ location: SearchLocation) {
        selectedFromLocation = location
        searchState.fromLocation = location
    }
    
    func selectToLocation(_ location: SearchLocation) {
        selectedToLocation = location
        searchState.toLocation = location
    }
    
    func swapLocations() {
        let temp = selectedFromLocation
        selectedFromLocation = selectedToLocation
        selectedToLocation = temp
        
        searchState.fromLocation = selectedFromLocation
        searchState.toLocation = selectedToLocation
    }
    
    // MARK: - Search History Methods
    func loadRecentSearches(userId: String, limit: Int = 10) async {
        // Skip network calls in preview mode
        if isPreview {
            return
        }
        
        guard let searchService = searchService else { return }
        
        await searchService.fetchRecentSearches(userId: userId, limit: limit)
    }
    
    func loadPopularSearches(limit: Int = 10) async {
        // Skip network calls in preview mode
        if isPreview {
            return
        }
        
        guard let searchService = searchService else { return }
        
        await searchService.fetchPopularSearches(limit: limit)
    }
    
    func useRecentSearch(_ search: SearchQuery) {
        searchState.searchText = search.searchText
        searchState.currentSearchType = search.searchType
        
        if let fromLocation = search.fromLocation {
            selectFromLocation(fromLocation)
        }
        
        if let toLocation = search.toLocation {
            selectToLocation(toLocation)
        }
    }
    
    // MARK: - Nearby Search Methods
    func searchNearbyPlaces(
        location: CLLocationCoordinate2D,
        radius: Int = 5000,
        type: String? = nil,
        keyword: String? = nil
    ) async {
        // Skip network calls in preview mode
        if isPreview {
            return
        }
        
        guard let googlePlacesService = googlePlacesService else { return }
        
        do {
            isLoading = true
            let predictions = try await googlePlacesService.searchNearbyPlaces(
                location: location,
                radius: radius,
                type: type,
                keyword: keyword
            )
            
            searchState.predictions = predictions
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Validation Methods
    var isFromLocationSelected: Bool {
        selectedFromLocation != nil
    }
    
    var isToLocationSelected: Bool {
        selectedToLocation != nil
    }
    
    var canProceedWithSearch: Bool {
        isFromLocationSelected || isToLocationSelected || !searchState.searchText.isEmpty
    }
    
    var searchSummary: String {
        var components: [String] = []
        
        if let from = selectedFromLocation {
            components.append("From: \(from.name)")
        }
        
        if let to = selectedToLocation {
            components.append("To: \(to.name)")
        }
        
        if !searchState.searchText.isEmpty && components.isEmpty {
            components.append("Search: \(searchState.searchText)")
        }
        
        return components.isEmpty ? "No location selected" : components.joined(separator: " • ")
    }
    
    // MARK: - Analytics Methods
    func trackSearchEvent(_ event: SearchAnalyticsEvent, additionalData: [String: Any] = [:]) async {
        // Skip analytics in preview mode
        if isPreview {
            return
        }
        
        guard let searchService = searchService else { return }
        
        // Track search analytics
        await searchService.trackSearchAnalytics(event, additionalData: additionalData)
    }
    
    // MARK: - Route Calculation (Future Implementation)
    func calculateRoute() async -> RouteCalculation? {
        guard let from = selectedFromLocation,
              let to = selectedToLocation else {
            return nil
        }
        
        // This would integrate with a routing service (Google Directions, etc.)
        // For now, return a placeholder
        return RouteCalculation(
            fromLocation: from,
            toLocation: to,
            distance: calculateDistance(from: from.coordinate, to: to.coordinate),
            estimatedDuration: 0,
            routePolyline: nil
        )
    }
    
    // MARK: - Helper Methods
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) // Returns distance in meters
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Route Calculation Model
struct RouteCalculation {
    let fromLocation: SearchLocation
    let toLocation: SearchLocation
    let distance: Double // in meters
    let estimatedDuration: TimeInterval // in seconds
    let routePolyline: String? // encoded polyline for map display
    
    var distanceFormatted: String {
        let distanceInKm = distance / 1000
        if distanceInKm < 1 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distanceInKm)
        }
    }
    
    var durationFormatted: String {
        let minutes = Int(estimatedDuration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Search Context Helper
extension SearchViewModel {
    func createSearchContext(userId: String) -> SearchContext {
        SearchContext(
            userId: userId,
            fromLocation: selectedFromLocation,
            toLocation: selectedToLocation,
            searchText: searchState.searchText,
            searchType: searchState.currentSearchType,
            timestamp: Date()
        )
    }
}

struct SearchContext {
    let userId: String
    let fromLocation: SearchLocation?
    let toLocation: SearchLocation?
    let searchText: String
    let searchType: SearchType
    let timestamp: Date
    
    var hasValidRoute: Bool {
        fromLocation != nil && toLocation != nil
    }
    
    var hasAnyLocation: Bool {
        fromLocation != nil || toLocation != nil
    }
}
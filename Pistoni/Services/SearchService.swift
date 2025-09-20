//
//  SearchService.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 12/08/2025.
//

import Foundation
import CoreLocation
import Combine
import UIKit

class SearchService: ObservableObject {
    @Published var searchState = SearchState()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let googlePlacesService: GooglePlacesService
    private let backendSearchService: BackendSearchService
    private var searchDebounceTimer: Timer?
    private let debounceDelay: TimeInterval = 0.5
    
    // Flag to indicate if this instance is being used in a preview
    private let isPreview: Bool
    
    init(isPreview: Bool = false) {
        self.isPreview = isPreview || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        // Initialize services
        self.googlePlacesService = GooglePlacesService(isPreview: self.isPreview)
        self.backendSearchService = BackendSearchService(isPreview: self.isPreview)
        
        // Set up mock data for previews
        if self.isPreview {
            setupPreviewData()
        }
    }
    
    // Sets up preview mode (no mock data)
    private func setupPreviewData() {
        // Preview mode setup without mock data
        guard isPreview else { return }
        // No mock data - let the app show real empty state
    }
    
    // MARK: - Search with Debouncing
    func searchWithDebounce(
        query: String,
        searchType: SearchType = .general,
        userId: String,
        userLocation: CLLocationCoordinate2D? = nil
    ) {
        // Cancel previous timer
        searchDebounceTimer?.invalidate()
        
        // Update search text immediately for UI responsiveness
        searchState.searchText = query
        searchState.currentSearchType = searchType
        
        // Clear predictions if query is empty
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchState.predictions = []
            searchState.isSearching = false
            return
        }
        
        // Skip network calls in preview mode
        if isPreview {
            // Use the mock data already set up in setupPreviewData()
            // Just simulate a short delay for UI feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isLoading = false
                self?.searchState.isSearching = false
            }
            return
        }
        
        // Set loading state
        searchState.isSearching = true
        isLoading = true
        
        // Create debounced search timer
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { [weak self] _ in
            Task {
                await self?.performSearch(
                    query: query,
                    searchType: searchType,
                    userId: userId,
                    userLocation: userLocation
                )
            }
        }
    }
    
    // MARK: - Perform Actual Search
    private func performSearch(
        query: String,
        searchType: SearchType,
        userId: String,
        userLocation: CLLocationCoordinate2D?
    ) async {
        do {
            let startTime = Date()
            
            // Get place types for this search context
            let placeTypes = GooglePlacesService.getPlaceTypes(for: searchType)
            
            // Fetch predictions from Google Places API
            let predictions = try await googlePlacesService.fetchPlacePredictions(
                query: query,
                location: userLocation,
                types: placeTypes
            )
            
            let searchDuration = Date().timeIntervalSince(startTime)
            
            // Update UI on main thread
            await MainActor.run {
                searchState.predictions = predictions
                searchState.isSearching = false
                searchState.errorMessage = nil
                isLoading = false
            }
            
            // Save search query to backend (non-confirmed search)
            let searchQuery = SearchQuery(
                userId: userId,
                searchText: query,
                searchType: searchType,
                isConfirmed: false,
                metadata: SearchMetadata(
                    deviceInfo: await getDeviceInfo(),
                    appVersion: getAppVersion(),
                    searchDuration: searchDuration,
                    resultsCount: predictions.count,
                    selectedResultIndex: nil
                )
            )
            
            await saveSearchToBackend(searchQuery)
            
        } catch {
            await MainActor.run {
                searchState.isSearching = false
                searchState.errorMessage = error.localizedDescription
                isLoading = false
                print("❌ Search error: \(error)")
            }
        }
    }
    
    // MARK: - Confirm Search Selection
    func confirmSearch(
        prediction: PlacePrediction,
        searchType: SearchType,
        userId: String,
        selectedIndex: Int
    ) async {
        do {
            // Create confirmed search query
            let searchQuery = SearchQuery(
                userId: userId,
                searchText: prediction.description,
                searchType: searchType,
                isConfirmed: true,
                metadata: SearchMetadata(
                    deviceInfo: await getDeviceInfo(),
                    appVersion: getAppVersion(),
                    searchDuration: nil,
                    resultsCount: 1,
                    selectedResultIndex: selectedIndex
                )
            )
            
            // Save confirmed search to backend
            await saveSearchToBackend(searchQuery)
            
            // Update search state
            await MainActor.run {
                searchState.searchText = prediction.description
                searchState.currentSearchType = searchType
                searchState.predictions = []
                searchState.isSearching = false
            }
        } catch {
            await MainActor.run {
                searchState.errorMessage = error.localizedDescription
                searchState.isSearching = false
            }
        }
    }
    
    // MARK: - Save Search to Backend
    private func saveSearchToBackend(_ searchQuery: SearchQuery) async {
        // Convert SearchQuery to backend format
        let location: Location? = nil // TODO: Convert SearchLocation to Location if needed
        
        backendSearchService.saveSearch(query: searchQuery.searchText, location: location) { result in
            switch result {
            case .success(let searchHistory):
                print("✅ Search saved to backend: \(searchHistory.id)")
            case .failure(let error):
                print("❌ Error saving search to backend: \(error)")
            }
        }
    }
    
    // MARK: - Fetch Recent Searches
    func fetchRecentSearches(userId: String, limit: Int = 10) async {
        backendSearchService.getRecentSearches { result in
            Task { @MainActor in
                switch result {
                case .success(let searches):
                    // Convert backend searches to SearchQuery format
                    let searchQueries = searches.map { searchHistory in
                        SearchQuery(
                            id: searchHistory.id,
                            userId: searchHistory.userId,
                            searchText: searchHistory.query,
                            searchType: .general, // Default type
                            timestamp: searchHistory.createdAt,
                            isConfirmed: true
                        )
                    }
                    self.searchState.recentSearches = searchQueries
                case .failure(let error):
                    print("❌ Error fetching recent searches: \(error)")
                }
            }
        }
    }
    
    // MARK: - Fetch Popular Searches
    func fetchPopularSearches(limit: Int = 10) async {
        backendSearchService.getPopularSearches { result in
            Task { @MainActor in
                switch result {
                case .success(let searches):
                    // Convert backend searches to SearchQuery format
                    let searchQueries = searches.map { popularSearch in
                        SearchQuery(
                            userId: "", // Popular searches don't have user ID
                            searchText: popularSearch.query,
                            searchType: .general,
                            isConfirmed: true
                        )
                    }
                    self.searchState.popularSearches = searchQueries
                case .failure(let error):
                    print("❌ Error fetching popular searches: \(error)")
                }
            }
        }
    }
    
    // MARK: - Clear Search State
    func clearSearchState() {
        searchState.searchText = ""
        searchState.predictions = []
        searchState.isSearching = false
        searchState.errorMessage = nil
        searchDebounceTimer?.invalidate()
    }
    
    // MARK: - Helper Methods
    private func getDeviceInfo() async -> String {
        return await UIDevice.current.model
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    // MARK: - Analytics
    func trackSearchAnalytics(_ event: SearchAnalyticsEvent, additionalData: [String: Any] = [:]) async {
        // TODO: Implement analytics tracking
        print("Analytics Event: \(event.displayName) - \(additionalData)")
    }
}
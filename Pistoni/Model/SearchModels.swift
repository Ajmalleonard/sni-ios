import Foundation
import CoreLocation

// MARK: - Search Models
struct SearchQuery: Codable, Identifiable, Sendable {
    let id: String
    let userId: String
    let fromLocation: SearchLocation?
    let toLocation: SearchLocation?
    let searchText: String
    let searchType: SearchType
    let timestamp: Date
    let isConfirmed: Bool
    let metadata: SearchMetadata?
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        fromLocation: SearchLocation? = nil,
        toLocation: SearchLocation? = nil,
        searchText: String,
        searchType: SearchType,
        timestamp: Date = Date(),
        isConfirmed: Bool = false,
        metadata: SearchMetadata? = nil
    ) {
        self.id = id
        self.userId = userId
        self.fromLocation = fromLocation
        self.toLocation = toLocation
        self.searchText = searchText
        self.searchType = searchType
        self.timestamp = timestamp
        self.isConfirmed = isConfirmed
        self.metadata = metadata
    }
}

struct SearchLocation: Codable, Sendable {
    let placeId: String?
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let city: String?
    let country: String?
    let postalCode: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct SearchMetadata: Codable, Sendable {
    let deviceInfo: String?
    let appVersion: String?
    let searchDuration: TimeInterval?
    let resultsCount: Int?
    let selectedResultIndex: Int?
}

enum SearchType: String, Codable, CaseIterable, Sendable {
    case pickup = "pickup"
    case destination = "destination"
    case general = "general"
    case nearbyVehicles = "nearby_vehicles"
    
    var displayName: String {
        switch self {
        case .pickup: return "Pickup Location"
        case .destination: return "Destination"
        case .general: return "General Search"
        case .nearbyVehicles: return "Nearby Vehicles"
        }
    }
}

// MARK: - Google Places Models
struct PlacePrediction: Codable, Identifiable, Sendable {
    let id: String
    let placeId: String
    let description: String
    let mainText: String
    let secondaryText: String
    let types: [String]
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case description
        case structuredFormatting = "structured_formatting"
        case types
    }
    
    enum StructuredFormattingKeys: String, CodingKey {
        case mainText = "main_text"
        case secondaryText = "secondary_text"
    }
    
    init(
        id: String = UUID().uuidString,
        placeId: String,
        description: String,
        mainText: String,
        secondaryText: String,
        types: [String] = []
    ) {
        self.id = id
        self.placeId = placeId
        self.description = description
        self.mainText = mainText
        self.secondaryText = secondaryText
        self.types = types
    }
    
    // Custom Decodable implementation to handle nested structured_formatting
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = UUID().uuidString
        self.placeId = try container.decode(String.self, forKey: .placeId)
        self.description = try container.decode(String.self, forKey: .description)
        self.types = try container.decodeIfPresent([String].self, forKey: .types) ?? []
        
        // Handle nested structured_formatting
        if let structuredFormattingContainer = try? container.nestedContainer(keyedBy: StructuredFormattingKeys.self, forKey: .structuredFormatting) {
            self.mainText = try structuredFormattingContainer.decodeIfPresent(String.self, forKey: .mainText) ?? description
            self.secondaryText = try structuredFormattingContainer.decodeIfPresent(String.self, forKey: .secondaryText) ?? ""
        } else {
            // Fallback if structured_formatting is not available
            self.mainText = description
            self.secondaryText = ""
        }
    }
    
    // Custom Encodable implementation
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(placeId, forKey: .placeId)
        try container.encode(description, forKey: .description)
        try container.encode(types, forKey: .types)
        
        // Encode nested structured_formatting
        var structuredFormattingContainer = container.nestedContainer(keyedBy: StructuredFormattingKeys.self, forKey: .structuredFormatting)
        try structuredFormattingContainer.encode(mainText, forKey: .mainText)
        try structuredFormattingContainer.encode(secondaryText, forKey: .secondaryText)
    }
}

struct PlaceDetails: Codable, Sendable {
    let placeId: String
    let name: String
    let formattedAddress: String
    let geometry: PlaceGeometry
    let addressComponents: [AddressComponent]?
    let types: [String]
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case formattedAddress = "formatted_address"
        case geometry
        case addressComponents = "address_components"
        case types
    }
}

struct PlaceGeometry: Codable, Sendable {
    let location: PlaceLocation
}

struct PlaceLocation: Codable, Sendable {
    let lat: Double
    let lng: Double
}

struct AddressComponent: Codable, Sendable {
    let longName: String
    let shortName: String
    let types: [String]
    
    enum CodingKeys: String, CodingKey {
        case longName = "long_name"
        case shortName = "short_name"
        case types
    }
}

// MARK: - Search State Models
struct SearchState: Sendable {
    var isSearching: Bool = false
    var searchText: String = ""
    var fromLocation: SearchLocation?
    var toLocation: SearchLocation?
    var predictions: [PlacePrediction] = []
    var recentSearches: [SearchQuery] = []
    var popularSearches: [SearchQuery] = []
    var currentSearchType: SearchType = .general
    var errorMessage: String?
}

// MARK: - Search Error Types
enum SearchError: Error, LocalizedError, Sendable {
    case invalidQuery
    case networkError(Error)
    case googlePlacesError(String)
    case firebaseError(String)
    case locationPermissionDenied
    case noResults
    case invalidURL
    case invalidResponse
    case unexpectedResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidQuery:
            return "Invalid search query"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .googlePlacesError(let message):
            return "Google Places error: \(message)"
        case .firebaseError(let message):
            return "Database error: \(message)"
        case .locationPermissionDenied:
            return "Location permission is required for search"
        case .noResults:
            return "No results found for your search"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unexpectedResponse:
            return "Unexpected response from server"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Sample Data for Previews
extension SearchQuery {
    static let sampleSearches: [SearchQuery] = [
        SearchQuery(
            userId: "user123",
            fromLocation: SearchLocation(
                placeId: "place1",
                name: "Times Square",
                address: "Times Square, New York, NY, USA",
                latitude: 40.7580,
                longitude: -73.9855,
                city: "New York",
                country: "USA",
                postalCode: "10036"
            ),
            toLocation: SearchLocation(
                placeId: "place2",
                name: "Central Park",
                address: "Central Park, New York, NY, USA",
                latitude: 40.7829,
                longitude: -73.9654,
                city: "New York",
                country: "USA",
                postalCode: "10024"
            ),
            searchText: "Times Square to Central Park",
            searchType: .general,
            isConfirmed: true
        ),
        SearchQuery(
            userId: "user123",
            searchText: "Airport pickup",
            searchType: .pickup,
            isConfirmed: true
        )
    ]
    
    static let sampleSearch = sampleSearches[0]
}

// MARK: - Search Analytics
enum SearchAnalyticsEvent: String, Codable, Sendable {
    case searchStarted = "search_started"
    case searchCompleted = "search_completed"
    case locationSelected = "location_selected"
    case searchCancelled = "search_cancelled"
    case routeCalculated = "route_calculated"
    case searchError = "search_error"
    
    var displayName: String {
        switch self {
        case .searchStarted: return "Search Started"
        case .searchCompleted: return "Search Completed"
        case .locationSelected: return "Location Selected"
        case .searchCancelled: return "Search Cancelled"
        case .routeCalculated: return "Route Calculated"
        case .searchError: return "Search Error"
        }
    }
}

extension PlacePrediction {
    static let samplePredictions: [PlacePrediction] = [
        PlacePrediction(
            placeId: "place1",
            description: "Times Square, New York, NY, USA",
            mainText: "Times Square",
            secondaryText: "New York, NY, USA",
            types: ["tourist_attraction", "point_of_interest"]
        ),
        PlacePrediction(
            placeId: "place2",
            description: "Central Park, New York, NY, USA",
            mainText: "Central Park",
            secondaryText: "New York, NY, USA",
            types: ["park", "tourist_attraction"]
        )
    ]
}
import Foundation
import CoreLocation
import Combine

class GooglePlacesService: ObservableObject {
    private let apiKey: String = APIConfig.googlePlacesAPIKey
    private let baseURL = "https://maps.googleapis.com/maps/api"
    private let session = URLSession.shared
    
    // Flag to indicate if this instance is being used in a preview
    private let isPreview: Bool
    
    init(isPreview: Bool = false) {
        self.isPreview = isPreview || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    // MARK: - Mock Data for Previews
    private func getMockPlacePredictions(query: String) -> [PlacePrediction] {
        // Return empty array - no mock data
        return []
    }
    
    // MARK: - Autocomplete Places
    func fetchPlacePredictions(
        query: String,
        location: CLLocationCoordinate2D? = nil,
        radius: Int = 50000,
        types: String? = nil
    ) async throws -> [PlacePrediction] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("🔍 Empty query, returning empty results")
            return []
        }
        
        // Return mock data in preview mode
        if isPreview {
            print("🎭 Preview mode: returning mock data")
            return getMockPlacePredictions(query: query)
        }
        
        // Check if API key is configured
        guard APIConfig.isGooglePlacesConfigured else {
            print("⚠️ Google Places API key not configured. Please set your API key in APIConfig.swift")
            print("🔑 Current API key: \(apiKey.prefix(10))...")
            print("🔍 Is configured: \(APIConfig.isGooglePlacesConfigured)")
            throw SearchError.googlePlacesError("Google Places API key not configured")
        }
        
        print("🌍 Google Places API Request:")
        print("   Query: '\(query)'")
        print("   Location: \(location?.latitude ?? 0), \(location?.longitude ?? 0)")
        print("   API Key: \(apiKey.prefix(10))...")
        print("   Types: \(types ?? "none")")
        
        var components = URLComponents(string: "\(baseURL)/place/autocomplete/json")
        var queryItems = [
            URLQueryItem(name: "input", value: query),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        // Add location bias if provided
        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"))
            queryItems.append(URLQueryItem(name: "radius", value: "\(radius)"))
        }
        
        // Add place types filter if provided
        if let types = types {
            queryItems.append(URLQueryItem(name: "types", value: types))
        }
        
        // Add session token for billing optimization
        queryItems.append(URLQueryItem(name: "sessiontoken", value: UUID().uuidString))
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            print("❌ Failed to create URL")
            throw SearchError.invalidQuery
        }
        
        print("🔗 Request URL: \(url.absoluteString)")
        
        do {
            print("📡 Making network request...")
            let (data, response) = try await session.data(from: url)
            
            print("📥 Response received")
            print("   Data size: \(data.count) bytes")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("   Status code: \(httpResponse.statusCode)")
                print("   Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Bad HTTP response: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw SearchError.networkError(URLError(.badServerResponse))
            }
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(responseString.prefix(500))...")
            }
            
            let autocompleteResponse = try JSONDecoder().decode(AutocompleteResponse.self, from: data)
            
            print("✅ Successfully decoded response")
            print("   Status: \(autocompleteResponse.status)")
            print("   Predictions count: \(autocompleteResponse.predictions.count)")
            
            if autocompleteResponse.status != "OK" && autocompleteResponse.status != "ZERO_RESULTS" {
                print("❌ Google Places API error: \(autocompleteResponse.status)")
                throw SearchError.googlePlacesError(autocompleteResponse.status)
            }
            
            let predictions = autocompleteResponse.predictions.map { prediction in
                PlacePrediction(
                    placeId: prediction.placeId,
                    description: prediction.description,
                    mainText: prediction.structuredFormatting?.mainText ?? prediction.description,
                    secondaryText: prediction.structuredFormatting?.secondaryText ?? "",
                    types: prediction.types
                )
            }
            
            print("🎯 Returning \(predictions.count) predictions")
            return predictions
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error: \(decodingError)")
            throw SearchError.networkError(decodingError)
        } catch {
            print("❌ Network error: \(error)")
            throw SearchError.networkError(error)
        }
    }
    
    // MARK: - Place Details
    func fetchPlaceDetails(placeId: String) async throws -> SearchLocation {
        var components = URLComponents(string: "\(baseURL)/place/details/json")
        components?.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "place_id,name,formatted_address,geometry,address_components,types"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw SearchError.invalidQuery
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SearchError.networkError(URLError(.badServerResponse))
            }
            
            let detailsResponse = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
            
            if detailsResponse.status != "OK" {
                throw SearchError.googlePlacesError(detailsResponse.status)
            }
            
            let place = detailsResponse.result
            
            // Extract city, country, and postal code from address components
            var city: String?
            var country: String?
            var postalCode: String?
            
            if let addressComponents = place.addressComponents {
                for component in addressComponents {
                    if component.types.contains("locality") {
                        city = component.longName
                    } else if component.types.contains("country") {
                        country = component.longName
                    } else if component.types.contains("postal_code") {
                        postalCode = component.longName
                    }
                }
            }
            
            return SearchLocation(
                placeId: place.placeId,
                name: place.name,
                address: place.formattedAddress,
                latitude: place.geometry.location.lat,
                longitude: place.geometry.location.lng,
                city: city,
                country: country,
                postalCode: postalCode
            )
            
        } catch {
            throw SearchError.networkError(error)
        }
    }
    
    // MARK: - Nearby Search
    func searchNearbyPlaces(
        location: CLLocationCoordinate2D,
        radius: Int = 5000,
        type: String? = nil,
        keyword: String? = nil
    ) async throws -> [PlacePrediction] {
        var components = URLComponents(string: "\(baseURL)/place/nearbysearch/json")
        var queryItems = [
            URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw SearchError.invalidQuery
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SearchError.networkError(URLError(.badServerResponse))
            }
            
            let nearbyResponse = try JSONDecoder().decode(NearbySearchResponse.self, from: data)
            
            if nearbyResponse.status != "OK" && nearbyResponse.status != "ZERO_RESULTS" {
                throw SearchError.googlePlacesError(nearbyResponse.status)
            }
            
            return nearbyResponse.results.map { place in
                PlacePrediction(
                    placeId: place.placeId,
                    description: place.vicinity ?? place.name,
                    mainText: place.name,
                    secondaryText: place.vicinity ?? "",
                    types: place.types
                )
            }
            
        } catch {
            throw SearchError.networkError(error)
        }
    }
}

// MARK: - Google Places API Response Models
private struct AutocompleteResponse: Codable {
    let predictions: [AutocompletePrediction]
    let status: String
}

private struct AutocompletePrediction: Codable {
    let placeId: String
    let description: String
    let types: [String]
    let structuredFormatting: StructuredFormatting?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case description
        case types
        case structuredFormatting = "structured_formatting"
    }
}

private struct StructuredFormatting: Codable {
    let mainText: String
    let secondaryText: String?
    
    enum CodingKeys: String, CodingKey {
        case mainText = "main_text"
        case secondaryText = "secondary_text"
    }
}

private struct PlaceDetailsResponse: Codable {
    let result: PlaceDetails
    let status: String
}

private struct NearbySearchResponse: Codable {
    let results: [NearbyPlace]
    let status: String
}

private struct NearbyPlace: Codable {
    let placeId: String
    let name: String
    let vicinity: String?
    let types: [String]
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case vicinity
        case types
    }
}

// MARK: - Configuration Extension
extension GooglePlacesService {
    // Common place types for filtering
    enum PlaceType: String, CaseIterable {
        case establishment = "establishment"
        case geocode = "geocode"
        case address = "address"
        case cities = "(cities)"
        case regions = "(regions)"
        case airport = "airport"
        case trainStation = "train_station"
        case busStation = "bus_station"
        
        var displayName: String {
            switch self {
            case .establishment: return "Businesses"
            case .geocode: return "Addresses"
            case .address: return "Street Addresses"
            case .cities: return "Cities"
            case .regions: return "Regions"
            case .airport: return "Airports"
            case .trainStation: return "Train Stations"
            case .busStation: return "Bus Stations"
            }
        }
    }
    
    // Helper method to get appropriate place types for search context
    static func getPlaceTypes(for searchType: SearchType) -> String? {
        switch searchType {
        case .pickup, .destination:
            return "establishment|geocode|airport|train_station|bus_station"
        case .general:
            return "establishment|geocode"
        case .nearbyVehicles:
            return "establishment"
        }
    }
}
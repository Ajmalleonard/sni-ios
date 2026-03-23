import Foundation
import CoreLocation
import Combine

class DirectionsService: ObservableObject {
    private let apiKey: String = APIConfig.googlePlacesAPIKey // Reusing the same key, assuming it has Directions API enabled
    private let baseURL = "https://maps.googleapis.com/maps/api/directions/json"
    
    @Published var isLoading = false
    
    enum DirectionsError: Error {
        case invalidURL
        case networkError(Error)
        case noRoutesFound
        case decodingError(Error)
        case apiError(String)
    }
    
    // MARK: - Fetch Directions
    func fetchDirections(from origin: SearchLocation, to destination: SearchLocation) async throws -> RouteInfo {
        var components = URLComponents(string: baseURL)
        
        let originQuery = "\(origin.latitude),\(origin.longitude)"
        let destinationQuery = "\(destination.latitude),\(destination.longitude)"
        
        components?.queryItems = [
            URLQueryItem(name: "origin", value: originQuery),
            URLQueryItem(name: "destination", value: destinationQuery),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "mode", value: "driving")
        ]
        
        guard let url = components?.url else {
            throw DirectionsError.invalidURL
        }
        
        print("🛣️ Directions API Request: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw DirectionsError.networkError(URLError(.badServerResponse))
            }
            
            let directionsResponse = try JSONDecoder().decode(DirectionsResponse.self, from: data)
            
            if directionsResponse.status != "OK" {
                throw DirectionsError.apiError(directionsResponse.status)
            }
            
            guard let route = directionsResponse.routes.first,
                  let leg = route.legs.first else {
                throw DirectionsError.noRoutesFound
            }
            
            // Extract route info
            return RouteInfo(
                fromLocation: origin,
                toLocation: destination,
                distance: leg.distance.text,
                duration: leg.duration.text,
                estimatedCost: calculateEstimatedCost(distanceValue: leg.distance.value, durationValue: leg.duration.value),
                routePolyline: route.overviewPolyline.points
            )
            
        } catch {
            print("❌ Directions Error: \(error)")
            throw error
        }
    }
    
    private func calculateEstimatedCost(distanceValue: Int, durationValue: Int) -> String {
        // Simple mock calculation: Base $5 + $1 per km + $0.2 per minute
        let distanceKm = Double(distanceValue) / 1000.0
        let durationMin = Double(durationValue) / 60.0
        
        let cost = 5.0 + (distanceKm * 1.0) + (durationMin * 0.2)
        return String(format: "$%.2f", cost)
    }
}

// MARK: - Response Models
private struct DirectionsResponse: Codable {
    let routes: [Route]
    let status: String
}

private struct Route: Codable {
    let overviewPolyline: Polyline
    let legs: [Leg]
    
    enum CodingKeys: String, CodingKey {
        case overviewPolyline = "overview_polyline"
        case legs
    }
}

private struct Polyline: Codable {
    let points: String
}

private struct Leg: Codable {
    let distance: TextValue
    let duration: TextValue
}

private struct TextValue: Codable {
    let text: String
    let value: Int
}

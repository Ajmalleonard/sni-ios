//
//  BackendSearchService.swift
//  SNI Rentals
//
//  Created by Assistant on 08/01/25.
//

import Foundation
import Combine

class BackendSearchService: ObservableObject {
    private let baseURL = "https://api.pistoni.io"
    
    // Flag to indicate if this instance is being used in a preview
    private let isPreview: Bool
    
    init(isPreview: Bool = false) {
        self.isPreview = isPreview || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    // MARK: - Mock Data for Previews
    private func getMockSearchSuggestions(query: String) -> [SearchSuggestion] {
        // Return empty array - no mock data
        return []
    }
    
    // MARK: - Search Suggestions
    
    func getSearchSuggestions(query: String, completion: @escaping (Result<[SearchSuggestion], Error>) -> Void) {
        // Return mock data in preview mode
        if isPreview {
            let mockSuggestions = getMockSearchSuggestions(query: query)
            completion(.success(mockSuggestions))
            return
        }
        
        guard let url = URL(string: baseURL + "/search/suggestions?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            completion(.failure(SearchError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthorizationHeader()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(SearchError.invalidResponse))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    completion(.failure(SearchError.unexpectedResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(SearchError.invalidResponse))
                    return
                }
                
                do {
                    let suggestions = try JSONDecoder().decode([SearchSuggestion].self, from: data)
                    completion(.success(suggestions))
                } catch {
                    print("❌ Error decoding search suggestions: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Search History
    
    func saveSearch(query: String, location: Location? = nil, completion: @escaping (Result<SearchHistory, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/search/save") else {
            completion(.failure(SearchError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthorizationHeader()
        
        var requestBody: [String: Any] = [
            "query": query
        ]
        
        if let location = location {
            requestBody["location"] = location.toDictionary()
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(SearchError.invalidResponse))
                    return
                }
                
                guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                    completion(.failure(SearchError.unexpectedResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(SearchError.invalidResponse))
                    return
                }
                
                do {
                    let searchHistory = try JSONDecoder().decode(SearchHistory.self, from: data)
                    completion(.success(searchHistory))
                } catch {
                    print("❌ Error decoding search history: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func getRecentSearches(completion: @escaping (Result<[SearchHistory], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/search/recent") else {
            completion(.failure(SearchError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthorizationHeader()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(SearchError.invalidResponse))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    completion(.failure(SearchError.unexpectedResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(SearchError.invalidResponse))
                    return
                }
                
                do {
                    let searches = try JSONDecoder().decode([SearchHistory].self, from: data)
                    completion(.success(searches))
                } catch {
                    print("❌ Error decoding recent searches: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func getPopularSearches(completion: @escaping (Result<[PopularSearch], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/search/popular") else {
            completion(.failure(SearchError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(SearchError.invalidResponse))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    completion(.failure(SearchError.unexpectedResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(SearchError.invalidResponse))
                    return
                }
                
                do {
                    let searches = try JSONDecoder().decode([PopularSearch].self, from: data)
                    completion(.success(searches))
                } catch {
                    print("❌ Error decoding popular searches: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func clearSearchHistory(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/search/clear-history") else {
            completion(.failure(SearchError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.addAuthorizationHeader()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(SearchError.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                    completion(.success(()))
                } else {
                    completion(.failure(SearchError.unexpectedResponse))
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    

}

// MARK: - Search Models

struct SearchSuggestion: Identifiable, Codable {
    let id: String
    let query: String
    let type: BackendSearchType
    let count: Int
}

enum BackendSearchType: String, Codable {
    case location = "LOCATION"
    case carMake = "CAR_MAKE"
    case carModel = "CAR_MODEL"
    case carMakeModel = "CAR_MAKE_MODEL"
}

struct SearchHistory: Identifiable, Codable {
    let id: String
    let query: String
    let location: Location?
    let userId: String
    let createdAt: Date
    let resultCount: Int
}

struct PopularSearch: Codable {
    let query: String
    let count: Int
}

// MARK: - Search Errors
// SearchError is defined in SearchModels.swift

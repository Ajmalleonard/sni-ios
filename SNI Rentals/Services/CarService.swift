import Foundation
import Combine

class CarService {
    private let baseURL = "https://api.snicolt.com"
    
    // MARK: - Fetch Cars
    
    /// Async method to fetch all cars for state management
    func fetchAllCars() async throws -> [Car] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchCars { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func fetchCars(params: CarFilterParams = CarFilterParams(), completion: @escaping @Sendable (Result<[Car], Error>) -> Void) {
        var urlComponents = URLComponents(string: baseURL + "/cars")!
        
        // Add query parameters
        var queryItems: [URLQueryItem] = []
        
        if let vehicleType = params.vehicleType {
            queryItems.append(URLQueryItem(name: "vehicleType", value: vehicleType.rawValue))
        }
        
        if let status = params.status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        
        if let minPrice = params.minPrice {
            queryItems.append(URLQueryItem(name: "minPrice", value: String(minPrice)))
        }
        
        if let maxPrice = params.maxPrice {
            queryItems.append(URLQueryItem(name: "maxPrice", value: String(maxPrice)))
        }
        
        if let seatCount = params.seatCount {
            queryItems.append(URLQueryItem(name: "seatCount", value: String(seatCount)))
        }
        
        if let transmissionType = params.transmissionType {
            queryItems.append(URLQueryItem(name: "transmissionType", value: transmissionType))
        }
        
        if let fuelType = params.fuelType {
            queryItems.append(URLQueryItem(name: "fuelType", value: fuelType))
        }
        
        if let skip = params.skip {
            queryItems.append(URLQueryItem(name: "skip", value: String(skip)))
        }
        
        if let take = params.take {
            queryItems.append(URLQueryItem(name: "take", value: String(take)))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            completion(.failure(CarError.invalidURL))
            return
        }
        
        performRequest(url: url, method: "GET", completion: completion)
    }
    
    // MARK: - Fetch Car by ID
    func fetchCarById(id: String, completion: @escaping @Sendable (Result<Car, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/cars/\(id)") else {
            completion(.failure(CarError.invalidURL))
            return
        }
        
        performRequest(url: url, method: "GET", completion: completion)
    }
    
    // MARK: - Fetch Cars by Vehicle Type
    func fetchCarsByVehicleType(type: VehicleType, completion: @escaping @Sendable (Result<[Car], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/cars/type/\(type.rawValue)") else {
            completion(.failure(CarError.invalidURL))
            return
        }
        
        performRequest(url: url, method: "GET", completion: completion)
    }
    
    // MARK: - Fetch Cars by Status
    func fetchCarsByStatus(status: CarStatus, completion: @escaping @Sendable (Result<[Car], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/cars/status/\(status.rawValue)") else {
            completion(.failure(CarError.invalidURL))
            return
        }
        
        performRequest(url: url, method: "GET", completion: completion)
    }
    
    // MARK: - Fetch Cars by Owner
    func fetchCarsByOwner(ownerId: String, completion: @escaping @Sendable (Result<[Car], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/cars/owner/\(ownerId)") else {
            completion(.failure(CarError.invalidURL))
            return
        }
        
        performRequest(url: url, method: "GET", completion: completion)
    }
    
    // MARK: - Create Rental
    func createRental(rentalData: CreateRentalRequest, completion: @escaping @Sendable (Result<Rental, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/rentals") else {
            completion(.failure(CarError.invalidURL))
            return
        }
        
        performRequest(url: url, method: "POST", body: rentalData, completion: completion)
    }
    
    // MARK: - Calculate Rental Price
    func calculateRentalPrice(data: PriceCalculationData, completion: @escaping @Sendable (Result<PriceCalculation, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/rentals/calculate-price") else {
            completion(.failure(CarError.invalidURL))
            return
        }
        
        performRequest(url: url, method: "POST", body: data, completion: completion)
    }
    
    // MARK: - Fetch User Rentals
    func fetchUserRentals(userId: String, completion: @escaping @Sendable (Result<[Rental], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/rentals/user/\(userId)") else {
            completion(.failure(CarError.invalidURL))
            return
        }
        
        performRequest(url: url, method: "GET", completion: completion)
    }
    
    // MARK: - Fetch Rental by ID
    func fetchRentalById(id: String, completion: @escaping @Sendable (Result<Rental, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/rentals/\(id)") else {
            completion(.failure(CarError.invalidURL))
            return
        }
        
        performRequest(url: url, method: "GET", completion: completion)
    }
    
    // MARK: - Private Helpers
    private func performRequest<T: Encodable & Sendable, U: Decodable & Sendable>(
        url: URL,
        method: String,
        body: T? = nil,
        completion: @escaping @Sendable (Result<U, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if available
        request.addAuthorizationHeader()
        
        if let body = body {
            do {
                let requestData = try JSONEncoder().encode(body)
                request.httpBody = requestData
                
                // Print detailed request information
                printRequestDetails(url: url, method: method, headers: request.allHTTPHeaderFields, body: requestData)
                
            } catch {
                print("❌ ENCODING ERROR: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Print detailed response information
            self?.printResponseDetails(url: url, data: data, response: response, error: error)
            
            if let error = error {
                completion(.failure(CarError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(CarError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedResponse = try decoder.decode(U.self, from: data)
                
                // Print successful decode information
                let typeName = String(describing: U.self)
                self?.printSuccessfulDecode(type: typeName, response: decodedResponse)
                
                completion(.success(decodedResponse))
            } catch {
                // Handle backend error decoding
                self?.handleBackendError(data: data, originalError: error, completion: completion)
            }
        }
        task.resume()
    }
    
    private func performRequest<U: Decodable & Sendable>(
        url: URL,
        method: String,
        completion: @escaping @Sendable (Result<U, Error>) -> Void
    ) {
        performRequest(url: url, method: method, body: nil as EmptyRequest?, completion: completion)
    }
    
    private func handleBackendError<U: Sendable>(
        data: Data,
        originalError: Error,
        completion: @escaping @Sendable (Result<U, Error>) -> Void
    ) {
        Task.detached {
            do {
                let decoder = JSONDecoder()
                let backendError = try decoder.decode(BackendError.self, from: data)
                await MainActor.run {
                    print("🔴 BACKEND ERROR DECODED: \(backendError)")
                }
                completion(.failure(CarError.backend(backendError.message)))
            } catch {
                await MainActor.run {
                    print("❌ DECODE ERROR: \(originalError.localizedDescription)")
                }
                completion(.failure(originalError))
            }
        }
    }
    
    // MARK: - Detailed Logging Methods
    private func printRequestDetails(url: URL, method: String, headers: [String: String]?, body: Data) {
        print("\n" + String(repeating: "=", count: 60))
        print("🚗 CAR API REQUEST")
        print(String(repeating: "=", count: 60))
        print("📍 URL: \(url.absoluteString)")
        print("🔗 Method: \(method)")
        print("📋 Headers:")
        if let headers = headers {
            for (key, value) in headers {
                print("   \(key): \(value)")
            }
        } else {
            print("   None")
        }
        print("📦 Request Body:")
        if let bodyString = String(data: body, encoding: .utf8) {
            if let jsonObject = try? JSONSerialization.jsonObject(with: body),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print(prettyString)
            } else {
                print(bodyString)
            }
        } else {
            print("   Unable to decode body as UTF-8")
        }
        print(String(repeating: "=", count: 60))
    }
    
    private func printResponseDetails(url: URL, data: Data?, response: URLResponse?, error: Error?) {
        print("\n" + String(repeating: "=", count: 60))
        print("🚗 CAR API RESPONSE")
        print(String(repeating: "=", count: 60))
        print("📍 URL: \(url.lastPathComponent)")
        
        if let httpResponse = response as? HTTPURLResponse {
            let statusEmoji = (200...299).contains(httpResponse.statusCode) ? "✅" : "❌"
            print("📊 Status Code: \(statusEmoji) \(httpResponse.statusCode)")
            print("📋 Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("   \(key): \(value)")
            }
        }
        
        if let error = error {
            print("❌ Network Error: \(error.localizedDescription)")
        }
        
        print("📦 Response Body:")
        if let data = data {
            print("   Size: \(data.count) bytes")
            if let responseString = String(data: data, encoding: .utf8) {
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    print(prettyString)
                } else {
                    print(responseString)
                }
            } else {
                print("   Unable to decode response as UTF-8")
            }
        } else {
            print("   No data received")
        }
        print(String(repeating: "=", count: 60))
    }
    
    private func printSuccessfulDecode<T: Sendable>(type: String, response: T) {
        print("\n" + String(repeating: "=", count: 60))
        print("✅ SUCCESSFUL CAR API DECODE")
        print(String(repeating: "=", count: 60))
        print("📝 Type: \(type)")
        print("🎯 Decoded Object:")
        
        // Try to print the object in a readable format
        if let codableResponse = response as? Codable {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(codableResponse)
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString)
                } else {
                    print("   \(response)")
                }
            } catch {
                print("   \(response)")
            }
        } else {
            print("   \(response)")
        }
        print(String(repeating: "=", count: 60) + "\n")
    }
}

// MARK: - Car Error Types
enum CarError: Error, LocalizedError, Sendable {
    case invalidURL
    case noData
    case backend(String)
    case networkError(Error)
    case carNotFound
    case rentalCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid car service URL."
        case .noData:
            return "No data received from car service."
        case .backend(let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        case .carNotFound:
            return "Car not found."
        case .rentalCreationFailed:
            return "Failed to create rental."
        }
    }
}

// MARK: - Helper Types
private struct EmptyRequest: Codable, Sendable {}
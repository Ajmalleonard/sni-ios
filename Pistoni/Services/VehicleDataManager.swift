import Foundation
import Combine

@MainActor
class VehicleDataManager: ObservableObject {
    static let shared = VehicleDataManager()
    
    @Published var allVehicles: [Car] = []
    @Published var isLoading: Bool = false
    @Published var lastRefreshTime: Date?
    @Published var errorMessage: String?
    
    private var refreshTimer: Timer?
    private let carService: CarService?
    private let refreshInterval: TimeInterval = 60 // 1 minute
    
    // Flag to indicate if this instance is being used in a preview
    var isPreview: Bool = false
    
    private init() {
        // Check if running in preview mode
        let isPreviewMode = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreviewMode {
            self.isPreview = true
            self.carService = nil
            setupMockVehicles()
        } else {
            self.carService = CarService()
            startPeriodicRefresh()
        }
    }
    
    deinit {
        Task { @MainActor in
            stopPeriodicRefresh()
        }
    }
    
    // MARK: - Public Methods
    
    /// Initial data fetch - called when app starts
    func initialFetch() async {
        guard allVehicles.isEmpty else { return }
        await fetchVehicles()
    }
    
    /// Manual refresh - called by user action
    func manualRefresh() async {
        await fetchVehicles()
    }
    
    /// Get all vehicles
    func getAllVehicles() -> [Car] {
        return allVehicles
    }
    
    /// Get vehicles filtered by type
    func getVehiclesByType(_ type: VehicleType) -> [Car] {
        return allVehicles.filter { $0.vehicleType == type }
    }
    
    /// Get available vehicles only
    func getAvailableVehicles() -> [Car] {
        return allVehicles.filter { $0.isAvailable }
    }
    
    /// Get available vehicles by type
    func getAvailableVehiclesByType(_ type: VehicleType) -> [Car] {
        return allVehicles.filter { $0.vehicleType == type && $0.isAvailable }
    }
    
    /// Search vehicles by make, model, or features
    func searchVehicles(_ query: String) -> [Car] {
        guard !query.isEmpty else { return allVehicles }
        
        let lowercaseQuery = query.lowercased()
        return allVehicles.filter { car in
            car.make.lowercased().contains(lowercaseQuery) ||
            car.model.lowercased().contains(lowercaseQuery) ||
            car.features.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchVehicles() async {
        // Skip network calls in preview mode
        if isPreview {
            return
        }
        
        guard let carService = carService else { return }
        
        isLoading = true
        
        do {
            let vehicles = try await carService.fetchAllCars()
            
            // Use fetched data if available, otherwise fallback to sample data
            if !vehicles.isEmpty {
                allVehicles = vehicles
            } else {
                allVehicles = createSampleVehicles()
            }
            
            lastRefreshTime = Date()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to fetch vehicles: \(error.localizedDescription)"
            
            // Fallback to sample data on error
            allVehicles = createSampleVehicles()
        }
        
        isLoading = false
    }
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchVehicles()
            }
        }
    }
    
    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Cache Management
    
    /// Check if data is stale (older than refresh interval)
    var isDataStale: Bool {
        guard let lastRefresh = lastRefreshTime else { return true }
        return Date().timeIntervalSince(lastRefresh) > refreshInterval
    }
    
    /// Force refresh if data is stale
    func refreshIfStale() async {
        if isDataStale {
            await fetchVehicles()
        }
    }
    
    private func setupMockVehicles() {
        allVehicles = createSampleVehicles()
        lastRefreshTime = Date()
    }
    
    /// Create sample vehicles for fallback
    private func createSampleVehicles() -> [Car] {
        return [
            Car(
                id: "sample-1",
                make: "Tesla",
                model: "Model S",
                year: 2024,
                color: "Red",
                licensePlate: "TESLA1",
                price: 150.0,
                images: ["https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800"],
                description: "Electric luxury sedan with autopilot",
                status: .approved,
                features: ["Electric", "Autopilot", "Premium Sound", "Unlimited Miles"],
                seatCount: 5,
                transmissionType: "Automatic",
                fuelType: "Electric",
                vehicleType: .suv,
                createdAt: Date(),
                updatedAt: Date(),
                ownerId: "owner1"
            ),
            Car(
                id: "sample-2",
                make: "BMW",
                model: "X5",
                year: 2023,
                color: "Blue",
                licensePlate: "BMW123",
                price: 120.0,
                images: ["https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800"],
                description: "Luxury SUV with all-wheel drive",
                status: .pendingReview,
                features: ["All-Wheel Drive", "Premium Package", "Heated Seats"],
                seatCount: 7,
                transmissionType: "Automatic",
                fuelType: "Petrol",
                vehicleType: .suv,
                createdAt: Date(),
                updatedAt: Date(),
                ownerId: "owner2"
            ),
            Car(
                id: "sample-3",
                make: "Toyota",
                model: "Coaster",
                year: 2022,
                color: "White",
                licensePlate: "COAST1",
                price: 200.0,
                images: ["https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800"],
                description: "Spacious coaster bus for group travel",
                status: .approved,
                features: ["Air Conditioning", "GPS Navigation", "25 Seats"],
                seatCount: 25,
                transmissionType: "Manual",
                fuelType: "Diesel",
                vehicleType: .coaster,
                createdAt: Date(),
                updatedAt: Date(),
                ownerId: "owner3"
            ),
            Car(
                id: "sample-4",
                make: "Mercedes",
                model: "Sprinter",
                year: 2023,
                color: "Silver",
                licensePlate: "LONG01",
                price: 180.0,
                images: ["https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800"],
                description: "Long vehicle perfect for cargo and passengers",
                status: .pendingReview,
                features: ["Large Cargo Space", "Comfortable Seating", "Bluetooth"],
                seatCount: 12,
                transmissionType: "Automatic",
                fuelType: "Diesel",
                vehicleType: .longVehicle,
                createdAt: Date(),
                updatedAt: Date(),
                ownerId: "owner4"
            )
        ]
    }
    
    /// Get cache status info
    var cacheInfo: String {
        guard let lastRefresh = lastRefreshTime else {
            return "No data cached"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        
        return "Last updated: \(formatter.string(from: lastRefresh))"
    }
}

// MARK: - Vehicle Type Extensions
extension VehicleDataManager {
    /// Get trending vehicles (based on rental count)
    func getTrendingVehicles(limit: Int = 10) -> [Car] {
        return allVehicles
            .filter { $0.isAvailable }
            .sorted { ($0.rentals?.count ?? 0) > ($1.rentals?.count ?? 0) }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get popular vehicles (based on rating)
    func getPopularVehicles(limit: Int = 10) -> [Car] {
        return allVehicles
            .filter { $0.isAvailable && $0.averageRating > 0 }
            .sorted { $0.averageRating > $1.averageRating }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get vehicles by price range
    func getVehiclesByPriceRange(min: Double, max: Double) -> [Car] {
        return allVehicles.filter { car in
            car.price >= min && car.price <= max
        }
    }
}
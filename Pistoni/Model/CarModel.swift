import Combine
import Foundation

// MARK: - Car State Models
struct CarState {
    var cars: [Car] = []
    var selectedCar: Car?
    var currentFilters: CarFilterParams = CarFilterParams()
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?
}

struct FilterState {
    var vehicleType: VehicleType?
    var status: CarStatus?
    var minPrice: Double?
    var maxPrice: Double?
    var seatCount: Int?
    var transmissionType: String?
    var fuelType: String?
    var location: Location?
    
    func toCarFilterParams() -> CarFilterParams {
        return CarFilterParams(
            vehicleType: vehicleType,
            status: status,
            minPrice: minPrice,
            maxPrice: maxPrice,
            seatCount: seatCount,
            transmissionType: transmissionType,
            fuelType: fuelType,
            location: location
        )
    }
    
    func reset() -> FilterState {
        return FilterState()
    }
}

struct RentalState {
    var userRentalIds: [String] = []
    var selectedRentalId: String?
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?
    
    // Computed properties
    var userRentals: [Rental] { [] } // Will be populated separately
    var selectedRental: Rental? { nil } // Will be populated separately
}

// MARK: - Car Model
@MainActor
class CarModel: ObservableObject {
    // Published state properties
    @Published var carState = CarState()
    @Published var filterState = FilterState()
    @Published var rentalState = RentalState()
    
    private let carService = CarService()
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for backward compatibility
    var cars: [Car] { carState.cars }
    var selectedCar: Car? { carState.selectedCar }
    var isLoading: Bool { carState.isLoading }
    var errorMessage: String? { carState.errorMessage }
    var successMessage: String? { carState.successMessage }
    
    init() {
        setupMessageAutoClearing()
    }
    
    // MARK: - Car Operations
    func fetchCars(params: CarFilterParams? = nil) {
        performCarOperation { [weak self] in
            await self?.handleFetchCars(params: params ?? self?.filterState.toCarFilterParams() ?? CarFilterParams())
        }
    }
    
    func fetchCarsByVehicleType(_ type: VehicleType) {
        performCarOperation { [weak self] in
            await self?.handleFetchCarsByVehicleType(type)
        }
    }
    
    func fetchCarsByStatus(_ status: CarStatus) {
        performCarOperation { [weak self] in
            await self?.handleFetchCarsByStatus(status)
        }
    }
    
    func fetchCarById(_ id: String) {
        performCarOperation { [weak self] in
            await self?.handleFetchCarById(id)
        }
    }
    
    func selectCar(_ car: Car) {
        carState.selectedCar = car
    }
    
    // MARK: - Filter Operations
    func updateFilter(_ filter: FilterState) {
        filterState = filter
        fetchCars()
    }
    
    func resetFilters() {
        filterState = filterState.reset()
        fetchCars()
    }
    
    func applyFilters() {
        fetchCars()
    }
    
    // MARK: - Rental Operations
    func createRental(rentalData: CreateRentalRequest) {
        performRentalOperation { [weak self] in
            await self?.handleCreateRental(rentalData)
        }
    }
    
    func fetchUserRentals(userId: String) {
        performRentalOperation { [weak self] in
            await self?.handleFetchUserRentals(userId)
        }
    }
    
    func calculateRentalPrice(data: PriceCalculationData) async -> PriceCalculation? {
        return await withCheckedContinuation { continuation in
            carService.calculateRentalPrice(data: data) { result in
                switch result {
                case .success(let priceCalculation):
                    continuation.resume(returning: priceCalculation)
                case .failure(let error):
                    print("❌ Price calculation failed: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - Private Async Handlers
    private func handleFetchCars(params: CarFilterParams) async {
        await withCheckedContinuation { continuation in
            carService.fetchCars(params: params) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let cars):
                        self.carState.cars = cars
                        self.carState.errorMessage = nil
                        self.carState.successMessage = "Found \(cars.count) cars"
                        
                    case .failure(let error):
                        self.carState.errorMessage = self.parseErrorMessage(error)
                        self.carState.successMessage = nil
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleFetchCarsByVehicleType(_ type: VehicleType) async {
        await withCheckedContinuation { continuation in
            carService.fetchCarsByVehicleType(type: type) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let cars):
                        self.carState.cars = cars
                        self.carState.errorMessage = nil
                        self.carState.successMessage = "Found \(cars.count) \(type.displayName)s"
                        
                    case .failure(let error):
                        self.carState.errorMessage = self.parseErrorMessage(error)
                        self.carState.successMessage = nil
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleFetchCarsByStatus(_ status: CarStatus) async {
        await withCheckedContinuation { continuation in
            carService.fetchCarsByStatus(status: status) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let cars):
                        self.carState.cars = cars
                        self.carState.errorMessage = nil
                        self.carState.successMessage = "Found \(cars.count) \(status.displayName.lowercased()) cars"
                        
                    case .failure(let error):
                        self.carState.errorMessage = self.parseErrorMessage(error)
                        self.carState.successMessage = nil
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleFetchCarById(_ id: String) async {
        await withCheckedContinuation { continuation in
            carService.fetchCarById(id: id) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let car):
                        self.carState.selectedCar = car
                        self.carState.errorMessage = nil
                        self.carState.successMessage = "Car details loaded"
                        
                    case .failure(let error):
                        self.carState.errorMessage = self.parseErrorMessage(error)
                        self.carState.successMessage = nil
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleCreateRental(_ rentalData: CreateRentalRequest) async {
        await withCheckedContinuation { continuation in
            carService.createRental(rentalData: rentalData) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let rental):
                        self.rentalState.userRentalIds.append(rental.id)
                        self.rentalState.errorMessage = nil
                        self.rentalState.successMessage = "Rental created successfully"
                        
                    case .failure(let error):
                        self.rentalState.errorMessage = self.parseErrorMessage(error)
                        self.rentalState.successMessage = nil
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleFetchUserRentals(_ userId: String) async {
        await withCheckedContinuation { continuation in
            carService.fetchUserRentals(userId: userId) { result in
                Task { @MainActor in
                    switch result {
                    case .success(let rentals):
                        self.rentalState.userRentalIds = rentals.map { $0.id }
                        self.rentalState.errorMessage = nil
                        self.rentalState.successMessage = "Found \(rentals.count) rentals"
                        
                    case .failure(let error):
                        self.rentalState.errorMessage = self.parseErrorMessage(error)
                        self.rentalState.successMessage = nil
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    private func performCarOperation(_ operation: @escaping () async -> Void) {
        guard !carState.isLoading else { return }
        
        carState.errorMessage = nil
        carState.successMessage = nil
        carState.isLoading = true
        
        Task {
            await operation()
            await MainActor.run {
                carState.isLoading = false
            }
        }
    }
    
    private func performRentalOperation(_ operation: @escaping () async -> Void) {
        guard !rentalState.isLoading else { return }
        
        rentalState.errorMessage = nil
        rentalState.successMessage = nil
        rentalState.isLoading = true
        
        Task {
            await operation()
            await MainActor.run {
                rentalState.isLoading = false
            }
        }
    }
    
    private func setupMessageAutoClearing() {
        // Auto-clear car messages after 5 seconds
        $carState
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] carState in
                if carState.errorMessage != nil || carState.successMessage != nil {
                    self?.carState.errorMessage = nil
                    self?.carState.successMessage = nil
                }
            }
            .store(in: &cancellables)
        
        // Auto-clear rental messages after 5 seconds
        $rentalState
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] rentalState in
                if rentalState.errorMessage != nil || rentalState.successMessage != nil {
                    self?.rentalState.errorMessage = nil
                    self?.rentalState.successMessage = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func parseErrorMessage(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection available"
            case .timedOut:
                return "Request timed out. Please try again"
            case .cannotFindHost:
                return "Server not found. Please check your connection"
            default:
                return "Network error: \(urlError.localizedDescription)"
            }
        }
        
        if let errorDescription = error.localizedDescription.isEmpty ? nil : error.localizedDescription {
            return errorDescription
        }
        
        return "An unexpected error occurred. Please try again"
    }
    
    deinit {
        cancellables.removeAll()
    }
}



import Foundation

// MARK: - Vehicle Type Enum
enum VehicleType: String, Codable, CaseIterable, Sendable {
    case suv = "SUV"
    case coaster = "COASTER"
    case longVehicle = "LONG_VEHICLE"
    
    var displayName: String {
        switch self {
        case .suv:
            return "SUV"
        case .coaster:
            return "Coaster"
        case .longVehicle:
            return "Long Vehicle"
        }
    }
    
    var icon: String {
        switch self {
        case .suv:
            return "car.fill"
        case .coaster:
            return "bus.fill"
        case .longVehicle:
            return "truck.box.fill"
        }
    }
}

// MARK: - Car Status Enum
enum CarStatus: String, Codable, Sendable {
    case pendingReview = "PENDING_REVIEW"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case maintenance = "MAINTENANCE"
    case available = "AVAILABLE"
    case rented = "RENTED"
    
    var displayName: String {
        switch self {
        case .pendingReview:
            return "Pending Review"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .maintenance:
            return "Maintenance"
        case .available:
            return "Available"
        case .rented:
            return "Rented"
        }
    }
    
    var color: String {
        switch self {
        case .pendingReview:
            return "orange"
        case .approved:
            return "green"
        case .rejected:
            return "red"
        case .maintenance:
            return "yellow"
        case .available:
            return "blue"
        case .rented:
            return "gray"
        }
    }
}

// MARK: - Location Model
struct Location: Identifiable, Codable, Sendable {
    let id: String
    let latitude: Double
    let longitude: Double
    let address: String
    let city: String
    let state: String?
    let country: String
    let zipCode: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, address, city, state, country, zipCode, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        address = try container.decode(String.self, forKey: .address)
        city = try container.decode(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        country = try container.decode(String.self, forKey: .country)
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode)
        
        // Handle date parsing with multiple formats
        createdAt = try Self.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDate(from: container, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(address, forKey: .address)
        try container.encode(city, forKey: .city)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encode(country, forKey: .country)
        try container.encodeIfPresent(zipCode, forKey: .zipCode)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        // Try different date formats
        if let dateString = try? container.decode(String.self, forKey: key) {
            // Try ISO8601 format first
            let iso8601Formatter = ISO8601DateFormatter()
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Try alternative formats
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd HH:mm:ss"
            ]
            
            for formatString in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = formatString
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Date string does not match expected formats: \(dateString)")
        } else {
            // Try decoding as timestamp
            let timestamp = try container.decode(Double.self, forKey: key)
            return Date(timeIntervalSince1970: timestamp)
        }
    }
    
    var fullAddress: String {
        var components = [address, city]
        if let state = state {
            components.append(state)
        }
        components.append(country)
        if let zipCode = zipCode {
            components.append(zipCode)
        }
        return components.joined(separator: ", ")
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "latitude": latitude,
            "longitude": longitude,
            "address": address,
            "city": city,
            "state": state as Any,
            "country": country,
            "zipCode": zipCode as Any
        ]
    }
}

// MARK: - Review Model
struct Review: Identifiable, Codable, Sendable {
    let id: String
    let rating: Int // 1-5 stars
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Relations
    let authorId: String
    let author: User?
    let targetId: String?
    let target: User?
    let carId: String?
    let rentalId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, rating, comment, createdAt, updatedAt
        case authorId, author, targetId, target, carId, rentalId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        rating = try container.decode(Int.self, forKey: .rating)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        authorId = try container.decode(String.self, forKey: .authorId)
        author = try container.decodeIfPresent(User.self, forKey: .author)
        targetId = try container.decodeIfPresent(String.self, forKey: .targetId)
        target = try container.decodeIfPresent(User.self, forKey: .target)
        carId = try container.decodeIfPresent(String.self, forKey: .carId)
        rentalId = try container.decodeIfPresent(String.self, forKey: .rentalId)
        
        // Handle date parsing with multiple formats
        createdAt = try Self.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDate(from: container, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(authorId, forKey: .authorId)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(targetId, forKey: .targetId)
        try container.encodeIfPresent(target, forKey: .target)
        try container.encodeIfPresent(carId, forKey: .carId)
        try container.encodeIfPresent(rentalId, forKey: .rentalId)
    }
    
    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        // Try different date formats
        if let dateString = try? container.decode(String.self, forKey: key) {
            // Try ISO8601 format first
            let iso8601Formatter = ISO8601DateFormatter()
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Try alternative formats
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd HH:mm:ss"
            ]
            
            for formatString in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = formatString
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Date string does not match expected formats: \(dateString)")
        } else {
            // Try decoding as timestamp
            let timestamp = try container.decode(Double.self, forKey: key)
            return Date(timeIntervalSince1970: timestamp)
        } 
    }
    
    // Removed invalid computed properties block
}

// MARK: - Rental Model
nonisolated struct Rental: Identifiable, Codable, Sendable {
    let id: String
    let startDate: Date
    let endDate: Date
    let totalPrice: Double
    let status: RentalStatus
    let distanceKm: Double?
    let createdAt: Date
    let updatedAt: Date
    
    // Relations
    let userId: String
    let user: User?
    let carId: String
    let pickupLocationId: String
    let pickupLocation: Location?
    let dropoffLocationId: String
    let dropoffLocation: Location?
    let reviewId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, startDate, endDate, totalPrice, status, distanceKm, createdAt, updatedAt
        case userId, user, carId, pickupLocationId, pickupLocation, dropoffLocationId, dropoffLocation, reviewId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        totalPrice = try container.decode(Double.self, forKey: .totalPrice)
        status = try container.decode(RentalStatus.self, forKey: .status)
        distanceKm = try container.decodeIfPresent(Double.self, forKey: .distanceKm)
        userId = try container.decode(String.self, forKey: .userId)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        carId = try container.decode(String.self, forKey: .carId)
        pickupLocationId = try container.decode(String.self, forKey: .pickupLocationId)
        pickupLocation = try container.decodeIfPresent(Location.self, forKey: .pickupLocation)
        dropoffLocationId = try container.decode(String.self, forKey: .dropoffLocationId)
        dropoffLocation = try container.decodeIfPresent(Location.self, forKey: .dropoffLocation)
        reviewId = try container.decodeIfPresent(String.self, forKey: .reviewId)
        
        // Handle date parsing with multiple formats
        startDate = try Self.decodeDate(from: container, forKey: .startDate)
        endDate = try Self.decodeDate(from: container, forKey: .endDate)
        createdAt = try Self.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDate(from: container, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(totalPrice, forKey: .totalPrice)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(distanceKm, forKey: .distanceKm)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encode(carId, forKey: .carId)
        try container.encode(pickupLocationId, forKey: .pickupLocationId)
        try container.encodeIfPresent(pickupLocation, forKey: .pickupLocation)
        try container.encodeIfPresent(dropoffLocationId, forKey: .dropoffLocationId)
        try container.encodeIfPresent(dropoffLocation, forKey: .dropoffLocation)
        try container.encodeIfPresent(reviewId, forKey: .reviewId)
    }
    
    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        // Try different date formats
        if let dateString = try? container.decode(String.self, forKey: key) {
            // Try ISO8601 format first
            let iso8601Formatter = ISO8601DateFormatter()
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Try alternative formats
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd HH:mm:ss"
            ]
            
            for formatString in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = formatString
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Date string does not match expected formats: \(dateString)")
        } else {
            // Try decoding as timestamp
            let timestamp = try container.decode(Double.self, forKey: key)
            return Date(timeIntervalSince1970: timestamp)
        }
    }
    
    // Computed properties to avoid circular references
    var car: Car? { nil } // Will be populated separately if needed
    var review: Review? { nil } // Will be populated separately if needed
    
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

// MARK: - Rental Status Enum
enum RentalStatus: String, Codable, Sendable {
    case pending = "PENDING"
    case confirmed = "CONFIRMED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .confirmed:
            return "Confirmed"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "orange"
        case .confirmed:
            return "blue"
        case .inProgress:
            return "green"
        case .completed:
            return "gray"
        case .cancelled:
            return "red"
        }
    }
}

// MARK: - Updated Car Model (replaces CarDisplay)
nonisolated struct Car: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let make: String
    let model: String
    let year: Int
    let color: String
    let licensePlate: String
    let price: Double // Price per day
    let images: [String]
    let description: String?
    let status: CarStatus
    let features: [String]
    let seatCount: Int
    let transmissionType: String
    let fuelType: String
    let vehicleType: VehicleType
    let createdAt: Date
    let updatedAt: Date
    
    // Relations
    let ownerId: String
    let owner: User?
    let location: Location?
    let reviewIds: [String]?
    let rentalIds: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, make, model, year, color, licensePlate, price, images, description
        case status, features, seatCount, transmissionType, fuelType, vehicleType
        case createdAt, updatedAt, ownerId, owner, location, reviewIds, rentalIds
    }
    
    init(id: String, make: String, model: String, year: Int, color: String, licensePlate: String,
         price: Double, images: [String], description: String?, status: CarStatus, features: [String],
         seatCount: Int, transmissionType: String, fuelType: String, vehicleType: VehicleType,
         createdAt: Date, updatedAt: Date, ownerId: String, owner: User? = nil, location: Location? = nil,
         reviewIds: [String]? = nil, rentalIds: [String]? = nil) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.color = color
        self.licensePlate = licensePlate
        self.price = price
        self.images = images
        self.description = description
        self.status = status
        self.features = features
        self.seatCount = seatCount
        self.transmissionType = transmissionType
        self.fuelType = fuelType
        self.vehicleType = vehicleType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ownerId = ownerId
        self.owner = owner
        self.location = location
        self.reviewIds = reviewIds
        self.rentalIds = rentalIds
    }

    // Hashable by id
    static func == (lhs: Car, rhs: Car) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        make = try container.decode(String.self, forKey: .make)
        model = try container.decode(String.self, forKey: .model)
        year = try container.decode(Int.self, forKey: .year)
        color = try container.decode(String.self, forKey: .color)
        licensePlate = try container.decode(String.self, forKey: .licensePlate)
        price = try container.decode(Double.self, forKey: .price)
        images = try container.decode([String].self, forKey: .images)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decode(CarStatus.self, forKey: .status)
        features = try container.decode([String].self, forKey: .features)
        seatCount = try container.decode(Int.self, forKey: .seatCount)
        transmissionType = try container.decode(String.self, forKey: .transmissionType)
        fuelType = try container.decode(String.self, forKey: .fuelType)
        vehicleType = try container.decode(VehicleType.self, forKey: .vehicleType)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        owner = try container.decodeIfPresent(User.self, forKey: .owner)
        location = try container.decodeIfPresent(Location.self, forKey: .location)
        reviewIds = try container.decodeIfPresent([String].self, forKey: .reviewIds)
        rentalIds = try container.decodeIfPresent([String].self, forKey: .rentalIds)
        
        // Handle date parsing with multiple formats
        createdAt = try Self.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDate(from: container, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(make, forKey: .make)
        try container.encode(model, forKey: .model)
        try container.encode(year, forKey: .year)
        try container.encode(color, forKey: .color)
        try container.encode(licensePlate, forKey: .licensePlate)
        try container.encode(price, forKey: .price)
        try container.encode(images, forKey: .images)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(status, forKey: .status)
        try container.encode(features, forKey: .features)
        try container.encode(seatCount, forKey: .seatCount)
        try container.encode(transmissionType, forKey: .transmissionType)
        try container.encode(fuelType, forKey: .fuelType)
        try container.encode(vehicleType, forKey: .vehicleType)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encodeIfPresent(owner, forKey: .owner)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(reviewIds, forKey: .reviewIds)
        try container.encodeIfPresent(rentalIds, forKey: .rentalIds)
    }
    
    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        if let dateString = try? container.decode(String.self, forKey: key) {
            let iso8601Formatter = ISO8601DateFormatter()
            if let date = iso8601Formatter.date(from: dateString) { return date }
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd HH:mm:ss"
            ]
            for formatString in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = formatString
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = formatter.date(from: dateString) { return date }
            }
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Date string does not match expected formats: \(dateString)")
        } else {
            let timestamp = try container.decode(Double.self, forKey: key)
            return Date(timeIntervalSince1970: timestamp)
        }
    }
    
    var reviews: [Review]? { nil }
    var rentals: [Rental]? { nil }
    
    var displayName: String { "\(make) \(model)" }
    var fullDisplayName: String { "\(make) \(model) (\(year))" }
    var primaryImage: String? { images.first }
    var averageRating: Double {
        guard let reviews = reviews, !reviews.isEmpty else { return 0 }
        let total = reviews.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(reviews.count)
    }
    var reviewCount: Int { reviews?.count ?? 0 }
    var isAvailable: Bool { status == .available || status == .approved || status == .pendingReview }
    var priceFormatted: String { String(format: "$%.0f", price) }
    var pricePerDayFormatted: String { "\(priceFormatted)/day" }
}

// MARK: - Car Filter Parameters
struct CarFilterParams: Codable, Sendable {
    var vehicleType: VehicleType?
    var status: CarStatus?
    var minPrice: Double?
    var maxPrice: Double?
    var seatCount: Int?
    var transmissionType: String?
    var fuelType: String?
    var location: Location?
    var skip: Int?
    var take: Int?
    
    init() {}
    
    init(vehicleType: VehicleType? = nil,
         status: CarStatus? = nil,
         minPrice: Double? = nil,
         maxPrice: Double? = nil,
         seatCount: Int? = nil,
         transmissionType: String? = nil,
         fuelType: String? = nil,
         location: Location? = nil,
         skip: Int? = nil,
         take: Int? = nil) {
        self.vehicleType = vehicleType
        self.status = status
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.seatCount = seatCount
        self.transmissionType = transmissionType
        self.fuelType = fuelType
        self.location = location
        self.skip = skip
        self.take = take
    }
}

// MARK: - Create Rental Request
nonisolated struct CreateRentalRequest: Codable, Sendable {
    let carId: String
    let startDate: Date
    let endDate: Date
    let pickupLocationId: String
    let dropoffLocationId: String
    let totalPrice: Double
    let distanceKm: Double?
}

// MARK: - Price Calculation Data
nonisolated struct PriceCalculationData: Codable, Sendable {
    let startDate: Date
    let endDate: Date
    let carId: String
    let distanceKm: Double
}

// MARK: - Price Calculation Response
nonisolated struct PriceCalculation: Codable, Sendable {
    let basePrice: Double
    let distancePrice: Double
    let totalPrice: Double
    let durationInDays: Int
    let distanceKm: Double
    
    var basePriceFormatted: String { String(format: "$%.0f", basePrice) }
    var distancePriceFormatted: String { String(format: "$%.0f", distancePrice) }
    var totalPriceFormatted: String { String(format: "$%.0f", totalPrice) }
}

// MARK: - Backward Compatibility
typealias CarDisplay = Car

// MARK: - Sample Data for Testing
extension Car {
    static let sampleCar = Car(
        id: "1",
        make: "Tesla",
        model: "Model S",
        year: 2024,
        color: "Red",
        licensePlate: "ABC123",
        price: 150.0,
        images: ["https://example.com/tesla.jpg"],
        description: "Electric luxury sedan",
        status: CarStatus.available,
        features: ["Electric", "Autopilot", "Premium Sound"],
        seatCount: 5,
        transmissionType: "Automatic",
        fuelType: "Electric",
        vehicleType: VehicleType.suv,
        createdAt: Date(),
        updatedAt: Date(),
        ownerId: "owner1",
        owner: nil as User?,
        location: nil as Location?,
        reviewIds: nil as [String]?,
        rentalIds: nil as [String]?
    )
    
    static let sampleCars = [
        sampleCar,
        Car(
            id: "2",
            make: "BMW",
            model: "X5",
            year: 2023,
            color: "Blue",
            licensePlate: "XYZ789",
            price: 120.0,
            images: ["https://example.com/bmw.jpg"],
            description: "Luxury SUV",
            status: CarStatus.available,
            features: ["All-Wheel Drive", "Premium Package"],
            seatCount: 7,
            transmissionType: "Automatic",
            fuelType: "Petrol",
            vehicleType: VehicleType.suv,
            createdAt: Date(),
            updatedAt: Date(),
            ownerId: "owner2",
            owner: nil as User?,
            location: nil as Location?,
            reviewIds: nil as [String]?,
            rentalIds: nil as [String]?
        )
    ]
}


enum VehicleTypeFilter: String, CaseIterable {
    case all = "All"
    case suv = "SUV"
    case coaster = "COASTER"
    case longVehicle = "LONG_VEHICLE"
    
    var displayName: String {
        switch self {
        case .all: return "All Cars"
        case .suv: return "SUVs"
        case .coaster: return "Coasters"
        case .longVehicle: return "Long Vehicles"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "car.2.fill"
        case .suv: return "car.fill"
        case .coaster: return "bus.fill"
        case .longVehicle: return "truck.box.fill"
        }
    }
    
    var vehicleType: VehicleType? {
        switch self {
        case .all: return nil
        case .suv: return .suv
        case .coaster: return .coaster
        case .longVehicle: return .longVehicle
        }
    }
}

// Removed duplicate Hashable extension for Car to avoid redeclaration and redundant conformance.

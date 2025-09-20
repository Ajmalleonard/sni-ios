import Foundation

// MARK: - Response Models
nonisolated struct LoginResponse: Codable, Sendable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

nonisolated struct EmptyResponse: Codable, Sendable {
    init() {}
}

// MARK: - Error Models
nonisolated struct BackendError: Codable, Sendable {
    let message: String
}

enum AuthError: Error, LocalizedError, Sendable {
    case invalidURL
    case noData
    case backend(String)
    case unexpectedResponse
    case invalidResponse
    case networkError(Error)
    case googleSignInError(String)
    case appleSignInError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL."
        case .noData:
            return "No data received from server."
        case .backend(let message):
            return message
        case .unexpectedResponse:
            return "Unexpected response from server."
        case .invalidResponse:
            return "Invalid response from server."
        case .networkError(let error):
            return error.localizedDescription
        case .googleSignInError(let message):
            return "Google Sign-In failed: \(message)"
        case .appleSignInError(let message):
            return "Apple Sign-In failed: \(message)"
        }
    }
}

// MARK: - Request Models
nonisolated struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

nonisolated struct GoogleSignInRequest: Codable, Sendable {
    let idToken: String
    let accessToken: String
    let email: String
    let name: String
    let profilePicture: String?
}

nonisolated struct AppleSignInRequest: Codable, Sendable {
    let identityToken: String
    let authorizationCode: String
    let email: String?
    let fullName: PersonNameComponents?
    let userIdentifier: String
    
    // Custom coding keys to handle PersonNameComponents
    enum CodingKeys: String, CodingKey {
        case identityToken
        case authorizationCode
        case email
        case fullName
        case userIdentifier
    }
    
    // Standard initializer
    init(identityToken: String, authorizationCode: String, email: String?, fullName: PersonNameComponents?, userIdentifier: String) {
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.email = email
        self.fullName = fullName
        self.userIdentifier = userIdentifier
    }
    
    // Custom encoding/decoding for PersonNameComponents
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identityToken = try container.decode(String.self, forKey: .identityToken)
        authorizationCode = try container.decode(String.self, forKey: .authorizationCode)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        userIdentifier = try container.decode(String.self, forKey: .userIdentifier)
        
        // Handle PersonNameComponents
        if let fullNameData = try container.decodeIfPresent([String: String].self, forKey: .fullName) {
            var nameComponents = PersonNameComponents()
            nameComponents.givenName = fullNameData["givenName"]
            nameComponents.familyName = fullNameData["familyName"]
            fullName = nameComponents
        } else {
            fullName = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identityToken, forKey: .identityToken)
        try container.encode(authorizationCode, forKey: .authorizationCode)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(userIdentifier, forKey: .userIdentifier)
        
        // Handle PersonNameComponents
        if let fullName = fullName {
            let fullNameData = [
                "givenName": fullName.givenName,
                "familyName": fullName.familyName
            ].compactMapValues { $0 }
            try container.encode(fullNameData, forKey: .fullName)
        }
    }
}

nonisolated struct EmailVerificationRequest: Codable, Sendable {
    let email: String
}

nonisolated struct CodeVerificationRequest: Codable, Sendable {
    let email: String
    let code: String
}

nonisolated struct CompleteRegistrationRequest: Codable, Sendable {
    let email: String
    let password: String
    let name: String
    let phoneNumber: String?
    let role: UserRole
}

nonisolated struct ChangePasswordRequest: Codable, Sendable {
    let currentPassword: String
    let newPassword: String
}

nonisolated struct UpdateProfileRequest: Codable, Sendable {
    let name: String
    let phoneNumber: String?
}

// MARK: - User Models
nonisolated struct User: Identifiable, Codable, Sendable, Equatable {
    let id: String
    var email: String
    var name: String
    var phoneNumber: String?
    var role: UserRole
    var profilePicture: String?
    var isVerified: Bool
    var createdAt: Date
    var authProvider: AuthProvider?
    
    // CodingKeys to map only the fields we need from the backend response
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case phoneNumber
        case role
        case profilePicture
        case isVerified
        case createdAt
        case authProvider
    }
    
    // Computed properties for UI
    nonisolated var isOAuthUser: Bool {
        return authProvider != nil && authProvider != .email
    }
    
    nonisolated var displayName: String {
        return name.isEmpty ? email : name
    }
    
    // Equatable conformance - compare by id since it's unique
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

enum UserRole: String, Codable, CaseIterable, Sendable {
    case admin = "ADMIN"
    case carOwner = "CAR_OWNER"
    case driver = "DRIVER"
    case client = "CLIENT"
}

enum AuthProvider: String, Codable, Sendable {
    case email = "EMAIL"
    case google = "GOOGLE"
    case apple = "APPLE"
}

// MARK: - Registration Flow
enum RegistrationStep: Sendable {
    case enterEmail
    case enterCode
    case enterDetails
}

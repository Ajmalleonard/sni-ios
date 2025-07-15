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
    case networkError(Error)
    case googleSignInError(String)
    
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
        case .networkError(let error):
            return error.localizedDescription
        case .googleSignInError(let message):
            return "Google Sign-In failed: \(message)"
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

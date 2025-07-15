import Combine
import Foundation

// MARK: - Optimized State Models
struct AuthState {
    var currentUser: User?
    var accessToken: String?
    var refreshToken: String?
    
    var isAuthenticated: Bool {
        return currentUser != nil && accessToken != nil
    }
}

struct RegistrationState {
    var step: RegistrationStep = .enterEmail
    var verifiedEmail: String?
    var codeVerified: Bool = false
    
    func reset() -> RegistrationState {
        return RegistrationState()
    }
}

struct MessageState {
    var message: String?
    var isError: Bool = false
    
    static let none = MessageState()
    
    static func error(_ message: String) -> MessageState {
        return MessageState(message: message, isError: true)
    }
    
    static func success(_ message: String) -> MessageState {
        return MessageState(message: message, isError: false)
    }
}

// MARK: - Optimized AuthModel
class AuthModel: ObservableObject {
    // Combined state properties - reduces UI updates
    @Published var authState = AuthState()
    @Published var registrationState = RegistrationState()
    @Published var messageState = MessageState.none
    @Published var isLoading: Bool = false
    
    private let authService = AuthService()
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for backward compatibility
    var currentUser: User? { authState.currentUser }
    var accessToken: String? { authState.accessToken }
    var refreshToken: String? { authState.refreshToken }
    var registrationStep: RegistrationStep { registrationState.step }
    var verifiedEmail: String? { registrationState.verifiedEmail }
    var codeVerified: Bool { registrationState.codeVerified }
    var errorMessage: String? { messageState.isError ? messageState.message : nil }
    var successMessage: String? { !messageState.isError ? messageState.message : nil }
    
    // Method to set success message
    func setSuccessMessage(_ message: String) {
        messageState = MessageState.success(message)
    }
    
    init() {
        setupMessageAutoClearing()
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) {
        performAuthOperation { [weak self] in
            await self?.handleLogin(email: email, password: password)
        }
    }
    
    func signInWithGoogle() {
        performAuthOperation { [weak self] in
            await self?.handleGoogleSignIn()
        }
    }
    
    func requestEmailVerification(email: String) {
        performAuthOperation { [weak self] in
            await self?.handleEmailVerification(email: email)
        }
    }
    
    func verifyEmailCode(email: String, code: String) {
        performAuthOperation { [weak self] in
            await self?.handleCodeVerification(email: email, code: code)
        }
    }
    
    func completeRegistration(email: String, password: String, name: String, phoneNumber: String?, role: UserRole) {
        performAuthOperation { [weak self] in
            await self?.handleRegistrationCompletion(email: email, password: password, name: name, phoneNumber: phoneNumber, role: role)
        }
    }
    
    func updateProfile(name: String, phoneNumber: String?) {
        performAuthOperation { [weak self] in
            await self?.handleProfileUpdate(name: name, phoneNumber: phoneNumber)
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) {
        performAuthOperation { [weak self] in
            await self?.handlePasswordChange(currentPassword: currentPassword, newPassword: newPassword)
        }
    }
    
    func logout() {
        authState = AuthState()
        registrationState = RegistrationState()
        messageState = MessageState.none
    }
    
    // MARK: - Private Async Handlers
    private func handleLogin(email: String, password: String) async {
        await withCheckedContinuation { continuation in
            authService.login(email: email, password: password) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self?.authState = AuthState(
                            currentUser: response.user,
                            accessToken: response.accessToken,
                            refreshToken: response.refreshToken
                        )
                        self?.messageState = MessageState.success("Login successful")
                        
                    case .failure(let error):
                        self?.messageState = MessageState.error(self?.parseErrorMessage(error) ?? "Login failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleGoogleSignIn() async {
        await withCheckedContinuation { continuation in
            authService.signInWithGoogle { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self?.authState = AuthState(
                            currentUser: response.user,
                            accessToken: response.accessToken,
                            refreshToken: response.refreshToken
                        )
                        self?.messageState = MessageState.success("Google Sign-In successful")
                        
                    case .failure(let error):
                        self?.messageState = MessageState.error(self?.parseErrorMessage(error) ?? "Google Sign-In failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleEmailVerification(email: String) async {
        await withCheckedContinuation { continuation in
            authService.requestEmailVerification(email: email) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.registrationState = RegistrationState(
                            step: .enterCode,
                            verifiedEmail: email,
                            codeVerified: false
                        )
                        self?.messageState = MessageState.success("Verification code sent to email")
                        
                    case .failure(let error):
                        self?.messageState = MessageState.error(self?.parseErrorMessage(error) ?? "Email verification failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleCodeVerification(email: String, code: String) async {
        await withCheckedContinuation { continuation in
            authService.verifyEmailCode(email: email, code: code) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.registrationState = RegistrationState(
                            step: .enterDetails,
                            verifiedEmail: email,
                            codeVerified: true
                        )
                        self?.messageState = MessageState.success("Email verified successfully")
                        
                    case .failure(let error):
                        self?.messageState = MessageState.error(self?.parseErrorMessage(error) ?? "Code verification failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleRegistrationCompletion(email: String, password: String, name: String, phoneNumber: String?, role: UserRole) async {
        await withCheckedContinuation { continuation in
            authService.completeRegistration(email: email, password: password, name: name, phoneNumber: phoneNumber, role: role) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self?.authState = AuthState(
                            currentUser: response.user,
                            accessToken: response.accessToken,
                            refreshToken: response.refreshToken
                        )
                        self?.registrationState = RegistrationState() // Reset registration state
                        self?.messageState = MessageState.success("Registration completed successfully")
                        
                    case .failure(let error):
                        self?.messageState = MessageState.error(self?.parseErrorMessage(error) ?? "Registration failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handleProfileUpdate(name: String, phoneNumber: String?) async {
        await withCheckedContinuation { continuation in
            authService.updateProfile(name: name, phoneNumber: phoneNumber) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let updatedUser):
                        self?.authState.currentUser = updatedUser
                        self?.messageState = MessageState.success("Profile updated successfully")
                        
                    case .failure(let error):
                        self?.messageState = MessageState.error(self?.parseErrorMessage(error) ?? "Profile update failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func handlePasswordChange(currentPassword: String, newPassword: String) async {
        await withCheckedContinuation { continuation in
            authService.changePassword(currentPassword: currentPassword, newPassword: newPassword) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.messageState = MessageState.success("Password changed successfully")
                        
                    case .failure(let error):
                        self?.messageState = MessageState.error(self?.parseErrorMessage(error) ?? "Password change failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    private func performAuthOperation(_ operation: @escaping () async -> Void) {
        guard !isLoading else { return } // Prevent multiple simultaneous operations
        
        messageState = MessageState.none
        isLoading = true
        
        Task {
            await operation()
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func setupMessageAutoClearing() {
        // Auto-clear messages after 5 seconds
        $messageState
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] messageState in
                if messageState.message != nil {
                    self?.messageState = MessageState.none
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




import Foundation
import Combine
import GoogleSignIn
import AuthenticationServices
import UIKit

class AuthService {
    private let baseURL = "https://api.snicolt.com"
//    private let baseURL = "http://localhost:1010"
    private var appleSignInDelegate: AppleSignInDelegate?
    
    // MARK: - Login
    func login(email: String, password: String, completion: @escaping @Sendable (Result<LoginResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/auth/login") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        let request = LoginRequest(email: email, password: password)
        performRequest(url: url, method: "POST", body: request, completion: completion)
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle(completion: @escaping @Sendable (Result<LoginResponse, Error>) -> Void) {
        // Ensure UI operations happen on main thread
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let presentingViewController = window.rootViewController else {
                completion(.failure(AuthError.googleSignInError("Could not find presenting view controller")))
                return
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            if let error = error {
                completion(.failure(AuthError.googleSignInError(error.localizedDescription)))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(AuthError.googleSignInError("Failed to get user information")))
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let email = user.profile?.email ?? ""
            let name = user.profile?.name ?? ""
            let profilePicture = user.profile?.imageURL(withDimension: 200)?.absoluteString
            
                self?.authenticateWithGoogle(
                    idToken: idToken,
                    accessToken: accessToken,
                    email: email,
                    name: name,
                    profilePicture: profilePicture,
                    completion: completion
                )
            }
        }
    }
    
    func signInWithGoogle() async throws -> LoginResponse {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.googleSignInError("No presenting view controller found")
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
             
            guard let idToken = user.idToken?.tokenString else {
                throw AuthError.googleSignInError("Failed to get ID token")
            }
            
            let accessToken = user.accessToken.tokenString
            let email = user.profile?.email ?? ""
            let name = user.profile?.name ?? ""
            let profilePicture = user.profile?.imageURL(withDimension: 200)?.absoluteString
            
            return try await authenticateWithGoogle(
                idToken: idToken,
                accessToken: accessToken,
                email: email,
                name: name,
                profilePicture: profilePicture
            )
        } catch {
            throw AuthError.googleSignInError(error.localizedDescription)
        }
    }
    
    func signInWithApple() async throws -> LoginResponse {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            
            // Store delegate as property to prevent deallocation
            Task { @MainActor in
                self.appleSignInDelegate = AppleSignInDelegate { [weak self] result in
                    defer { self?.appleSignInDelegate = nil } // Clean up after completion
                    switch result {
                    case .success(let loginResponse):
                        continuation.resume(returning: loginResponse)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                authorizationController.delegate = self.appleSignInDelegate
                authorizationController.presentationContextProvider = self.appleSignInDelegate
                authorizationController.performRequests()
            }
        }
    }
    
    private func authenticateWithGoogle(
        idToken: String,
        accessToken: String,
        email: String,
        name: String,
        profilePicture: String?,
        completion: @escaping @Sendable (Result<LoginResponse, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + "/auth/google") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        let request = GoogleSignInRequest(
            idToken: idToken,
            accessToken: accessToken,
            email: email,
            name: name,
            profilePicture: profilePicture
        )
        
        performRequest(url: url, method: "POST", body: request, completion: completion)
    }
    
    private func authenticateWithGoogle(
        idToken: String,
        accessToken: String,
        email: String,
        name: String,
        profilePicture: String?
    ) async throws -> LoginResponse {
        let request = GoogleSignInRequest(
            idToken: idToken,
            accessToken: accessToken,
            email: email,
            name: name,
            profilePicture: profilePicture
        )
        
        guard let url = URL(string: baseURL + "/auth/google") else {
            throw AuthError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AuthError.networkError(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.unexpectedResponse
            }
            
            if httpResponse.statusCode == 200 {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                return loginResponse
            } else {
                if let errorData = try? JSONDecoder().decode(BackendError.self, from: data) {
                    throw AuthError.backend(errorData.message)
                } else {
                    throw AuthError.invalidResponse
                }
            }
        } catch {
            if error is AuthError {
                throw error
            } else {
                throw AuthError.networkError(error)
            }
        }
    }
    
    func authenticateWithApple(
        identityToken: String,
        authorizationCode: String,
        email: String?,
        fullName: PersonNameComponents?,
        userIdentifier: String
    ) async throws -> LoginResponse {
        let request = AppleSignInRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            email: email,
            fullName: fullName,
            userIdentifier: userIdentifier
        )
        
        guard let url = URL(string: baseURL + "/auth/apple") else {
            throw AuthError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AuthError.networkError(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.unexpectedResponse
            }
            
            if httpResponse.statusCode == 200 {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                return loginResponse
            } else {
                if let errorData = try? JSONDecoder().decode(BackendError.self, from: data) {
                    throw AuthError.backend(errorData.message)
                } else {
                    throw AuthError.invalidResponse
                }
            }
        } catch {
            if error is AuthError {
                throw error
            } else {
                throw AuthError.networkError(error)
            }
        }
    }
    
    // MARK: - Email Verification
    func requestEmailVerification(email: String, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/auth/check-email") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        let request = EmailVerificationRequest(email: email)
        performRequest(url: url, method: "POST", body: request) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    func verifyEmailCode(email: String, code: String, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/auth/validate-email") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        let request = CodeVerificationRequest(email: email, code: code)
        performRequest(url: url, method: "POST", body: request) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func completeRegistration(email: String, password: String, name: String, phoneNumber: String?, role: UserRole, completion: @escaping @Sendable (Result<LoginResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/auth/complete-registration") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        let request = CompleteRegistrationRequest(email: email, password: password, name: name, phoneNumber: phoneNumber, role: role)
        performRequest(url: url, method: "POST", body: request, completion: completion)
    }
    
    // MARK: - Profile Management
    func updateProfile(name: String, phoneNumber: String?, completion: @escaping @Sendable (Result<User, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/auth/update-profile") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        let request = UpdateProfileRequest(name: name, phoneNumber: phoneNumber)
        performRequest(url: url, method: "PUT", body: request, completion: completion)
    }
    
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/auth/change-password") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        let request = ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword)
        performRequest(url: url, method: "PUT", body: request) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Helpers
    private func performRequest<T: Encodable & Sendable, U: Decodable & Sendable>(
        url: URL, 
        method: String, 
        body: T, 
        completion: @escaping @Sendable (Result<U, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Print detailed response information
            self?.printResponseDetails(url: url, data: data, response: response, error: error)
            
            if let error = error {
                completion(.failure(AuthError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(AuthError.noData))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                // Handle empty success responses
                if (200...299).contains(httpResponse.statusCode) {
                    // Use type checking without capturing the type
                    if String(describing: U.self) == String(describing: EmptyResponse.self) {
                        if let emptyResponse = EmptyResponse() as? U {
                            completion(.success(emptyResponse))
                            return
                        }
                    }
                }
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
                // Handle backend error decoding in a non-isolated way
                self?.handleBackendError(data: data, originalError: error, completion: completion)
            }
        }
        task.resume()
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
                completion(.failure(AuthError.backend(backendError.message)))
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
        print("🚀 API REQUEST")
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
        print("📥 API RESPONSE")
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
        print("✅ SUCCESSFUL DECODE")
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

// MARK: - Apple Sign-In Delegate
@MainActor
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<LoginResponse, Error>) -> Void
    
    init(completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple Sign-In: Authorization completed")
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("❌ Apple Sign-In: Invalid credential type")
            completion(.failure(AuthError.appleSignInError("Invalid credential type")))
            return
        }
        
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              let authorizationCodeData = appleIDCredential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
            print("❌ Apple Sign-In: Failed to get identity token or authorization code")
            completion(.failure(AuthError.appleSignInError("Failed to get identity token or authorization code")))
            return
        }
        
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        let userIdentifier = appleIDCredential.user
        
        print("🍎 Apple Sign-In: Got credentials - Email: \(email ?? "nil"), UserID: \(userIdentifier)")
        
        Task {
            do {
                print("🍎 Apple Sign-In: Starting backend authentication...")
                let authService = AuthService()
                let loginResponse = try await authService.authenticateWithApple(
                    identityToken: identityToken,
                    authorizationCode: authorizationCode,
                    email: email,
                    fullName: fullName,
                    userIdentifier: userIdentifier
                )
                print("✅ Apple Sign-In: Backend authentication successful")
                completion(.success(loginResponse))
            } catch {
                print("❌ Apple Sign-In: Backend authentication failed - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In: Authorization failed - \(error.localizedDescription)")
        completion(.failure(AuthError.appleSignInError(error.localizedDescription)))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

//
//  TokenManager.swift
//  SNI Rentals
//
//  Created by Assistant on 08/01/25.
//

import Foundation
import Combine

// MARK: - Token Manager
class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    @Published var isAuthenticated = false
    
    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"
    
    private init() {
        // Check if user is already authenticated on init
        isAuthenticated = getCurrentAccessToken() != nil
    }
    
    // MARK: - Token Storage
    
    func storeTokens(accessToken: String, refreshToken: String, userId: String? = nil) {
        userDefaults.set(accessToken, forKey: accessTokenKey)
        userDefaults.set(refreshToken, forKey: refreshTokenKey)
        
        if let userId = userId {
            userDefaults.set(userId, forKey: userIdKey)
        }
        
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
        
        print("✅ Tokens stored successfully")
    }
    
    func clearTokens() {
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
        userDefaults.removeObject(forKey: userIdKey)
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
        
        print("🗑️ Tokens cleared")
    }
    
    // MARK: - Token Retrieval
    
    func getCurrentAccessToken() -> String? {
        return userDefaults.string(forKey: accessTokenKey)
    }
    
    func getCurrentRefreshToken() -> String? {
        return userDefaults.string(forKey: refreshTokenKey)
    }
    
    func getCurrentUserId() -> String? {
        return userDefaults.string(forKey: userIdKey)
    }
    
    // MARK: - Token Validation
    
    func isTokenValid() -> Bool {
        guard let token = getCurrentAccessToken() else {
            return false
        }
        
        // Basic JWT token validation (check if it's not expired)
        return !isTokenExpired(token)
    }
    
    private func isTokenExpired(_ token: String) -> Bool {
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else {
            return true // Invalid JWT format
        }
        
        let payload = components[1]
        guard let data = base64UrlDecode(payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return true // Cannot decode or no expiration
        }
        
        let expirationDate = Date(timeIntervalSince1970: exp)
        return Date() >= expirationDate
    }
    
    private func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        
        return Data(base64Encoded: base64)
    }
    
    // MARK: - Authorization Header Helper
    
    func getAuthorizationHeader() -> String? {
        guard let token = getCurrentAccessToken() else {
            return nil
        }
        return "Bearer \(token)"
    }
    
    // MARK: - Token Refresh (placeholder for future implementation)
    
    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        guard getCurrentRefreshToken() != nil else {
            completion(false)
            return
        }
        
        // TODO: Implement token refresh logic with backend
        // This should call your backend's refresh token endpoint
        print("🔄 Token refresh needed - implement refresh logic")
        completion(false)
    }
}

// MARK: - Convenience Extensions

extension URLRequest {
    mutating func addAuthorizationHeader() {
        if let authHeader = TokenManager.shared.getAuthorizationHeader() {
            setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
    }
}
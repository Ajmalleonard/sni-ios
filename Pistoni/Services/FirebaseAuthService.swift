//
//  FirebaseAuthService.swift
//  SNI Rentals
//
//  Created by Assistant on 08/01/25.
//

import Foundation
import FirebaseAuth
import Combine

class FirebaseAuthService: ObservableObject {
    @Published var isFirebaseAuthenticated = false
    private let baseURL = "https://api.snicolt.com"
    
    // MARK: - Authenticate with Firebase using backend token
    func authenticateWithFirebase(user: User, completion: @escaping (Bool) -> Void) {
        // First, get a custom Firebase token from your backend
        getFirebaseCustomToken(for: user) { [weak self] result in
            switch result {
            case .success(let customToken):
                // Sign in to Firebase with the custom token
                Auth.auth().signIn(withCustomToken: customToken) { authResult, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Firebase authentication failed: \(error.localizedDescription)")
                            self?.isFirebaseAuthenticated = false
                            completion(false)
                        } else {
                            print("✅ Firebase authentication successful")
                            self?.isFirebaseAuthenticated = true
                            completion(true)
                        }
                    }
                }
            case .failure(let error):
                print("❌ Failed to get custom token: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isFirebaseAuthenticated = false
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Get Custom Token from Backend
    private func getFirebaseCustomToken(for user: User, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/auth/firebase-token") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header - you'll need to get the current user's token
        if let token = getCurrentUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = [
            "userId": user.id,
            "email": user.email,
            "name": user.name
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthError.unexpectedResponse))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Firebase token request failed with status: \(httpResponse.statusCode)")
                completion(.failure(AuthError.unexpectedResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(AuthError.noData))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let customToken = json["customToken"] as? String {
                    completion(.success(customToken))
                } else {
                    completion(.failure(AuthError.unexpectedResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    private func getCurrentUserToken() -> String? {
        return TokenManager.shared.getCurrentAccessToken()
    }
    
    // MARK: - Sign Out from Firebase
    func signOutFromFirebase() {
        do {
            try Auth.auth().signOut()
            isFirebaseAuthenticated = false
            print("✅ Firebase sign out successful")
        } catch {
            print("❌ Firebase sign out failed: \(error.localizedDescription)")
        }
    }
}

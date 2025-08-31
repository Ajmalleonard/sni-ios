//
//  ChatUserService.swift
//  SNI Rentals
//
//  Created by Assistant on 08/01/25.
//

import Foundation
import Combine

class ChatUserService {
    private let baseURL = "https://api.snicolt.com"
    
    // MARK: - Fetch All Users for Chat
    func fetchChatUsers(excludingUserId currentUserId: String, completion: @escaping (Result<[ChatUser], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/users/chat-users") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header - you'll need to get the current user's token
        // This should be retrieved from your AuthModel or stored securely
        if let token = getCurrentUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
                print("❌ Chat users request failed with status: \(httpResponse.statusCode)")
                completion(.failure(AuthError.unexpectedResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(AuthError.noData))
                return
            }
            
            do {
                let backendUsers = try JSONDecoder().decode([BackendUser].self, from: data)
                
                // Convert backend users to ChatUser and exclude current user
                let chatUsers = backendUsers
                    .filter { $0.id != currentUserId }
                    .map { backendUser in
                        ChatUser(
                            id: backendUser.id,
                            name: backendUser.name,
                            email: backendUser.email,
                            profilePicture: backendUser.profilePicture,
                            isOnline: backendUser.isOnline ?? false,
                            lastSeen: backendUser.lastSeen
                        )
                    }
                
                completion(.success(chatUsers))
            } catch {
                print("❌ Error decoding chat users: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Update User Online Status
    func updateOnlineStatus(userId: String, isOnline: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/users/\(userId)/online-status") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        if let token = getCurrentUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = [
            "isOnline": isOnline,
            "lastSeen": ISO8601DateFormatter().string(from: Date())
        ] as [String: Any]
        
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
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(.success(()))
                } else {
                    print("❌ Online status update failed with status: \(httpResponse.statusCode)")
                    completion(.failure(AuthError.unexpectedResponse))
                }
            } else {
                completion(.failure(AuthError.unexpectedResponse))
            }
        }.resume()
    }
    
    // MARK: - Sync User to Firebase
    func syncUserToFirebase(user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/users/sync-to-firebase") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        if let token = getCurrentUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = [
            "userId": user.id,
            "name": user.name,
            "email": user.email,
            "profilePicture": user.profilePicture ?? "",
            "role": user.role.rawValue,
            "authProvider": user.authProvider?.rawValue ?? "email"
        ] as [String: Any]
        
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
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    completion(.success(()))
                } else {
                    print("❌ User sync failed with status: \(httpResponse.statusCode)")
                    completion(.failure(AuthError.unexpectedResponse))
                }
            } else {
                completion(.failure(AuthError.unexpectedResponse))
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    private func getCurrentUserToken() -> String? {
        return TokenManager.shared.getCurrentAccessToken()
    }
}

// MARK: - Backend User Model
struct BackendUser: Codable {
    let id: String
    let name: String
    let email: String
    let profilePicture: String?
    let isOnline: Bool?
    let lastSeen: Date?
    let role: String?
    let authProvider: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, profilePicture, isOnline, lastSeen, role, authProvider
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        profilePicture = try container.decodeIfPresent(String.self, forKey: .profilePicture)
        isOnline = try container.decodeIfPresent(Bool.self, forKey: .isOnline)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        authProvider = try container.decodeIfPresent(String.self, forKey: .authProvider)
        
        // Handle date parsing
        if let lastSeenString = try container.decodeIfPresent(String.self, forKey: .lastSeen) {
            let formatter = ISO8601DateFormatter()
            lastSeen = formatter.date(from: lastSeenString)
        } else {
            lastSeen = nil
        }
    }
}
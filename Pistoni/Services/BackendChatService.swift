//
//  BackendChatService.swift
//  SNI Rentals
//
//  Created by Assistant on 08/01/25.
//

import Foundation
import Combine

class BackendChatService: ObservableObject {
    private let baseURL = "https://api.snicolt.com"
    
    // MARK: - Chat User Management
    
    func fetchChatUsers(completion: @escaping (Result<[BackendChatUser], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/users/chat-users") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getCurrentUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(AuthError.unexpectedResponse))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    completion(.failure(AuthError.unexpectedResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(AuthError.invalidResponse))
                    return
                }
                
                do {
                    let users = try JSONDecoder().decode([BackendChatUser].self, from: data)
                    completion(.success(users))
                } catch {
                    print("❌ Error decoding chat users: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func updateOnlineStatus(userId: String, isOnline: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/users/\(userId)/online-status") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(AuthError.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                    completion(.success(()))
                } else {
                    print("❌ Online status update failed with status: \(httpResponse.statusCode)")
                    completion(.failure(AuthError.unexpectedResponse))
                }
            }
        }.resume()
    }
    
    // MARK: - Chat Room Management
    
    func fetchChatRooms(completion: @escaping (Result<[ChatRoom], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/chat/rooms") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getCurrentUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(AuthError.invalidResponse))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    completion(.failure(AuthError.unexpectedResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(AuthError.invalidResponse))
                    return
                }
                
                do {
                    let rooms = try JSONDecoder().decode([ChatRoom].self, from: data)
                    completion(.success(rooms))
                } catch {
                    print("❌ Error decoding chat rooms: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func createChatRoom(participants: [String], completion: @escaping (Result<ChatRoom, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/chat/rooms") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getCurrentUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = [
            "participants": participants,
            "type": "PRIVATE"
        ] as [String: Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(AuthError.invalidResponse))
                    return
                }
                
                guard httpResponse.statusCode == 201 else {
                    completion(.failure(AuthError.unexpectedResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(AuthError.invalidResponse))
                    return
                }
                
                do {
                    let room = try JSONDecoder().decode(ChatRoom.self, from: data)
                    completion(.success(room))
                } catch {
                    print("❌ Error decoding chat room: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Message History
    
    func fetchMessages(roomId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        guard let url = URL(string: baseURL + "/chat/rooms/\(roomId)/messages") else {
            completion(.failure(AuthError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getCurrentUserToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(AuthError.invalidResponse))
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    completion(.failure(AuthError.unexpectedResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(AuthError.invalidResponse))
                    return
                }
                
                do {
                    let messages = try JSONDecoder().decode([Message].self, from: data)
                    completion(.success(messages))
                } catch {
                    print("❌ Error decoding messages: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserToken() -> String? {
        return TokenManager.shared.getCurrentAccessToken()
    }
}

// MARK: - Chat Models

struct ChatRoom: Identifiable, Codable {
    let id: String
    let name: String?
    let type: String // "PRIVATE" or "GROUP"
    let createdAt: Date
    let updatedAt: Date
    let participants: [ChatRoomParticipant]
    let lastMessage: Message?
    let unreadCount: Int
}

struct ChatRoomParticipant: Identifiable, Codable {
    let id: String
    let userId: String
    let chatRoomId: String
    let joinedAt: Date
    let user: BackendChatUser?
}

struct BackendChatUser: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let profilePicture: String?
    let status: String? // "ONLINE" or "OFFLINE"
    let lastSeen: Date?
    let role: String
    let authProvider: String
    let createdAt: Date
    
    var isOnline: Bool {
        return status == "ONLINE"
    }
}
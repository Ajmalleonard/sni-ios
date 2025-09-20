//
//  ChatModels.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 12/08/2025.
//

import Foundation
import FirebaseFirestore

// Enhanced Message model with sender info
struct EnhancedChatMessage: Identifiable, Codable {
    var id: String
    var text: String
    var senderId: String
    var senderName: String
    var receiverId: String
    var receiverName: String
    var timestamp: Date
    var chatRoomId: String
    
    // Helper property to determine if message was received by current user
    func isReceived(by userId: String) -> Bool {
        return receiverId == userId
    }
}

// Simple chat user model
struct ChatUser: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var profilePicture: String?
    var isOnline: Bool = false
    var lastSeen: Date?
    
    init(id: String, name: String, email: String, profilePicture: String? = nil, isOnline: Bool = false, lastSeen: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.profilePicture = profilePicture
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
    
    init(from user: User) {
        self.id = user.id
        self.name = user.name
        self.email = user.email
        self.profilePicture = user.profilePicture
        self.isOnline = false
        self.lastSeen = Date()
    }
}

// Chat room model
struct EnhancedChatRoom: Identifiable, Codable {
    var id: String
    var participants: [String] // User IDs
    var participantNames: [String] // User names for display
    var lastMessage: String?
    var lastMessageTime: Date?
    var createdAt: Date
    
    // Generate chat room ID from two user IDs
    static func generateRoomId(user1: String, user2: String) -> String {
        return [user1, user2].sorted().joined(separator: "_")
    }
} 
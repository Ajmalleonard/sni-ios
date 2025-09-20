//
//  EnhancedMessagesManager.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 12/08/2025.
//

import Foundation
import Combine
import UIKit

class EnhancedMessagesManager: ObservableObject {
    @Published private(set) var messages: [EnhancedChatMessage] = []
    @Published var availableUsers: [ChatUser] = []
    @Published private(set) var lastMessageId: String = ""
    @Published var selectedUser: ChatUser?
    @Published var currentChatRoomId: String?
    @Published var isConnected = false
    
    private let backendChatService = BackendChatService()
    private let webSocketChatService = WebSocketChatService()
    
    let currentUser: User
    
    init(currentUser: User) {
        self.currentUser = currentUser
        setupBackendConnection()
    }
    
    deinit {
        webSocketChatService.disconnect()
    }
    
    // MARK: - Setup Backend Connection
    private func setupBackendConnection() {
        // Connect to WebSocket for real-time messaging
        webSocketChatService.connect(user: currentUser)
        
        // Load available users from backend
        loadAvailableUsers()
        
        // Update online status
        updateOnlineStatus(isOnline: true)
    }
    
    // MARK: - Load Available Users from Backend
    func loadAvailableUsers() {
        backendChatService.fetchChatUsers { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let backendUsers):
                    // Convert BackendChatUser to ChatUser for compatibility
                    let chatUsers = backendUsers.map { backendUser in
                        ChatUser(
                            id: backendUser.id,
                            name: backendUser.name,
                            email: backendUser.email,
                            profilePicture: backendUser.profilePicture,
                            isOnline: backendUser.isOnline,
                            lastSeen: backendUser.lastSeen
                        )
                    }
                    self?.availableUsers = chatUsers
                    print("📱 Loaded \(chatUsers.count) available users from backend")
                case .failure(let error):
                    print("❌ Error loading users from backend: \(error)")
                    self?.availableUsers = []
                }
            }
        }
    }
    
    // MARK: - Update Online Status
    func updateOnlineStatus(isOnline: Bool) {
        backendChatService.updateOnlineStatus(userId: currentUser.id, isOnline: isOnline) { result in
            switch result {
            case .success:
                print("✅ Online status updated: \(isOnline)")
            case .failure(let error):
                print("❌ Error updating online status: \(error)")
            }
        }
    }
    
    // MARK: - Start Chat with User
    func startChat(with user: ChatUser) {
        selectedUser = user
        currentChatRoomId = EnhancedChatRoom.generateRoomId(user1: currentUser.id, user2: user.id)
        
        // Join chat room via WebSocket
        if let roomId = currentChatRoomId {
            webSocketChatService.joinChatRoom(roomId: roomId)
        }
        
        // Load messages for this chat room
        loadMessages()
    }
    
    // MARK: - Load Messages
    private func loadMessages() {
        guard let roomId = currentChatRoomId else { return }
        
        backendChatService.fetchMessages(roomId: roomId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let backendMessages):
                    // Convert backend messages to EnhancedChatMessage for compatibility
                    let enhancedMessages = backendMessages.map { backendMessage in
                        EnhancedChatMessage(
                            id: backendMessage.id,
                            text: backendMessage.content,
                            senderId: backendMessage.senderId,
                            senderName: backendMessage.sender?.name ?? "Unknown",
                            receiverId: "", // Will be determined based on sender
                            receiverName: "", // Will be determined based on sender
                            timestamp: backendMessage.createdAt,
                            chatRoomId: backendMessage.chatRoomId
                        )
                    }
                    self?.messages = enhancedMessages
                    print("📱 Loaded \(enhancedMessages.count) messages from backend")
                case .failure(let error):
                    print("❌ Error loading messages from backend: \(error)")
                    self?.messages = []
                }
            }
        }
    }
    
    // MARK: - Send Message
    func sendMessage(_ text: String) {
        guard let roomId = currentChatRoomId else { return }
        
        // Send via WebSocket for real-time delivery
        webSocketChatService.sendMessage(content: text)
        
        // Create local message for immediate UI update
        let newMessage = EnhancedChatMessage(
            id: UUID().uuidString,
            text: text,
            senderId: currentUser.id,
            senderName: currentUser.name,
            receiverId: selectedUser?.id ?? "",
            receiverName: selectedUser?.name ?? "",
            timestamp: Date(),
            chatRoomId: roomId
        )
        
        DispatchQueue.main.async {
            self.messages.append(newMessage)
        }
    }
    
    // MARK: - Leave Chat
    func leaveChat() {
        webSocketChatService.leaveChatRoom()
        selectedUser = nil
        currentChatRoomId = nil
        messages = []
    }
    
    // MARK: - App Lifecycle
    func appWillResignActive() {
        updateOnlineStatus(isOnline: false)
    }
    
    func appDidBecomeActive() {
        updateOnlineStatus(isOnline: true)
    }
}
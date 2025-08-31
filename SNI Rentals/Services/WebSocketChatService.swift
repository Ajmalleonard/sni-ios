//
//  WebSocketChatService.swift
//  SNI Rentals
//
//  Created by Assistant on 08/01/25.
//

import Foundation
import Combine
import SocketIO

class WebSocketChatService: ObservableObject {
    @Published var isConnected = false
    @Published var messages: [Message] = []
    @Published var typingUsers: Set<String> = []
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let baseURL = "https://api.snicolt.com"
    private var currentUser: User?
    private var currentRoomId: String?
    
    // Flag to indicate if this instance is being used in a preview
    var isPreview: Bool = false
    
    init() {
        // Check if running in preview mode
        let isPreviewMode = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        if isPreviewMode {
            self.isPreview = true
            setupMockData()
        }
    }
    
    private func setupMockData() {
        // Create mock messages for preview
        let mockUser = User(
            id: "user1",
            email: "john@example.com",
            name: "John Doe",
            phoneNumber: nil,
            role: .client,
            profilePicture: nil,
            isVerified: true,
            createdAt: Date(),
            authProvider: .email
        )
        let mockMessages = [
            Message(
                id: "1",
                content: "Hello! How can I help you today?",
                messageType: "TEXT",
                senderId: "user2",
                chatRoomId: "room1",
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-3600),
                sender: nil,
                isRead: true
            ),
            Message(
                id: "2",
                content: "I'm interested in renting a property.",
                messageType: "TEXT",
                senderId: "user1",
                chatRoomId: "room1",
                createdAt: Date().addingTimeInterval(-1800),
                updatedAt: Date().addingTimeInterval(-1800),
                sender: mockUser,
                isRead: true
            )
        ]
        
        self.messages = mockMessages
        self.isConnected = true
    }
    
    // MARK: - Connection Management
    
    func connect(user: User) {
        // Skip WebSocket connection in preview mode
        if isPreview {
            self.currentUser = user
            isConnected = true
            return
        }
        
        self.currentUser = user
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        manager = SocketManager(socketURL: url, config: [
            .log(true),
            .compress,
            .connectParams(["userId": user.id, "token": getAuthToken() ?? ""])
        ])
        
        socket = manager?.defaultSocket
        
        setupSocketEvents()
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        manager = nil
        socket = nil
        isConnected = false
    }
    
    // MARK: - Socket Event Setup
    
    private func setupSocketEvents() {
        guard let socket = socket else { return }
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("✅ WebSocket connected")
            DispatchQueue.main.async {
                self?.isConnected = true
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("❌ WebSocket disconnected")
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }
        
        socket.on(clientEvent: .error) { [weak self] data, _ in
            print("❌ WebSocket error: \(data)")
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }
        
        // Chat events
        socket.on("newMessage") { [weak self] data, _ in
            self?.handleNewMessage(data: data)
        }
        
        socket.on("userTyping") { [weak self] data, _ in
            self?.handleTypingIndicator(data: data)
        }
        
        socket.on("userStoppedTyping") { [weak self] data, _ in
            self?.handleStoppedTyping(data: data)
        }
        
        socket.on("userOnline") { [weak self] data, _ in
            self?.handleUserOnline(data: data)
        }
        
        socket.on("userOffline") { [weak self] data, _ in
            self?.handleUserOffline(data: data)
        }
    }
    
    // MARK: - Chat Room Management
    
    func joinChatRoom(roomId: String) {
        currentRoomId = roomId
        
        // Skip WebSocket operations in preview mode
        if isPreview {
            print("🔗 [Preview] Joined chat room: \(roomId)")
            return
        }
        
        socket?.emit("joinRoom", roomId)
        print("🔗 Joined chat room: \(roomId)")
    }
    
    func leaveChatRoom() {
        if let roomId = currentRoomId {
            // Skip WebSocket operations in preview mode
            if isPreview {
                print("🔗 [Preview] Left chat room: \(roomId)")
            } else {
                socket?.emit("leaveRoom", roomId)
                print("🔗 Left chat room: \(roomId)")
            }
        }
        currentRoomId = nil
    }
    
    // MARK: - Message Handling
    
    func sendMessage(content: String) {
        // Skip WebSocket operations in preview mode
        if isPreview {
            // Add mock message to preview
            if let currentUser = currentUser, let roomId = currentRoomId {
                let mockMessage = Message(
                    id: UUID().uuidString,
                    content: content,
                    messageType: "TEXT",
                    senderId: currentUser.id,
                    chatRoomId: roomId,
                    createdAt: Date(),
                    updatedAt: Date(),
                    sender: currentUser,
                    isRead: false
                )
                messages.append(mockMessage)
            }
            return
        }
        
        guard let roomId = currentRoomId,
              let userId = currentUser?.id else {
            print("❌ Cannot send message - missing room or user")
            return
        }
        
        let messageData: [String: Any] = [
            "content": content,
            "chatRoomId": roomId,
            "messageType": "TEXT"
        ]
        
        socket?.emit("sendMessage", messageData)
        print("📤 Sent message: \(content)")
    }
    
    private func handleNewMessage(data: [Any]) {
        guard let messageData = data.first as? [String: Any],
              let message = parseMessage(from: messageData) else {
            print("❌ Failed to parse new message")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.messages.append(message)
        }
        print("📥 Received message: \(message.content)")
    }
    
    // MARK: - Typing Indicators
    
    func sendTypingIndicator(isTyping: Bool) {
        guard let roomId = currentRoomId else { return }
        
        // Skip WebSocket operations in preview mode
        if isPreview {
            return
        }
        
        let typingData: [String: Any] = [
            "chatRoomId": roomId,
            "isTyping": isTyping
        ]
        
        socket?.emit("typing", typingData)
    }
    
    private func handleTypingIndicator(data: [Any]) {
        guard let typingData = data.first as? [String: Any],
              let userId = typingData["userId"] as? String else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.typingUsers.insert(userId)
        }
    }
    
    private func handleStoppedTyping(data: [Any]) {
        guard let typingData = data.first as? [String: Any],
              let userId = typingData["userId"] as? String else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.typingUsers.remove(userId)
        }
    }
    
    // MARK: - Online Status
    
    func updateOnlineStatus(isOnline: Bool) {
        // Skip WebSocket operations in preview mode
        if isPreview {
            return
        }
        
        let statusData: [String: Any] = [
            "isOnline": isOnline
        ]
        
        socket?.emit("updateStatus", statusData)
    }
    
    private func handleUserOnline(data: [Any]) {
        guard let userData = data.first as? [String: Any],
              let userId = userData["userId"] as? String else { return }
        
        print("🟢 User online: \(userId)")
        // You can emit a notification or update UI here
    }
    
    private func handleUserOffline(data: [Any]) {
        guard let userData = data.first as? [String: Any],
              let userId = userData["userId"] as? String else { return }
        
        print("🔴 User offline: \(userId)")
        // You can emit a notification or update UI here
    }
    
    // MARK: - Helper Methods
    
    private func parseMessage(from data: [String: Any]) -> Message? {
        guard let id = data["id"] as? String,
              let content = data["content"] as? String,
              let senderId = data["senderId"] as? String,
              let chatRoomId = data["chatRoomId"] as? String,
              let createdAtString = data["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            return nil
        }
        
        return Message(
            id: id,
            content: content,
            messageType: data["messageType"] as? String ?? "TEXT",
            senderId: senderId,
            chatRoomId: chatRoomId,
            createdAt: createdAt,
            updatedAt: createdAt,
            sender: nil,
            isRead: data["isRead"] as? Bool ?? false
        )
    }
    
    private func getAuthToken() -> String? {
        return TokenManager.shared.getCurrentAccessToken()
    }
}

// MARK: - Message Model
struct Message: Identifiable, Codable {
    let id: String
    let content: String
    let messageType: String
    let senderId: String
    let chatRoomId: String
    let createdAt: Date
    let updatedAt: Date
    let sender: User?
    let isRead: Bool
}
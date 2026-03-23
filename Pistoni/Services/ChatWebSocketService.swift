import Foundation
import Combine
import SocketIO

/// WebSocket service for chat functionality
/// Handles chat-specific events like messages, typing indicators, and room management
class ChatWebSocketService: ObservableObject {
    // MARK: - Published Properties
    @Published var newMessage: EnhancedChatMessage?
    @Published var messageEdited: EnhancedChatMessage?
    @Published var messageDeleted: String? // Message ID
    @Published var userTyping: (userId: String, chatRoomId: String, isTyping: Bool)?
    
    // MARK: - Private Properties
    private let socketManager = SocketIOManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    static let shared = ChatWebSocketService()
    
    private init() {
        setupEventListeners()
    }
    
    // MARK: - Event Listeners
    
    private func setupEventListeners() {
        // Listen for new messages
        socketManager.on(event: "newMessage") { [weak self] data in
            guard let messageData = data.first as? [String: Any] else { return }
            if let message = self?.parseMessage(from: messageData) {
                DispatchQueue.main.async {
                    self?.newMessage = message
                    print("💬 New message received: \(message.text)")
                }
            }
        }
        
        // Listen for edited messages
        socketManager.on(event: "messageEdited") { [weak self] data in
            guard let messageData = data.first as? [String: Any] else { return }
            if let message = self?.parseMessage(from: messageData) {
                DispatchQueue.main.async {
                    self?.messageEdited = message
                    print("✏️ Message edited: \(message.id)")
                }
            }
        }
        
        // Listen for deleted messages
        socketManager.on(event: "messageDeleted") { [weak self] data in
            guard let messageData = data.first as? [String: Any],
                  let messageId = messageData["id"] as? String else { return }
            DispatchQueue.main.async {
                self?.messageDeleted = messageId
                print("🗑️ Message deleted: \(messageId)")
            }
        }
        
        // Listen for typing indicators
        socketManager.on(event: "userTyping") { [weak self] data in
            guard let typingData = data.first as? [String: Any],
                  let userId = typingData["userId"] as? String,
                  let chatRoomId = typingData["chatRoomId"] as? String,
                  let isTyping = typingData["isTyping"] as? Bool else { return }
            
            DispatchQueue.main.async {
                self?.userTyping = (userId, chatRoomId, isTyping)
                print("⌨️ User \(userId) \(isTyping ? "is typing" : "stopped typing") in \(chatRoomId)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseMessage(from data: [String: Any]) -> EnhancedChatMessage? {
        guard let id = data["id"] as? String,
              let content = data["content"] as? String,
              let senderId = data["senderId"] as? String,
              let chatRoomId = data["chatRoomId"] as? String,
              let timestampString = data["timestamp"] as? String else {
            print("❌ Failed to parse message data")
            return nil
        }
        
        // Parse sender info
        var senderName = "Unknown"
        let receiverId = ""
        let receiverName = ""
        
        if let sender = data["sender"] as? [String: Any],
           let name = sender["name"] as? String {
            senderName = name
        }
        
        // Parse timestamp
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.date(from: timestampString) ?? Date()
        
        return EnhancedChatMessage(
            id: id,
            text: content,
            senderId: senderId,
            senderName: senderName,
            receiverId: receiverId,
            receiverName: receiverName,
            timestamp: timestamp,
            chatRoomId: chatRoomId
        )
    }
    
    // MARK: - Public Methods
    
    /// Join a chat room to receive messages
    /// - Parameter chatRoomId: The ID of the chat room to join
    func joinRoom(chatRoomId: String) {
        socketManager.emit(event: "joinRoom", data: ["chatRoomId": chatRoomId])
        print("📥 Joined chat room: \(chatRoomId)")
    }
    
    /// Leave a chat room
    /// - Parameter chatRoomId: The ID of the chat room to leave
    func leaveRoom(chatRoomId: String) {
        socketManager.emit(event: "leaveRoom", data: ["chatRoomId": chatRoomId])
        print("📤 Left chat room: \(chatRoomId)")
    }
    
    /// Send a message to a chat room
    /// - Parameters:
    ///   - chatRoomId: The ID of the chat room
    ///   - content: The message content
    func sendMessage(chatRoomId: String, content: String) {
        let data: [String: Any] = [
            "chatRoomId": chatRoomId,
            "content": content
        ]
        socketManager.emit(event: "sendMessage", data: data)
        print("📤 Sent message to \(chatRoomId)")
    }
    
    /// Edit a message
    /// - Parameters:
    ///   - messageId: The ID of the message to edit
    ///   - chatRoomId: The ID of the chat room
    ///   - content: The new message content
    func editMessage(messageId: String, chatRoomId: String, content: String) {
        let data: [String: Any] = [
            "messageId": messageId,
            "chatRoomId": chatRoomId,
            "content": content
        ]
        socketManager.emit(event: "editMessage", data: data)
        print("✏️ Edited message: \(messageId)")
    }
    
    /// Delete a message
    /// - Parameters:
    ///   - messageId: The ID of the message to delete
    ///   - chatRoomId: The ID of the chat room
    ///   - hardDelete: Whether to permanently delete the message
    func deleteMessage(messageId: String, chatRoomId: String, hardDelete: Bool = false) {
        let data: [String: Any] = [
            "messageId": messageId,
            "chatRoomId": chatRoomId,
            "hardDelete": hardDelete
        ]
        socketManager.emit(event: "deleteMessage", data: data)
        print("🗑️ Deleted message: \(messageId)")
    }
    
    /// Send typing indicator
    /// - Parameters:
    ///   - chatRoomId: The ID of the chat room
    ///   - isTyping: Whether the user is currently typing
    func sendTypingIndicator(chatRoomId: String, isTyping: Bool) {
        let data: [String: Any] = [
            "chatRoomId": chatRoomId,
            "isTyping": isTyping
        ]
        socketManager.emit(event: "typing", data: data)
    }
    
    // MARK: - Cleanup
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

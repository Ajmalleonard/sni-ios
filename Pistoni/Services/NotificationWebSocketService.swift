import Foundation
import Combine
import SocketIO

/// WebSocket service for notifications
/// Handles realtime notification delivery and unread count updates
class NotificationWebSocketService: ObservableObject {
    // MARK: - Published Properties
    @Published var newNotification: Notification?
    @Published var unreadCount: Int = 0
    @Published var notificationsRead: [String] = [] // Notification IDs marked as read
    
    // MARK: - Private Properties
    private var notificationSocket: SocketIOClient?
    private var notificationManager: SocketManager?
    private let baseURL = "https://api.pistoni.io"
    // private let baseURL = "http://localhost:1111" // Use this for local testing
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Connection Status
    @Published var isConnected: Bool = false
    
    // MARK: - Singleton
    static let shared = NotificationWebSocketService()
    
    private init() {
        print("🔔 NotificationWebSocketService initialized")
    }
    
    // MARK: - Connection Management
    
    /// Connect to the notifications namespace with JWT authentication
    /// - Parameter token: JWT access token
    func connect(token: String, userId: String) {
        guard notificationSocket == nil || notificationSocket?.status != .connected else {
            print("⚠️ Notification socket already connected")
            return
        }
        
        print("🔔 Connecting to notifications WebSocket: \(baseURL)/notifications")
        
        // Configure Socket.IO manager for notifications namespace
        let config: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectAttempts(-1),
            .reconnectWait(1000),
            .forceNew(true),
            .connectParams(["token": token]) // JWT token for authentication
        ]
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            return
        }
        
        notificationManager = SocketManager(socketURL: url, config: config)
        notificationSocket = notificationManager?.socket(forNamespace: "/notifications")
        
        setupEventHandlers()
        notificationSocket?.connect()
        
        // Join notifications room after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.joinNotifications(userId: userId)
        }
    }
    
    /// Disconnect from the notifications WebSocket
    func disconnect(userId: String) {
        print("🔔 Disconnecting from notifications WebSocket")
        leaveNotifications(userId: userId)
        notificationSocket?.disconnect()
        notificationSocket = nil
        notificationManager = nil
        isConnected = false
    }
    
    // MARK: - Event Handlers
    
    private func setupEventHandlers() {
        guard let socket = notificationSocket else { return }
        
        // Connection established
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.isConnected = true
                print("✅ Notifications WebSocket connected")
            }
        }
        
        // Connection error
        socket.on(clientEvent: .error) { data, ack in
            print("❌ Notifications WebSocket error: \(data)")
        }
        
        // Disconnected
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.isConnected = false
                print("🔔 Notifications WebSocket disconnected")
            }
        }
        
        // New notification received
        socket.on("newNotification") { [weak self] data, ack in
            guard let notificationData = data.first as? [String: Any] else { return }
            
            if let notification = self?.parseNotification(from: notificationData) {
                DispatchQueue.main.async {
                    self?.newNotification = notification
                    print("🔔 New notification: \(notification.title)")
                }
            }
        }
        
        // Unread count updated
        socket.on("unreadCountUpdate") { [weak self] data, ack in
            if let count = data.first as? Int {
                DispatchQueue.main.async {
                    self?.unreadCount = count
                    print("🔔 Unread count updated: \(count)")
                }
            }
        }
        
        // Notifications marked as read
        socket.on("notificationsRead") { [weak self] data, ack in
            guard let readData = data.first as? [String: Any],
                  let notificationIds = readData["notificationIds"] as? [String] else { return }
            
            DispatchQueue.main.async {
                self?.notificationsRead = notificationIds
                print("🔔 Notifications marked as read: \(notificationIds.count)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseNotification(from data: [String: Any]) -> Notification? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let body = data["body"] as? String,
              let typeString = data["type"] as? String,
              let isRead = data["isRead"] as? Bool,
              let createdAtString = data["createdAt"] as? String else {
            print("❌ Failed to parse notification data")
            return nil
        }
        
        // Parse notification type
        let type = NotificationType(rawValue: typeString) ?? .system
        
        // Parse timestamp
        let formatter = ISO8601DateFormatter()
        let createdAt = formatter.date(from: createdAtString) ?? Date()
        
        // Parse optional fields
        let relatedEntityId = data["relatedEntityId"] as? String
        let imageUrl = data["imageUrl"] as? String
        let actionUrl = data["actionUrl"] as? String
        
        return Notification(
            id: id,
            userId: userId,
            title: title,
            body: body,
            type: type,
            relatedEntityId: relatedEntityId, isRead: isRead,
            createdAt: createdAt,
            imageUrl: imageUrl,
            actionUrl: actionUrl
        )
    }
    
    // MARK: - Public Methods
    
    /// Join the notifications room for the current user
    /// - Parameter userId: The user's ID
    func joinNotifications(userId: String) {
        guard isConnected else {
            print("⚠️ Cannot join notifications: Not connected")
            return
        }
        
        notificationSocket?.emit("joinNotifications", ["userId": userId])
        print("📥 Joined notifications room for user: \(userId)")
    }
    
    /// Leave the notifications room
    /// - Parameter userId: The user's ID
    func leaveNotifications(userId: String) {
        notificationSocket?.emit("leaveNotifications", ["userId": userId])
        print("📤 Left notifications room for user: \(userId)")
    }
    
    // MARK: - Cleanup
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

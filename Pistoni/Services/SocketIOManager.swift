import Foundation
import Combine
import SocketIO

/// Core WebSocket manager for managing Socket.IO connections
/// Handles authentication, connection lifecycle, and reconnection logic
class SocketIOManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var connectionError: Error?
    
    // MARK: - Private Properties
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var cancellables = Set<AnyCancellable>()
    
    // Base URL for the API
    private let baseURL = "https://api.pistoni.io"
    // private let baseURL = "http://localhost:1111" // Use this for local testing
    
    // MARK: - Singleton
    static let shared = SocketIOManager()
    
    private init() {
        print("🔌 SocketIOManager initialized")
    }
    
    // MARK: - Connection Management
    
    /// Connect to the WebSocket server with JWT authentication
    /// - Parameter token: JWT access token for authentication
    func connect(token: String) {
        guard socket == nil || socket?.status != .connected else {
            print("⚠️ Socket already connected")
            return
        }
        
        print("🔌 Connecting to WebSocket: \(baseURL)")
        
        // Configure Socket.IO manager
        let config: SocketIOClientConfiguration = [
            .log(false), // Set to true for debugging
            .compress,
            .reconnects(true),
            .reconnectAttempts(-1), // Unlimited reconnection attempts
            .reconnectWait(1000), // Wait 1 second between reconnection attempts
            .forceNew(true),
            .connectParams(["token": token]) // JWT token for authentication
        ]
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            return
        }
        
        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.defaultSocket
        
        setupEventHandlers()
        socket?.connect()
    }
    
    /// Disconnect from the WebSocket server
    func disconnect() {
        print("🔌 Disconnecting from WebSocket")
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnected = false
    }
    
    /// Reconnect to the WebSocket server (useful after token refresh)
    /// - Parameter token: New JWT access token
    func reconnect(token: String) {
        disconnect()
        connect(token: token)
    }
    
    // MARK: - Event Handlers
    
    private func setupEventHandlers() {
        guard let socket = socket else { return }
        
        // Connection established
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.connectionError = nil
                print("✅ WebSocket connected successfully")
            }
        }
        
        // Connection failed
        socket.on(clientEvent: .error) { [weak self] data, ack in
            DispatchQueue.main.async {
                if let errorData = data.first as? [String: Any],
                   let message = errorData["message"] as? String {
                    print("❌ WebSocket error: \(message)")
                    self?.connectionError = NSError(domain: "SocketIO", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
                } else {
                    print("❌ WebSocket error: \(data)")
                }
            }
        }
        
        // Disconnected
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.isConnected = false
                print("🔌 WebSocket disconnected: \(data)")
            }
        }
        
        // Reconnection attempt
        socket.on(clientEvent: .reconnect) { data, ack in
            print("🔄 WebSocket reconnecting...")
        }
        
        // Reconnection attempt failed
        socket.on(clientEvent: .reconnectAttempt) { data, ack in
            print("🔄 Reconnection attempt: \(data)")
        }
        
        // Status change
        socket.on(clientEvent: .statusChange) { [weak self] data, ack in
            if let status = data.first as? SocketIOStatus {
                print("📊 WebSocket status changed to: \(status)")
                DispatchQueue.main.async {
                    self?.isConnected = (status == .connected)
                }
            }
        }
    }
    
    // MARK: - Event Listeners
    
    /// Listen for a specific event
    /// - Parameters:
    ///   - event: Event name to listen for
    ///   - callback: Closure to execute when the event is received
    func on(event: String, callback: @escaping ([Any]) -> Void) {
        socket?.on(event) { data, ack in
            callback(data)
        }
    }
    
    /// Remove listener for a specific event
    /// - Parameter event: Event name to stop listening for
    func off(event: String) {
        socket?.off(event)
    }
    
    // MARK: - Event Emitters
    
    /// Emit an event to the server
    /// - Parameters:
    ///   - event: Event name
    ///   - data: Data to send with the event
    func emit(event: String, data: [String: Any]) {
        guard isConnected else {
            print("⚠️ Cannot emit '\(event)': Socket not connected")
            return
        }
        
        print("📤 Emitting event: \(event)")
        socket?.emit(event, data)
    }
    
    /// Emit an event and wait for acknowledgment
    /// - Parameters:
    ///   - event: Event name
    ///   - data: Data to send with the event
    ///   - callback: Closure to execute when acknowledgment is received
    func emitWithAck(event: String, data: [String: Any], callback: @escaping ([Any]) -> Void) {
        guard isConnected else {
            print("⚠️ Cannot emit '\(event)': Socket not connected")
            return
        }
        
        print("📤 Emitting event with ack: \(event)")
        socket?.emitWithAck(event, data).timingOut(after: 5) { ackData in
            callback(ackData)
        }
    }
    
    // MARK: - Utility
    
    /// Get current connection status
    var status: SocketIOStatus {
        return socket?.status ?? .notConnected
    }
    
    /// Check if socket is connected
    var connected: Bool {
        return socket?.status == .connected
    }
}

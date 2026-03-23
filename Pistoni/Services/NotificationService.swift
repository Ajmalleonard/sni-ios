import Foundation
import Combine
import FirebaseFirestore

class NotificationService {
    // Singleton instance
    static let shared = NotificationService()
    
    private lazy var db = Firestore.firestore()
    private let apiBaseURL = "https://api.pistoni.io/v1"
    
    // WebSocket service for realtime notifications
    private let webSocketService = NotificationWebSocketService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Private init for singleton
    private init() {
        print("📦 NotificationService initialized")
    }
    
    // MARK: - WebSocket Initialization
    
    /// Initialize WebSocket connection for realtime notifications
    func connectWebSocket(token: String, userId: String) {
        webSocketService.connect(token: token, userId: userId)
        
        // Subscribe to WebSocket notifications
        webSocketService.$newNotification
            .compactMap { $0 }
            .sink { notification in
                print("🔔 Received realtime notification: \(notification.title)")
                // You can add additional handling here (e.g., play sound, show banner)
            }
            .store(in: &cancellables)
    }
    
    /// Disconnect WebSocket
    func disconnectWebSocket(userId: String) {
        webSocketService.disconnect(userId: userId)
    }
    
    // MARK: - Primary Firebase Methods (with API sync)
    
    /// Fetch notifications for a specific user from Firebase
    func fetchNotificationsFromFirebase(for userId: String) -> AnyPublisher<[Notification], Error> {
        return Future<[Notification], Error> { promise in
            self.db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let notifications = documents.compactMap { Notification(document: $0) }
                    promise(.success(notifications))
                }
        }
        .eraseToAnyPublisher()
    }
    
    /// Listen for real-time notification updates for a specific user from Firebase
    func listenForNotificationsFromFirebase(for userId: String) -> AnyPublisher<[Notification], Error> {
        return Future<[Notification], Error> { promise in
            self.db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .whereField("isRead", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let notifications = documents.compactMap { Notification(document: $0) }
                    promise(.success(notifications))
                }
        }
        .eraseToAnyPublisher()
    }
    
    /// Mark notifications as read in Firebase
    func markAsRead(notificationIds: [String]) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            let batch = self.db.batch()
            
            for id in notificationIds {
                let docRef = self.db.collection("notifications").document(id)
                batch.updateData(["isRead": true], forDocument: docRef)
            }
            
            batch.commit { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Get the count of unread notifications for a user
    func getUnreadCount(for userId: String) -> AnyPublisher<Int, Error> {
        return Future<Int, Error> { promise in
            self.db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .whereField("isRead", isEqualTo: false)
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    let count = snapshot?.documents.count ?? 0
                    promise(.success(count))
                }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Unified Interface
    
    /// Primary method to fetch notifications (uses Firebase with API fallback)
    func fetchNotifications(for userId: String, useAPI: Bool = false) -> AnyPublisher<[Notification], Error> {
        if useAPI {
            // Use API method when explicitly requested
            return fetchNotificationsFromAPI(token: TokenManager.shared.getCurrentAccessToken() ?? "")
                .map { $0.notifications }
                .eraseToAnyPublisher()
        } else {
            // Default to Firebase
             return fetchNotificationsFromFirebase(for: userId)
        }
    }
    
    // MARK: - Backend API Methods (Secondary)
    
    /// Fetch notifications from the backend API
    func fetchNotificationsFromAPI(token: String) -> AnyPublisher<NotificationResponse, Error> {
        guard let url = URL(string: "\(apiBaseURL)/notifications") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NotificationResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    /// Mark notifications as read on the backend API
    func markNotificationsReadOnAPI(token: String, notificationIds: [String]) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(apiBaseURL)/notifications/read") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = MarkNotificationReadRequest(notificationIds: notificationIds)
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    /// Get unread notification count from API
    func getUnreadCountFromAPI(token: String) -> AnyPublisher<Int, Error> {
        guard let url = URL(string: "\(apiBaseURL)/notifications/unread-count") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NotificationCountResponse.self, decoder: JSONDecoder())
            .map { $0.unreadCount }
            .eraseToAnyPublisher()
    }
    
    /// Create a test notification via the API
    func createTestNotification(token: String) -> AnyPublisher<Notification, Error> {
        guard let url = URL(string: "\(apiBaseURL)/notifications/test") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: Notification.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

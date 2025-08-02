import Foundation
import Combine
import FirebaseFirestore

class NotificationService {
    private let db = Firestore.firestore()
    private let notificationsCollection = "notifications"
    
    // MARK: - Firebase Firestore Methods
    
    /// Fetch notifications for a user from Firestore
    func fetchNotifications(for userId: String, limit: Int = 20) -> AnyPublisher<[Notification], Error> {
        return Future<[Notification], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "NotificationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }
            
            self.db.collection(self.notificationsCollection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
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
    
    /// Listen for new notifications in real-time
    func listenForNotifications(for userId: String) -> AnyPublisher<[Notification], Error> {
        let subject = PassthroughSubject<[Notification], Error>()
        
        let listener = db.collection(notificationsCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    subject.send([])
                    return
                }
                
                let notifications = documents.compactMap { Notification(document: $0) }
                subject.send(notifications)
            }
        
        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
    
    /// Get unread notification count
    func getUnreadCount(for userId: String) -> AnyPublisher<Int, Error> {
        return Future<Int, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "NotificationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }
            
            self.db.collection(self.notificationsCollection)
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
    
    /// Mark notifications as read
    func markAsRead(notificationIds: [String]) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "NotificationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }
            
            let batch = self.db.batch()
            
            for id in notificationIds {
                let docRef = self.db.collection(self.notificationsCollection).document(id)
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
    
    // MARK: - Backend API Notifications
    
    /// Fetch notifications from backend API (transpota-app backend)
    func fetchNotificationsFromAPI(token: String, page: Int = 1, limit: Int = 20) -> AnyPublisher<NotificationResponse, Error> {
        guard let url = URL(string: "http://localhost:1010/notifications?page=\(page)&limit=\(limit)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: NotificationResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    /// Mark notifications as read on backend API
    func markNotificationsReadOnAPI(token: String, notificationIds: [String]) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "http://localhost:1010/notifications/mark-read") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = MarkNotificationReadRequest(notificationIds: notificationIds)
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
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
        guard let url = URL(string: "http://localhost:1010/notifications/unread-count") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: NotificationCountResponse.self, decoder: JSONDecoder())
            .map { $0.unreadCount }
            .eraseToAnyPublisher()
    }
    
    /// Create a test notification via API
    func createTestNotification(token: String) -> AnyPublisher<Notification, Error> {
        guard let url = URL(string: "http://localhost:1010/notifications/test") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: Notification.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

// MARK: - NotificationService (uses models from NotificationModels.swift)


import Foundation
import FirebaseFirestore

// MARK: - Notification Models
struct Notification: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let type: NotificationType
    let relatedEntityId: String?
    let isRead: Bool
    let createdAt: Date
    
    // Optional fields
    let imageUrl: String?
    let actionUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, title, body, type, relatedEntityId, isRead, createdAt, imageUrl, actionUrl
    }
    
    init(id: String, userId: String, title: String, body: String, type: NotificationType, 
         relatedEntityId: String? = nil, isRead: Bool = false, createdAt: Date = Date(),
         imageUrl: String? = nil, actionUrl: String? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
        self.type = type
        self.relatedEntityId = relatedEntityId
        self.isRead = isRead
        self.createdAt = createdAt
        self.imageUrl = imageUrl
        self.actionUrl = actionUrl
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let body = data["body"] as? String,
              let typeString = data["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let isRead = data["isRead"] as? Bool,
              let timestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.title = title
        self.body = body
        self.type = type
        self.relatedEntityId = data["relatedEntityId"] as? String
        self.isRead = isRead
        self.createdAt = timestamp.dateValue()
        self.imageUrl = data["imageUrl"] as? String
        self.actionUrl = data["actionUrl"] as? String
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "title": title,
            "body": body,
            "type": type.rawValue,
            "isRead": isRead,
            "createdAt": Timestamp(date: createdAt)
        ]
        
        if let relatedEntityId = relatedEntityId {
            dict["relatedEntityId"] = relatedEntityId
        }
        
        if let imageUrl = imageUrl {
            dict["imageUrl"] = imageUrl
        }
        
        if let actionUrl = actionUrl {
            dict["actionUrl"] = actionUrl
        }
        
        return dict
    }
}

enum NotificationType: String, Codable {
    case chat = "CHAT"
    case rental = "RENTAL"
    case payment = "PAYMENT"
    case system = "SYSTEM"
    case promotion = "PROMOTION"
}

// MARK: - API Request/Response Models
struct NotificationResponse: Codable {
    let notifications: [Notification]
    let total: Int
    let unreadCount: Int
    let page: Int?
    let limit: Int?
    let totalPages: Int?
}

struct MarkNotificationReadRequest: Codable {
    let notificationIds: [String]
}

struct NotificationCountResponse: Codable {
    let unreadCount: Int
} 
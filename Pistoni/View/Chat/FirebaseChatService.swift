import Foundation
import FirebaseFirestore
import Combine

// Service for Firestore-based chat functionality
class FirebaseChatService: ObservableObject {
    private let db = Firestore.firestore()
    private var messageListener: ListenerRegistration?
    
    // Observe messages for a given chat room in real time
    func observeMessages(chatId: String, onUpdate: @escaping ([EnhancedChatMessage]) -> Void) {
        messageListener?.remove() // Clean up previous listener
        messageListener = db.collection("messages")
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    onUpdate([])
                    return
                }
                let messages: [EnhancedChatMessage] = documents.compactMap { document in
                    let data = document.data()
                    guard
                        let text = data["text"] as? String,
                        let senderId = data["senderId"] as? String,
                        let senderName = data["senderName"] as? String,
                        let receiverId = data["receiverId"] as? String,
                        let receiverName = data["receiverName"] as? String,
                        let chatRoomId = data["chatRoomId"] as? String
                    else {
                        return nil
                    }

                    // Handle timestamp which may be Firestore Timestamp or Date
                    var date: Date = Date()
                    if let ts = data["timestamp"] as? Timestamp {
                        date = ts.dateValue()
                    } else if let d = data["timestamp"] as? Date {
                        date = d
                    }

                    return EnhancedChatMessage(
                        id: data["id"] as? String ?? document.documentID,
                        text: text,
                        senderId: senderId,
                        senderName: senderName,
                        receiverId: receiverId,
                        receiverName: receiverName,
                        timestamp: date,
                        chatRoomId: chatRoomId
                    )
                }
                onUpdate(messages)
            }
    }
    
    // Send a message to a chat room
    func sendMessage(text: String, chatId: String, sender: ChatUser) {
        let message = EnhancedChatMessage(
            id: UUID().uuidString,
            text: text,
            senderId: sender.id,
            senderName: sender.name,
            receiverId: "", // To be set if needed
            receiverName: "", // To be set if needed
            timestamp: Date(),
            chatRoomId: chatId
        )
        
        let data: [String: Any] = [
            "id": message.id,
            "text": message.text,
            "senderId": message.senderId,
            "senderName": message.senderName,
            "receiverId": message.receiverId,
            "receiverName": message.receiverName,
            "timestamp": Timestamp(date: message.timestamp),
            "chatRoomId": message.chatRoomId
        ]

        db.collection("messages").document(message.id).setData(data) { error in
            if let error = error {
                print("❌ Error sending message: \(error)")
            }
        }
    }

    // Create or fetch a chat room document for two user IDs
    func getOrCreateChatRoom(user1: ChatUser, user2: ChatUser, completion: @escaping (String?) -> Void) {
        let roomId = EnhancedChatRoom.generateRoomId(user1: user1.id, user2: user2.id)
        let roomRef = db.collection("chats").document(roomId)
        roomRef.getDocument { doc, error in
            if let doc = doc, doc.exists {
                completion(roomId)
                return
            }
            let chatRoomData: [String: Any] = [
                "id": roomId,
                "participants": [user1.id, user2.id],
                "participantNames": [user1.name, user2.name],
                "lastMessage": NSNull(),
                "lastMessageTime": NSNull(),
                "createdAt": Timestamp(date: Date())
            ]

            roomRef.setData(chatRoomData) { error in
                if let error = error {
                    print("❌ Error creating chat room: \(error)")
                    completion(nil)
                } else {
                    completion(roomId)
                }
            }
        }
    }
    
    // Remove the real-time listener when no longer needed
    func removeListener() {
        messageListener?.remove()
        messageListener = nil
    }
}

//
//  ChatScreen.swift
//  SNI Rentals
//
//  Created by Assistant on 25/01/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import Combine
// Define ChatNotificationType directly in this file
import struct Foundation.Date

// Chat Notification Type for use in this file
enum ChatNotificationType {
    case general, support, booking, payment, system
    
    var iconName: String {
        switch self {
        case .general: return "bell.fill"
        case .support: return "questionmark.circle.fill"
        case .booking: return "car.fill"
        case .payment: return "creditcard.fill"
        case .system: return "gear.circle.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .general: return .blue.opacity(0.2)
        case .support: return .orange.opacity(0.2)
        case .booking: return .green.opacity(0.2)
        case .payment: return .purple.opacity(0.2)
        case .system: return .gray.opacity(0.2)
        }
    }
    
    var iconColor: Color {
        switch self {
        case .general: return .blue
        case .support: return .orange
        case .booking: return .green
        case .payment: return .purple
        case .system: return .gray
        }
    }
}

struct ChatScreen: View {
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatManager = ChatManager()
    @State private var selectedTab: ChatTab = .chats
    @State private var messageText = ""
    @State private var selectedChat: ChatConversation?
    @State private var showingNotifications = false
    enum ChatTab {
        case chats, notifications
    }
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar

                
                // Content
                Group {
                    if selectedTab == .chats {
                        ChatsListView(
                            chats: chatManager.conversations,
                            selectedChat: $selectedChat
                        )
                    } else {
                        NotificationsListView(
                            notifications: chatManager.notifications
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
               
                
            
             }
            .onAppear {
                chatManager.startListening()
                chatManager.loadUserData(authModel.currentUser)
            }
            .onDisappear {
                chatManager.stopListening()
            }
            .sheet(item: $selectedChat) { chat in
                ChatDetailView(conversation: chat, chatManager: chatManager)
                    .environmentObject(authModel)
            }
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let unreadCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                if unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                        
                        Text("\(min(unreadCount, 99))")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
            )
        }
    }
}

// MARK: - Chats List View
struct ChatsListView: View {
    let chats: [ChatConversation]
    @Binding var selectedChat: ChatConversation?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if chats.isEmpty {
                    EmptyStateView(
                        icon: "message",
                        title: "No conversations yet",
                        subtitle: "Start a conversation with support or other users"
                    )
                    .padding(.top, 100)
                } else {
                    ForEach(chats) { chat in
                        ChatRowView(conversation: chat) {
                            selectedChat = chat
                        }
                        
                        if chat.id != chats.last?.id {
                            Divider()
                                .padding(.leading, 80)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Notifications List View
struct NotificationsListView: View {
    let notifications: [AppNotification]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell",
                        title: "No notifications",
                        subtitle: "You'll see app updates and important notices here"
                    )
                    .padding(.top, 100)
                } else {
                    ForEach(notifications) { notification in
                        NotificationRowView(notification: notification)
                        
                        if notification.id != notifications.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Chat Row View
struct ChatRowView: View {
    let conversation: ChatConversation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Avatar
                AsyncImage(url: URL(string: conversation.otherUserAvatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            Text(conversation.otherUserName.prefix(1).uppercased())
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.otherUserName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(conversation.lastMessageTime.timeAgoString())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(conversation.lastMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        if conversation.unreadCount > 0 {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.type.backgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.type.iconName)
                    .font(.headline)
                    .foregroundColor(notification.type.iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(notification.timestamp.timeAgoString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 250)
    }
}

// MARK: - Data Models
struct ChatConversation: Identifiable, Hashable {
    let id: String
    let otherUserId: String
    let otherUserName: String
    let otherUserAvatar: String?
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
    let isSupport: Bool
}

struct AppNotification: Identifiable {
    let id: String
    let title: String
    let message: String
    let type: ChatNotificationType
    let timestamp: Date
    let isRead: Bool
    let actionData: [String: Any]?
}


// MARK: - Chat Manager
class ChatManager: ObservableObject {
    @Published var conversations: [ChatConversation] = []
    @Published var notifications: [AppNotification] = []
    @Published var unreadChatsCount: Int = 0
    @Published var unreadNotificationsCount: Int = 0
    
    private var db = Firestore.firestore()
    private var chatListener: ListenerRegistration?
    private var notificationListener: ListenerRegistration?
    private var currentUserId: String?
    
    func loadUserData(_ user: User?) {
        currentUserId = user?.id
        print("💬 ChatManager loaded user: \(user?.displayName ?? "Unknown")")
    }
    
    func startListening() {
        guard let userId = currentUserId else {
            print("❌ No user ID available for chat listening")
            return
        }
        
        print("🎧 Starting to listen for chats and notifications")
        startListeningToChats(userId: userId)
        startListeningToNotifications(userId: userId)
    }
    
    func stopListening() {
        print("🛑 Stopping chat listeners")
        chatListener?.remove()
        notificationListener?.remove()
    }
    
    private func startListeningToChats(userId: String) {
        chatListener = db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to chats: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 No chat documents found")
                    return
                }
                
                self?.conversations = documents.compactMap { doc in
                    self?.parseChatDocument(doc, currentUserId: userId)
                }
                
                self?.unreadChatsCount = self?.conversations.reduce(0) { $0 + $1.unreadCount } ?? 0
                print("💬 Loaded \(self?.conversations.count ?? 0) conversations")
            }
    }
    
    private func startListeningToNotifications(userId: String) {
        notificationListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to notifications: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 No notification documents found")
                    return
                }
                
                self?.notifications = documents.compactMap { doc in
                    self?.parseNotificationDocument(doc)
                }
                
                self?.unreadNotificationsCount = self?.notifications.filter { !$0.isRead }.count ?? 0
                print("🔔 Loaded \(self?.notifications.count ?? 0) notifications")
            }
    }
    
    private func parseChatDocument(_ document: QueryDocumentSnapshot, currentUserId: String) -> ChatConversation? {
        let data = document.data()
        
        guard let participants = data["participants"] as? [String],
              let lastMessage = data["lastMessage"] as? String,
              let lastMessageTimestamp = data["lastMessageTime"] as? Timestamp else {
            return nil
        }
        
        // Find the other participant
        let otherUserId = participants.first { $0 != currentUserId } ?? ""
        let otherUserName = data["otherUserName"] as? String ?? "Unknown User"
        let otherUserAvatar = data["otherUserAvatar"] as? String
        let unreadCount = data["unreadCount_\(currentUserId)"] as? Int ?? 0
        let isSupport = data["isSupport"] as? Bool ?? false
        
        return ChatConversation(
            id: document.documentID,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserAvatar: otherUserAvatar,
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTimestamp.dateValue(),
            unreadCount: unreadCount,
            isSupport: isSupport
        )
    }
    
    private func parseNotificationDocument(_ document: QueryDocumentSnapshot) -> AppNotification? {
        let data = document.data()
        
        guard let title = data["title"] as? String,
              let message = data["message"] as? String,
              let typeString = data["type"] as? String,
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }
        
        let type: ChatNotificationType
        switch typeString {
        case "support": type = .support
        case "booking": type = .booking
        case "payment": type = .payment
        case "system": type = .system
        default: type = .general
        }
        
        let isRead = data["isRead"] as? Bool ?? false
        let actionData = data["actionData"] as? [String: Any]
        
        return AppNotification(
            id: document.documentID,
            title: title,
            message: message,
            type: type,
            timestamp: timestamp.dateValue(),
            isRead: isRead,
            actionData: actionData
        )
    }
    
    func refreshData() {
        print("🔄 Refreshing chat data")
        // The listeners will automatically refresh the data
    }
}

// MARK: - Extensions
extension Date {
    func timeAgoString() -> String {
        let formatter = DateFormatter()
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        }
    }
}

#Preview {
    ChatScreen()
        .environmentObject(AuthModel())
}

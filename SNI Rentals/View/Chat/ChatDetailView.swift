//
//  ChatDetailView.swift
//  SNI Rentals
//
//  Created by Assistant on 25/01/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct ChatDetailView: View {
    let conversation: ChatConversation
    let chatManager: ChatManager
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var messageListener: ListenerRegistration?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if messages.isEmpty && !isLoading {
                                EmptyMessagesView()
                                    .padding(.top, 100)
                            } else {
                                ForEach(messages) { message in
                                    MessageBubbleView(
                                        message: message,
                                        isCurrentUser: message.senderId == authModel.currentUser?.id
                                    )
                                    .id(message.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: messages.count) { _, _ in
                        // Auto-scroll to bottom when new message arrives
                        if let lastMessage = messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message Input
                MessageInputView(
                    messageText: $messageText,
                    isLoading: isLoading,
                    onSend: sendMessage
                )
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(conversation.otherUserName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    AsyncImage(url: URL(string: conversation.otherUserAvatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                Text(conversation.otherUserName.prefix(1).uppercased())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            )
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                }
            }
            .onAppear {
                startListeningToMessages()
                markMessagesAsRead()
            }
            .onDisappear {
                stopListeningToMessages()
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUser = authModel.currentUser else {
            return
        }
        
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        isLoading = true
        
        let messageData: [String: Any] = [
            "text": trimmedMessage,
            "senderId": currentUser.id,
            "senderName": currentUser.displayName,
            "timestamp": FieldValue.serverTimestamp(),
            "chatId": conversation.id,
            "isRead": false
        ]
        
        // Add message to messages collection
        Firestore.firestore().collection("messages").addDocument(data: messageData) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("❌ Error sending message: \(error)")
                } else {
                    messageText = ""
                    updateLastMessage(trimmedMessage)
                }
            }
        }
    }
    
    private func updateLastMessage(_ message: String) {
        let chatUpdate: [String: Any] = [
            "lastMessage": message,
            "lastMessageTime": FieldValue.serverTimestamp(),
            "unreadCount_\(conversation.otherUserId)": FieldValue.increment(Int64(1))
        ]
        
        Firestore.firestore().collection("chats").document(conversation.id)
            .updateData(chatUpdate) { error in
                if let error = error {
                    print("❌ Error updating chat: \(error)")
                } else {
                    print("✅ Chat updated successfully")
                }
            }
    }
    
    private func startListeningToMessages() {
        messageListener = Firestore.firestore().collection("messages")
            .whereField("chatId", isEqualTo: conversation.id)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error listening to messages: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 No messages found")
                    return
                }
                
                messages = documents.compactMap { doc in
                    parseMessageDocument(doc)
                }
                
                print("💬 Loaded \(messages.count) messages for chat \(conversation.id)")
            }
    }
    
    private func stopListeningToMessages() {
        messageListener?.remove()
        messageListener = nil
    }
    
    private func parseMessageDocument(_ document: QueryDocumentSnapshot) -> ChatMessage? {
        let data = document.data()
        
        guard let text = data["text"] as? String,
              let senderId = data["senderId"] as? String,
              let senderName = data["senderName"] as? String else {
            return nil
        }
        
        let timestamp = data["timestamp"] as? Timestamp
        let isRead = data["isRead"] as? Bool ?? false
        
        return ChatMessage(
            id: document.documentID,
            text: text,
            senderId: senderId,
            senderName: senderName,
            timestamp: timestamp?.dateValue() ?? Date(),
            isRead: isRead
        )
    }
    
    private func markMessagesAsRead() {
        guard let currentUserId = authModel.currentUser?.id else { return }
        
        // Mark messages as read for current user
        let chatUpdate = [
            "unreadCount_\(currentUserId)": 0
        ]
        
        Firestore.firestore().collection("chats").document(conversation.id)
            .updateData(chatUpdate) { error in
                if let error = error {
                    print("❌ Error marking messages as read: \(error)")
                } else {
                    print("✅ Messages marked as read")
                }
            }
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isCurrentUser ? Color.blue : Color(.systemGray5))
                    )
                
                Text(message.timestamp.timeAgoString())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Message Input View
struct MessageInputView: View {
    @Binding var messageText: String
    let isLoading: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageText, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...5)
            
            Button(action: onSend) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty Messages View
struct EmptyMessagesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Start the conversation")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Send a message to begin chatting")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 250)
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let senderId: String
    let senderName: String
    let timestamp: Date
    let isRead: Bool
}

#Preview {
    ChatDetailView(
        conversation: ChatConversation(
            id: "preview",
            otherUserId: "user123",
            otherUserName: "John Doe",
            otherUserAvatar: nil,
            lastMessage: "Hello there!",
            lastMessageTime: Date(),
            unreadCount: 2,
            isSupport: false
        ),
        chatManager: ChatManager()
    )
    .environmentObject(AuthModel())
} 

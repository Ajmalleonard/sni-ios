//
//  EnhancedChatView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 12/08/2025.
//

import SwiftUI

struct EnhancedChatView: View {
    @EnvironmentObject var authModel: AuthModel
    @State private var messagesManager: EnhancedMessagesManager?
    @State private var showingUserSelection = false
    @State private var messageText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if let manager = messagesManager {
                if manager.selectedUser != nil {
                    // Chat interface
                    chatInterface(with: manager)
                } else {
                    // User selection prompt
                    userSelectionPrompt(with: manager)
                }
            } else {
                // Loading state
                loadingView
            }
        }
        .onAppear {
            createManagerIfNeeded()
            // Set user online when app appears
            messagesManager?.updateOnlineStatus(isOnline: true)
        }
        .onDisappear {
            // Set user offline when app disappears
            messagesManager?.updateOnlineStatus(isOnline: false)
        }
        .onChange(of: authModel.currentUser) { _, newUser in
            if newUser != nil {
                createManagerIfNeeded()
            }
        }
        .sheet(isPresented: $showingUserSelection) {
            if let manager = messagesManager {
                UserSelectionView(messagesManager: manager) { selectedUser in
                    manager.startChat(with: selectedUser)
                }
            }
        }
    }
    
    private func createManagerIfNeeded() {
        guard let currentUser = authModel.currentUser, messagesManager == nil else { return }
        messagesManager = EnhancedMessagesManager(currentUser: currentUser)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Chat...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func userSelectionPrompt(with manager: EnhancedMessagesManager) -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text("Messages")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        showingUserSelection = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("Secondary"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color("Primary"))
            
            // Empty state
            VStack(spacing: 16) {
                Image(systemName: "message.circle")
                    .font(.system(size: 60))
                    .foregroundColor(Color("Secondary").opacity(0.6))
                
                Text("Start a Conversation")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    Text("To chat with other users:")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    
                    Text("• Create accounts with different emails")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("• Sign in on different devices/simulators")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("• Users will appear automatically")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                
                Button("Find Users") {
                    showingUserSelection = true
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color("Secondary"))
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Set current user as online when chat view appears
            manager.updateOnlineStatus(isOnline: true)
        }
        .onDisappear {
            // Set current user as offline when chat view disappears
            manager.updateOnlineStatus(isOnline: false)
        }
    }
    
    private func chatInterface(with manager: EnhancedMessagesManager) -> some View {
        VStack(spacing: 0) {
            // Chat header
            chatHeader(with: manager)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(manager.messages) { message in
                            EnhancedMessageBubble(
                                message: message,
                                currentUserId: authModel.currentUser?.id ?? ""
                            )
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 16)
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .onChange(of: manager.lastMessageId) { _, id in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
            
            // Message input
            messageInputField(with: manager)
        }
        .background(Color("Primary"))
        .navigationBarHidden(true)
    }
    
    private func chatHeader(with manager: EnhancedMessagesManager) -> some View {
        HStack(spacing: 16) {
            Button {
                manager.selectedUser = nil
                manager.currentChatRoomId = nil
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color("Secondary"))
            }
            
            if let user = manager.selectedUser {
                // User info
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: user.profilePicture ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(user.name.prefix(1).uppercased())
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(user.isOnline ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            Button {
                showingUserSelection = true
            } label: {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.title2)
                    .foregroundColor(Color("Secondary"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private func messageInputField(with manager: EnhancedMessagesManager) -> some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    sendMessage(with: manager)
                }
            
            Button {
                sendMessage(with: manager)
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color("Secondary"))
                    .clipShape(Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    private func sendMessage(with manager: EnhancedMessagesManager) {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        manager.sendMessage(messageText)
        messageText = ""
    }
}

struct EnhancedMessageBubble: View {
    let message: EnhancedChatMessage
    let currentUserId: String
    @State private var showTime = false
    
    private var isFromCurrentUser: Bool {
        message.senderId == currentUserId
    }
    
    var body: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if isFromCurrentUser {
                    Spacer(minLength: 50)
                }
                
                VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                    if !isFromCurrentUser {
                        Text(message.senderName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                    }
                    
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(isFromCurrentUser ? Color("Secondary") : Color.gray.opacity(0.2))
                        .foregroundColor(isFromCurrentUser ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .onTapGesture {
                    showTime.toggle()
                }
                
                if !isFromCurrentUser {
                    Spacer(minLength: 50)
                }
            }
            
            if showTime {
                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: isFromCurrentUser ? .trailing : .leading)
                    .padding(.horizontal, 20)
            } 
        }
        .frame(maxWidth: .infinity, alignment: isFromCurrentUser ? .trailing : .leading)
    }
}

#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return EnhancedChatView()
        .environmentObject(mockAuthModel)
}

//
//  UserSelectionView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 12/08/2025.
//

import SwiftUI

struct UserSelectionView: View {
    @ObservedObject var messagesManager: EnhancedMessagesManager
    @Environment(\.dismiss) private var dismiss
    let onUserSelected: (ChatUser) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // User List
                if $messagesManager.availableUsers.isEmpty {
                    emptyStateView
                } else {
                    userListView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Color("Secondary"))
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Start Chat")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Select a user to chat with")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button("Refresh") {
                    messagesManager.loadAvailableUsers()
                }
                .font(.caption)
                .foregroundColor(Color("Secondary"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color("Primary"))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Other Users Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                Text("To test real-time chat:")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
                
                Text("1. Create another account (different email)")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("2. Sign in on another device/simulator")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("3. Both users will appear here automatically")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            
            Button("Refresh") {
                messagesManager.loadAvailableUsers()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color("Secondary"))
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(messagesManager.availableUsers) { user in
                    UserRowView(user: user) {
                        onUserSelected(user)
                        dismiss()
                    }
                    
                    if user.id != messagesManager.availableUsers.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .background(Color("Primary"))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

struct UserRowView: View {
    let user: ChatUser
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Profile picture
                AsyncImage(url: URL(string: user.profilePicture ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(user.name.prefix(1).uppercased())
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(
                    // Online status indicator
                    Circle()
                        .fill(user.isOnline ? Color.green : Color.gray)
                        .frame(width: 16, height: 16)
                        .offset(x: 18, y: 18)
                )
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(user.isOnline ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        
                        Text(user.isOnline ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    UserSelectionView(
        messagesManager: EnhancedMessagesManager(currentUser: User(
            id: "preview_user",
            email: "preview@test.com",
            name: "Preview User",
            phoneNumber: nil,
            role: .client,
            profilePicture: nil,
            isVerified: true,
            createdAt: Date(),
            authProvider: .email
        )),
        onUserSelected: { _ in }
    )
} 

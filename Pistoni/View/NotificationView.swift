import SwiftUI
import Combine

struct NotificationView: View {
    @EnvironmentObject var authModel: AuthModel
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header with back button and title
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color("Secondary"))
                    }
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("Mark Read")
                            .font(.caption)
                            .foregroundColor(Color("Secondary"))
                        Text("Notifications")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    HStack {
                        // Test API button
                        Button {
                            testAPIConnection()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        // Mark all as read - icon only
                        if !viewModel.notifications.isEmpty {
                            Button {
                                if let userId = authModel.currentUser?.id {
                                    viewModel.markAllAsRead(for: userId)
                                }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                // Main content
                if viewModel.isLoading {
                    CustomLoadingView()
                } else if viewModel.notifications.isEmpty {
                    Spacer()
                    emptyNotificationsView
                    Spacer()
                } else {
                    notificationsList
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let userId = authModel.currentUser?.id {
                viewModel.authModel = authModel
                viewModel.loadNotifications(for: userId)
                viewModel.startNotificationListener(for: userId)
                
                // Add some dummy notifications for testing
                addDummyNotifications(userId: userId)
            }
        }
        .onDisappear {
            viewModel.stopNotificationListener()
        }
    }
    
    private var emptyNotificationsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            Text("No Notifications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You don't have any notifications yet.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private var notificationsList: some View {
        List {
            ForEach(viewModel.notifications) { notification in
                NotificationRow(
                    notification: notification,
                    onMarkAsRead: {
                        viewModel.markAsRead(notificationId: notification.id)
                    },
                    onDelete: {
                        // For now, just mark as read since we don't have delete in the viewModel
                        viewModel.markAsRead(notificationId: notification.id)
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if !notification.isRead {
                        viewModel.markAsRead(notificationId: notification.id)
                    }
                    handleNotificationTap(notification)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        .refreshable {
            if let userId = authModel.currentUser?.id {
                viewModel.loadNotifications(for: userId)
            }
        }
    }
    
    private func handleNotificationTap(_ notification: Notification) {
        // Handle different notification types
        switch notification.type {
        case .chat:
            // Navigate to chat if there's a related entity ID
            if let chatId = notification.relatedEntityId {
                print("Navigate to chat: \(chatId)")
                // Navigation would happen here
            }
        case .rental:
            // Navigate to rental details
            if let rentalId = notification.relatedEntityId {
                print("Navigate to rental: \(rentalId)")
                // Navigation would happen here
            }
        case .payment:
            // Navigate to payment details
            if let paymentId = notification.relatedEntityId {
                print("Navigate to payment: \(paymentId)")
                // Navigation would happen here
            }
        case .system, .promotion:
            // Just mark as read, no navigation needed
            break
        }
    }
    
    private func addDummyNotifications(userId: String) {
        // Add some dummy notifications for testing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let dummyNotifications = [
                Notification(
                    id: UUID().uuidString,
                    userId: userId,
                    title: "Welcome to SNI Rentals!",
                    body: "Thank you for joining our car rental platform. Start exploring available cars near you.",
                    type: .system,
                    isRead: false,
                    createdAt: Date().addingTimeInterval(-3600) // 1 hour ago
                ),
                Notification(
                    id: UUID().uuidString,
                    userId: userId,
                    title: "New Message",
                    body: "You have a new message from John about your Tesla Model 3 rental.",
                    type: .chat,
                    relatedEntityId: "chat_123",
                    isRead: false,
                    createdAt: Date().addingTimeInterval(-1800) // 30 minutes ago
                ),
                Notification(
                    id: UUID().uuidString,
                    userId: userId,
                    title: "Rental Confirmed",
                    body: "Your BMW X5 rental has been confirmed for tomorrow 9:00 AM.",
                    type: .rental,
                    relatedEntityId: "rental_456",
                    isRead: true,
                    createdAt: Date().addingTimeInterval(-900) // 15 minutes ago
                ),
                Notification(
                    id: UUID().uuidString,
                    userId: userId,
                    title: "Payment Processed",
                    body: "Your payment of $150.00 has been successfully processed.",
                    type: .payment,
                    relatedEntityId: "payment_789",
                    isRead: false,
                    createdAt: Date().addingTimeInterval(-300) // 5 minutes ago
                ),
                Notification(
                    id: UUID().uuidString,
                    userId: userId,
                    title: "Special Offer!",
                    body: "Get 20% off your next rental. Use code SAVE20 at checkout.",
                    type: .promotion,
                    isRead: false,
                    createdAt: Date().addingTimeInterval(-60) // 1 minute ago
                )
            ]
            
            // Add to viewModel notifications
            viewModel.notifications = dummyNotifications.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    private func testAPIConnection() {
        print("🧪 Testing API connection...")
        
        // For now, we'll use a dummy token since auth is disabled
        let dummyToken = "test-token"
        
        let notificationService = NotificationService()
        notificationService.createTestNotification(token: dummyToken)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ API test notification created successfully")
                    case .failure(let error):
                        print("❌ API test failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { notification in
                    print("📱 Received notification from API: \(notification.title)")
                    
                    // Add the API notification to our list
                    viewModel.notifications.insert(notification, at: 0)
                    viewModel.notifications = viewModel.notifications.sorted { $0.createdAt > $1.createdAt }
                }
            )
            .store(in: &cancellables)
    }
}

struct NotificationRow: View {
    let notification: Notification
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var showingReadButton = false
    @State private var showingDeleteButton = false
    
    var body: some View {
                ZStack {
            // Background actions
            HStack {
                // Delete button (appears when swiping right)
                if showingDeleteButton && dragOffset > 0 {
                    Button(action: {
                        withAnimation(.spring()) {
                            onDelete()
                            resetSwipe()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                        .frame(width: 20, height: 20)
                        .background(Color.red)
                        .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Mark as read button (appears when swiping left)
                if showingReadButton && dragOffset < 0 && !notification.isRead {
                    Button(action: {
                        withAnimation(.spring()) {
                            onMarkAsRead()
                            resetSwipe()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                        .frame(width: 20, height: 20)
                        .background(Color.green)
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Main notification content
            HStack(alignment: .top, spacing: 12) {
                // Icon
                notificationIcon
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(notification.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Message
                    Text(notification.body)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Time
                    Text(timeAgo(from: notification.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                // Unread indicator and swipe hint
                VStack {
                    if !notification.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                    
                    // Swipe hint
                    if !showingReadButton && !showingDeleteButton {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.red.opacity(0.6))
                            Image(systemName: "chevron.left")
                                .font(.caption2)
                                .foregroundColor(.green.opacity(notification.isRead ? 0.3 : 0.6))
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(notification.isRead ? Color(.systemBackground) : Color(.systemBlue).opacity(0.05))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .offset(x: dragOffset)
            .animation(.interactiveSpring(), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.width
                        
                        if translation < 0 {
                            // Left swipe - show read button
                            dragOffset = max(translation, -140)
                            showingReadButton = abs(translation) > 30
                            showingDeleteButton = false
                        } else if translation > 0 {
                            // Right swipe - show delete button
                            dragOffset = min(translation, 140)
                            showingDeleteButton = translation > 30
                            showingReadButton = false
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.width
                        
                        withAnimation(.spring()) {
                            if translation < -100 && !notification.isRead {
                                // Auto-perform mark as read
                                onMarkAsRead()
                                resetSwipe()
                            } else if translation > 100 {
                                // Auto-perform delete
                                onDelete()
                                resetSwipe()
                            } else if abs(translation) > 50 {
                                // Show action button
                                if translation < 0 {
                                    dragOffset = -140
                                    showingReadButton = !notification.isRead
                                } else {
                                    dragOffset = 140
                                    showingDeleteButton = true
                                }
                            } else {
                                // Snap back
                                resetSwipe()
                            }
                        }
                    }
            )
            .onTapGesture {
                if showingReadButton || showingDeleteButton {
                    // Hide action buttons
                    withAnimation(.spring()) {
                        resetSwipe()
                    }
                } else {
                    // Handle notification tap
                    if !notification.isRead {
                        onMarkAsRead()
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
    
    private func resetSwipe() {
        dragOffset = 0
        showingReadButton = false
        showingDeleteButton = false
    }
    
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
            
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private var iconName: String {
        switch notification.type {
        case .chat:
            return "message.fill"
        case .rental:
            return "car.fill"
        case .payment:
            return "creditcard.fill"
        case .system:
            return "bell.fill"
        case .promotion:
            return "tag.fill"
        }
    }
    
    private var iconBackgroundColor: Color {
        switch notification.type {
        case .chat:
            return .blue
        case .rental:
            return .green
        case .payment:
            return .purple
        case .system:
            return .gray
        case .promotion:
            return .orange
        }
    }
}

// MARK: - Helper Functions
private func timeAgo(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

#Preview {
    NotificationView()
        .environmentObject(AuthModel())
} 

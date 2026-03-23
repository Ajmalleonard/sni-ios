import SwiftUI
import Combine

struct NotificationView: View {
    @EnvironmentObject var authModel: AuthModel
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var cancellables = Set<AnyCancellable>()
    @State private var selectedFilter: NotificationFilter = .all
    
    enum NotificationFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case unread = "Unread"
        case system = "System"
        case chat = "Messages"
        case promotion = "Promotions"
        
        var id: String { rawValue }
    }
    
    var filteredNotifications: [Notification] {
        switch selectedFilter {
        case .all:
            return viewModel.notifications
        case .unread:
            return viewModel.notifications.filter { !$0.isRead }
        case .system:
            return viewModel.notifications.filter { $0.type == .system }
        case .chat:
            return viewModel.notifications.filter { $0.type == .chat }
        case .promotion:
            return viewModel.notifications.filter { $0.type == .promotion }
        }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                headerView
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                // Filter Bar
                filterBar
                    .padding(.bottom, 24)
                
                // Main Content
                if viewModel.isLoading {
                    Spacer()
                    CustomLoadingView()
                    Spacer()
                } else if filteredNotifications.isEmpty {
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
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            
            Text("Notifications")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Spacer()
            
            // Hidden button to balance the layout
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NotificationFilter.allCases) { filter in
                    Button {
                        withAnimation {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? Color(hex: "064E3B") : Color.white)
                            )
                            .foregroundColor(selectedFilter == filter ? .white : .black)
                            .overlay(
                                Capsule()
                                    .stroke(Color.gray.opacity(0.1), lineWidth: selectedFilter == filter ? 0 : 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 5)
        }
    }
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredNotifications) { notification in
                    NotificationCard(notification: notification)
                        .onTapGesture {
                            if !notification.isRead {
                                viewModel.markAsRead(notificationId: notification.id)
                            }
                            handleNotificationTap(notification)
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private var emptyNotificationsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("No Notifications")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("You don't have any notifications in this category yet.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleNotificationTap(_ notification: Notification) {
        // Handle different notification types
        switch notification.type {
        case .chat:
            if let chatId = notification.relatedEntityId {
                print("Navigate to chat: \(chatId)")
            }
        case .rental:
            if let rentalId = notification.relatedEntityId {
                print("Navigate to rental: \(rentalId)")
            }
        case .payment:
            if let paymentId = notification.relatedEntityId {
                print("Navigate to payment: \(paymentId)")
            }
        case .system, .promotion:
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
        
        let dummyToken = "test-token"
        
        let notificationService = NotificationService.shared
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
                    viewModel.notifications.insert(notification, at: 0)
                    viewModel.notifications = viewModel.notifications.sorted { $0.createdAt > $1.createdAt }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Notification Card View
struct NotificationCard: View {
    let notification: Notification
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconBackgroundColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Right Side Info
            VStack(alignment: .trailing, spacing: 4) {
                // Time
                Text(timeAgo(from: notification.createdAt))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(timeColor)
                
                // Date
                Text(formatDate(notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.all, 16)
        .background(Color.white)
        .cornerRadius(0)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    // Helpers
    private var iconName: String {
        switch notification.type {
        case .chat: return "message.fill"
        case .rental: return "car.fill"
        case .payment: return "creditcard.fill"
        case .system: return "bell.fill"
        case .promotion: return "tag.fill"
        }
    }
    
    private var iconBackgroundColor: Color {
        switch notification.type {
        case .chat: return Color.blue
        case .rental: return Color(hex: "064E3B") // Dark Green
        case .payment: return Color.orange
        case .system: return Color.purple
        case .promotion: return Color.red
        }
    }
    
    private var timeColor: Color {
        // Use green for recent/unread, black otherwise
        return !notification.isRead ? Color(hex: "10B981") : Color.black
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    NotificationView()
        .environmentObject(AuthModel())
}

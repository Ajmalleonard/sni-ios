import SwiftUI

struct NotificationButton: View {
    @ObservedObject var viewModel: NotificationViewModel
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .overlay(
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    )
                
                // Badge for unread notifications
                if viewModel.unreadCount > 0 {
                    Text("\(min(viewModel.unreadCount, 99))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.red))
                        .offset(x: 4, y: -4)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3), value: viewModel.unreadCount)
                }
            }
        }
        .accessibilityLabel("Notifications")
        .accessibilityHint("View your notifications")
        .onAppear {
            if let userId = viewModel.authModel?.currentUser?.id {
                viewModel.refreshUnreadCount(for: userId)
                viewModel.startNotificationListener(for: userId)
            }
        }
        .onDisappear {
            viewModel.stopNotificationListener()
        }
    }
}

// No need for extension here since the property is already defined in the ViewModel

#Preview {
    NotificationButton(
        viewModel: NotificationViewModel(),
        action: {
            print("Notification button tapped")
        }
    )
} 
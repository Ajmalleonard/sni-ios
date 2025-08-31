import Foundation
import Combine
import FirebaseFirestore

class NotificationViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var authModel: AuthModel?
    
    private let notificationService = NotificationService()
    private var cancellables = Set<AnyCancellable>()
    private var notificationListener: AnyCancellable?
    
    // MARK: - Public Methods
    
    /// Load notifications for a user
    func loadNotifications(for userId: String) {
        isLoading = true
        errorMessage = nil
        
        // Try to load from backend API first
        if let token = authModel?.accessToken {
            notificationService.fetchNotificationsFromAPI(token: token)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                        if case .failure(_) = completion {
                            // Fallback to Firebase if API fails
                            self?.loadNotificationsFromFirebase(for: userId)
                        }
                    },
                    receiveValue: { [weak self] (response: NotificationResponse) in
                        self?.isLoading = false
                        self?.notifications = response.notifications
                        self?.unreadCount = response.unreadCount
                    }
                )
                .store(in: &cancellables)
        } else {
            // No token, use Firebase
            loadNotificationsFromFirebase(for: userId)
        }
    }

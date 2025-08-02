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
    
    private func loadNotificationsFromFirebase(for userId: String) {
        notificationService.fetchNotifications(for: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] notifications in
                    self?.notifications = notifications
                    self?.updateUnreadCount()
                }
            )
            .store(in: &cancellables)
    }
    
    /// Start listening for new notifications
    func startNotificationListener(for userId: String) {
        stopNotificationListener()
        
        notificationListener = notificationService.listenForNotifications(for: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] newNotifications in
                    // Only add notifications that don't already exist in our list
                    let existingIds = Set((self?.notifications ?? []).map { $0.id })
                    let uniqueNewNotifications = newNotifications.filter { !existingIds.contains($0.id) }
                    
                    if !uniqueNewNotifications.isEmpty {
                        self?.notifications.insert(contentsOf: uniqueNewNotifications, at: 0)
                        self?.updateUnreadCount()
                    }
                }
            )
    }
    
    /// Stop listening for notifications
    func stopNotificationListener() {
        notificationListener?.cancel()
        notificationListener = nil
    }
    
    /// Mark a notification as read
    func markAsRead(notificationId: String) {
        guard let index = notifications.firstIndex(where: { $0.id == notificationId }) else { return }
        
        // Optimistically update the UI
        var updatedNotification = notifications[index]
        if !updatedNotification.isRead {
            // Create a new notification with isRead set to true
            let newNotification = Notification(
                id: updatedNotification.id,
                userId: updatedNotification.userId,
                title: updatedNotification.title,
                body: updatedNotification.body,
                type: updatedNotification.type,
                relatedEntityId: updatedNotification.relatedEntityId,
                isRead: true,
                createdAt: updatedNotification.createdAt,
                imageUrl: updatedNotification.imageUrl,
                actionUrl: updatedNotification.actionUrl
            )
            
            notifications[index] = newNotification
            updateUnreadCount()
            
            // Try to update via backend API first
            if let token = authModel?.accessToken {
                notificationService.markNotificationsReadOnAPI(token: token, notificationIds: [notificationId])
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { [weak self] completion in
                            if case .failure(_) = completion {
                                // Fallback to Firebase
                                self?.markAsReadInFirebase([notificationId], originalNotification: updatedNotification, index: index)
                            }
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            } else {
                // Use Firebase
                markAsReadInFirebase([notificationId], originalNotification: updatedNotification, index: index)
            }
        }
    }
    
    private func markAsReadInFirebase(_ notificationIds: [String], originalNotification: Notification, index: Int) {
        notificationService.markAsRead(notificationIds: notificationIds)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        // Revert the optimistic update on error
                        self?.notifications[index] = originalNotification
                        self?.updateUnreadCount()
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    /// Mark all notifications as read
    func markAllAsRead(for userId: String) {
        let unreadIds = notifications
            .filter { !$0.isRead && $0.userId == userId }
            .map { $0.id }
        
        if unreadIds.isEmpty { return }
        
        // Optimistically update the UI
        for i in 0..<notifications.count {
            if !notifications[i].isRead && notifications[i].userId == userId {
                // Create a new notification with isRead set to true
                let updatedNotification = Notification(
                    id: notifications[i].id,
                    userId: notifications[i].userId,
                    title: notifications[i].title,
                    body: notifications[i].body,
                    type: notifications[i].type,
                    relatedEntityId: notifications[i].relatedEntityId,
                    isRead: true,
                    createdAt: notifications[i].createdAt,
                    imageUrl: notifications[i].imageUrl,
                    actionUrl: notifications[i].actionUrl
                )
                notifications[i] = updatedNotification
            }
        }
        
        updateUnreadCount()
        
        // Update in Firestore
        notificationService.markAsRead(notificationIds: unreadIds)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        // We should reload notifications to get the correct state
                        self?.loadNotifications(for: userId)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    /// Refresh unread count
    func refreshUnreadCount(for userId: String) {
        notificationService.getUnreadCount(for: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] count in
                    self?.unreadCount = count
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    deinit {
        stopNotificationListener()
        cancellables.removeAll()
    }
} 
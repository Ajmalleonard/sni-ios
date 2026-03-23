//
//  SNI_RentalsApp.swift
//  SNI Rentals
//
//  Created by Jesus on 7/4/25.
//

import SwiftUI
import Firebase
import GoogleSignIn
import GoogleMaps
import FirebaseAuth

@main
struct SNI_RentalsApp: App {
    @StateObject private var authModel = AuthModel()
    @Environment(\.scenePhase) private var scenePhase
    
    // WebSocket managers
    private let socketManager = SocketIOManager.shared
    private let chatService = ChatWebSocketService.shared
    
    init() {
        // Skip heavy initialization in preview mode
//        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
//
//        }
        setupProductionServices()
    }
    
   
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authModel)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
                .onAppear {
                    setupWebSocketConnection()
                }
        }
    }
    
    
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        // This will be handled by individual chat managers
        // but we can add global app state management here if needed
        switch phase {
        case .active:
            print("📱 App became active")
            // Reconnect WebSocket if user is authenticated
            setupWebSocketConnection()
        case .inactive:
            print("📱 App became inactive")
        case .background:
            print("📱 App went to background")
            // Keep WebSocket connected in background for notifications
        @unknown default:
            break
        }
    }
    
    
    private func setupWebSocketConnection() {
        // Only connect if user is authenticated
        guard let user = authModel.currentUser,
              let token = TokenManager.shared.getCurrentAccessToken() else {
            print("⚠️ User not authenticated, skipping WebSocket connection")
            return
        }
        
        print("🔌 Setting up WebSocket connections for user: \(user.id)")
        
        // Connect main socket for chat
        if !socketManager.connected {
            socketManager.connect(token: token)
        }
        
        // Connect notification socket using singleton
        NotificationService.shared.connectWebSocket(token: token, userId: user.id)
    }
    
    private func setupProductionServices() {
        FirebaseApp.configure()
        
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("GoogleService-Info.plist file not found or CLIENT_ID not found")
        }
        
        let gidConfig = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = gidConfig
        
        // Configure Google Maps
        GoogleMapsConfiguration.configure()
    }
}

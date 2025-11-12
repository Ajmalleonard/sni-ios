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
        }
    }
    
    
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        // This will be handled by individual chat managers
        // but we can add global app state management here if needed
        switch phase {
        case .active:
            print("📱 App became active")
        case .inactive:
            print("📱 App became inactive")
        case .background:
            print("📱 App went to background")
        @unknown default:
            break
        }
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

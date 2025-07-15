//
//  SNI_RentalsApp.swift
//  SNI Rentals
//
//  Created by Jesus on 7/4/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@main
struct SNI_RentalsApp: App {
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("GoogleService-Info.plist file not found or CLIENT_ID missing")
        }
        
        // GIDConfiguration initializer doesn't return optional, so no need for guard let
        let gidConfig = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = gidConfig
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct AppRootView: View {
    @StateObject private var authModel = AuthModel()
    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var showAuthChoice = false
    
    private var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    var body: some View {
        Group {
            if authModel.currentUser != nil {
                // User is logged in - show main app
                HomeView()
                    .environmentObject(authModel)
            } else if showSplash {
                // Show splash screen
                SplashScreen {
                    showSplash = false
                    if hasSeenOnboarding {
                        showAuthChoice = true
                    } else {
                        showOnboarding = true
                    }
                }
            } else if showOnboarding {
                // Show onboarding for new users
                OnboardingView {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    showOnboarding = false
                    showAuthChoice = true
                }
            } else if showAuthChoice {
                // Show auth choice screen
                AuthChoiceView(
                    onRegisterTapped: {
                        // Navigation handled within RegisterView
                    },
                    onLoginTapped: {
                        // Navigation handled within LoginView
                    }
                )
                .environmentObject(authModel)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: authModel.currentUser?.id)
    }
}

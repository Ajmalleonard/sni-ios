import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authModel: AuthModel
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

#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return ContentView()
        .environmentObject(mockAuthModel)
}


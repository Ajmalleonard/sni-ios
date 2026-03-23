import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authModel: AuthModel
    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var showAuthChoice = false


    
    let config = LocationPermissionViewConfig(appName: "Pistoni")
    @State private var showAccessRequest: Bool = false
    
    private var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    var body: some View {
        Group {
            if authModel.currentUser != nil {
                // User is logged in - show main app with tab navigation
                Bbar()
            } else if showSplash {
                // Show splash screen
                SplashScreen {
                    showSplash = false
                    if hasSeenOnboarding {
                        showAuthChoice = true
                        showAccessRequest = true
                    } else {
                        showOnboarding = true
                    }
                }
            } else if showOnboarding {
                //  Show onboarding for new users
                OnboardingView {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    showOnboarding = false
                    showAuthChoice = true
                    showAccessRequest = true
                }
            } else if showAuthChoice {
                // Show auth choice screen
                AuthChoiceView()
                .environmentObject(authModel)
            }
        }
        .locationPermissionFullScreenCover(isPresented: $showAccessRequest, config: config) {
            
        } authorizationDidChange: { status in
            print(status)
        } askLater: {
            print("Ask Later")
        }
        .animation(.easeInOut(duration: 0.2), value: authModel.currentUser?.id)
    }
    
    
    
    
    
    

    
    
    
}
    


// MARK: - App Tab Enum







#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return ContentView()
        .environmentObject(mockAuthModel)
}


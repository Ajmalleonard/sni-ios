import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authModel: AuthModel
    @State private var showSplash = true
    @State private var showOnboarding = false
    @State private var showAuthChoice = false
    @State private var selectedTab: AppTab = .home
    @State private var searchText : String = ""
    
    private var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    var body: some View {
        Group {
                        if authModel.currentUser == nil {
             // User is logged in - show main app with tab navigation
            mainAppView()
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
    
    @ViewBuilder
    func mainAppView(_ safeAreaBottomPadding: CGFloat = 0) -> some View {
        TabView{
            Tab.init("Home", systemImage: AppTab.home.icon){
                NavigationStack{
                    HomeView()
                        .navigationDestination(for: Car.self) { car in
                            CarDetailView(car: car)
                        }
                }
                .navigationTitle("Home")
                .safeAreaPadding(.bottom,safeAreaBottomPadding)
            }
            Tab.init("Explore", systemImage: AppTab.explore.icon){
                NavigationStack{
                    SearchView()
                }.navigationTitle("Explore")
                    .safeAreaPadding(.bottom,safeAreaBottomPadding)
            }
            
            Tab.init("Profile", systemImage: AppTab.profile.icon){
                NavigationStack{
                    ProfileView()
                }.navigationTitle("Profile")
                    .safeAreaPadding(.bottom,safeAreaBottomPadding)
            }
            Tab.init("Search", systemImage: AppTab.search.icon, role: .search){
                NavigationStack{
                    PageSearchScreen(searchText: $searchText)
                }.navigationTitle("Search")
                    .searchable(text: $searchText)
                 .safeAreaPadding(.bottom,safeAreaBottomPadding)
            }
        }.accentColor(.red).background(.white)
            .environmentObject(authModel)
    }
    
    
    
}
    


// MARK: - App Tab Enum
enum AppTab: String, CaseIterable {
    case home = "Home"
    case explore = "Explore"

    case profile = "Profile"
    case search = "Search"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "map.fill"
     
        case .profile: return "person.circle"
        case .search: return "magnifyingglass"
        }
    }
}






#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return ContentView()
        .environmentObject(mockAuthModel)
}

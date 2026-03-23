import SwiftUI

struct Bbar: View {
    @EnvironmentObject var authModel: AuthModel
    var safeAreaBottomPadding: CGFloat = 0
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: AppTab.home.icon) {
                NavigationStack {
                    HomeView()
                        .navigationDestination(for: Car.self) { car in
                            CarDetailView(car: car)
                        }
                }
                .navigationTitle("Home")
                .safeAreaPadding(.bottom, safeAreaBottomPadding)
            }
            
            Tab("Explore", systemImage: AppTab.explore.icon) {
                NavigationStack {
                    SearchView()
                }
                .navigationTitle("Explore")
                .safeAreaPadding(.bottom, safeAreaBottomPadding)
            }
            
            Tab("Profile", systemImage: AppTab.profile.icon) {
                NavigationStack {
                    ProfileView()
                }
                .navigationTitle("Profile")
                .safeAreaPadding(.bottom, safeAreaBottomPadding)
            }
            

        }
        .accentColor(.blue)
        .background(.white)
        .environmentObject(authModel)
    }
}

// MARK: - App Tab Enum
enum AppTab: String, CaseIterable {
    case home = "Home"
    case explore = "Explore"
    case profile = "Profile"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "map.fill"
        case .profile: return "person.circle"
        }
    }
}

#Preview {
    Bbar()
        .environmentObject(AuthModel())
}

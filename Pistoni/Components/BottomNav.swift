//
//  BottomNav.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 27/08/2025.
//
import SwiftUI


// MARK: - Bottom Navigation Bar (Simplified)
struct BottomNavigationBar: View {
    @Binding var selectedTab: HomeTab
    
    var body: some View {
        HStack {
            ForEach(HomeTab.allCases, id: \.rawValue) { tab in
                Spacer()
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(tabIcon(for: tab))
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20,height:20)
                            .foregroundColor(selectedTab == tab ? Color("Secondary") : .gray)
                        
                        Text(tabTitle(for: tab))
                            .font(.caption2)
                            .foregroundColor(selectedTab == tab ? Color("Secondary") : .gray)
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 0)
        .padding(.bottom,10)
        .background(.white)
            .compositingGroup()
            .foregroundColor(.primary)
       
    }
    
    // MARK: - Helper Functions
    private func tabIcon(for tab: HomeTab) -> String {
        switch tab {
        case .home:
            return selectedTab == tab ? "home-active" : "home"
        case .chat:
            return selectedTab == tab ?"message-active": "message"
        case .profile:
            return selectedTab == tab ? "person-active" : "person"
        case .explore :
            return selectedTab == tab ?  "explore-active":"explore"
        
        }

    }
    
    private func tabTitle(for tab: HomeTab) -> String {
        switch tab {
        case .home:
            return "Home"
        case .chat:
            return "Chat"
        case .profile:
            return "Profile"
        case .explore: return "Explore"
        
        }
    
    }
}

//
//  QuickAction.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 12/08/2025.
//

import SwiftUI

struct QuickAction: View {
    @Binding var showScheduleTrip : Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 25)
            
            VStack(spacing: 0) {
                QuickActionItem(
                    icon: "calendar.badge.plus",
                    title: "Schedule a Trip",
                    subtitle: "Plan your next rental",
                    actionType: .trigger {
                        showScheduleTrip = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                QuickActionItem(
                    icon: "map",
                    title: "Find Nearby Cars",
                    subtitle: "Discover cars around you",
                    actionType: .navigation(AnyView(SearchView()))
                )
                
                Divider()
                    .padding(.leading, 60)
                
                QuickActionItem(
                    icon: "heart",
                    title: "My Favorites",
                    subtitle: "View saved vehicles",
                    actionType: .trigger {
                        // Handle favorites
                    }
                )
            }
            .background(Color("Primary"))
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
}

// MARK: - Quick Action Item (ProfileView Style)
struct QuickActionItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionType: QuickActionType
    
    var body: some View {
        Group {
            switch actionType {
            case .navigation(let destination):
                NavigationLink(destination: destination) {
                    quickActionContent
                }
                .buttonStyle(PlainButtonStyle())
                
            case .trigger(let action):
                Button(action: action) {
                    quickActionContent
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var quickActionContent: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color("Secondary"))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Quick Action Type Enum
enum QuickActionType {
    case navigation(AnyView)
    case trigger(() -> Void)
}



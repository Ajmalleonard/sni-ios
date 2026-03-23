//
//  HomeHeaderView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 20/09/2025.
//

import SwiftUI

struct HomeHeaderView: View {
    @EnvironmentObject var authModel: AuthModel
    @Binding var showSearch: Bool
    @Binding var showNotifications: Bool
    let hasNotifications: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
               
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Search Button
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showSearch = true
                        }
                    } label: {
                        Image("search")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color("AppSecondary"))
                            .frame(width: 20, height: 20)
                            .padding(12)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    // Notification Button
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showNotifications = true
                        }
                    } label: {
                        ZStack {
                            Image("notify")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color("AppSecondary"))
                                .frame(width: 20, height: 20)
                                .padding(12)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                            
                            // Notification Badge
                            if hasNotifications {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -12)
                                    .shadow(color: .white, radius: 1)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
}

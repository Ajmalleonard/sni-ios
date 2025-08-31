import SwiftUI
import UIKit

// Define the three stages of the bottom sheet
enum BottomSheetStage {
    case collapsed   // Just search bar
    case quickActions // Search bar + quick actions
    case history     // Search bar + quick actions + history
}

struct SearchBottomSheet: View {
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @State private var currentStage: BottomSheetStage = .collapsed
    @GestureState private var gestureOffset: CGFloat = 0
    
    @Binding var navigationPath: NavigationPath
    @Binding var showingSearchScreen: Bool
    var onProfileTap: () -> Void
    
    // Haptic feedback generator
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    private let maxHeight: CGFloat = UIScreen.main.bounds.height - 100
    private let minHeight: CGFloat = 100
    private let quickActionsHeight: CGFloat = 220 // Height for quick actions stage
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag Indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue.opacity(0.4))
                    .frame(width: 60, height: 6)
                    .padding(.top, 10)
                
                // Search Bar and Profile
                HStack(spacing: 15) {
                    // Search Button
                    Button {
                        showingSearchScreen = true
                    } label: {
                        HStack {
                            Image("search")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 36,height: 36)
                                .foregroundColor(.blue)
                            Text("Search Destination")
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(.blue.opacity(0.3))
                        .clipShape(Capsule())
                    }
                    
                    // Profile Button
                    Button(action: onProfileTap) {
                        Image("user_1")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 36,height: 36)
                            .foregroundColor(.blue)
                            .padding()
                            .background(.blue.opacity(0.3))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Quick Actions - visible in quickActions and history stages
                if currentStage == .quickActions || currentStage == .history {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            QuickActionButton(icon: "house.fill", text: "Home")
                            QuickActionButton(icon: "car.fill", text: "Rides")
                            QuickActionButton(icon: "clock.fill", text: "Recent")
                            QuickActionButton(icon: "exclamationmark.triangle.fill", text: "Help")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    .transition(.opacity)
                }
                
                // Recent Routes - only visible in history stage
                if currentStage == .history {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Recent Routes")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 5)
                        
                        VStack(spacing: 15) {
                            RecentRouteItem(title: "8 Sinza")
                            RecentRouteItem(title: "Magomeni, kanisani")
                            RecentRouteItem(title: "Kariakoo, Lumumba")
                            RecentRouteItem(title: "Kariakoo, Lumumba")
                        }
                        .padding(.horizontal)
                    }
                    .transition(.opacity)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 50))
            .shadow(color: .black.opacity(0.1), radius: 10)
            .offset(y: max(offset + gestureOffset, 0))
            .gesture(
                DragGesture()
                    .updating($gestureOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let height = value.translation.height
                        
                        // Determine the next stage based on current stage and swipe direction
                        var nextStage = currentStage
                        
                        if height > 50 { // Swipe down
                            switch currentStage {
                            case .collapsed:
                                // Already at the bottom, do nothing
                                break
                            case .quickActions:
                                nextStage = .collapsed
                            case .history:
                                nextStage = .quickActions
                            }
                        } else if -height > 50 { // Swipe up
                            switch currentStage {
                            case .collapsed:
                                nextStage = .quickActions
                            case .quickActions:
                                nextStage = .history
                            case .history:
                                // Already at the top, do nothing
                                break
                            }
                        }
                        
                        // Only trigger haptic feedback if stage changed
                        if nextStage != currentStage {
                            hapticFeedback.impactOccurred()
                        }
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            currentStage = nextStage
                            
                            // Set the appropriate offset based on the stage
                            switch currentStage {
                            case .collapsed:
                                offset = maxHeight - minHeight
                            case .quickActions:
                                offset = maxHeight - quickActionsHeight
                            case .history:
                                offset = 0
                            }
                            
                            lastOffset = offset
                        }
                    }
            )
            .onAppear {
                // Initialize haptic feedback
                hapticFeedback.prepare()
                
                // Start in collapsed state
                offset = maxHeight - minHeight
                lastOffset = offset
                currentStage = .collapsed
            }
        }
        .frame(maxHeight: maxHeight)
        .ignoresSafeArea(edges: .bottom)
    }
}

struct QuickActionButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.black)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .foregroundColor(.black)
        }
    }
}

struct RecentRouteItem: View {
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.gray)
            Text(title)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}
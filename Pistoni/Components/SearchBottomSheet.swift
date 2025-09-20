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
    private let minHeight: CGFloat = 80
    private let quickActionsHeight: CGFloat = 220 // Height for quick actions stage
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag Indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue.opacity(0.08))
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
                                .frame(width: 25, height: 25)
                                .foregroundColor(.blue)
                            Text("Search Destination")
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding()
                        .background(.blue.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Profile Button
                    Button(action: onProfileTap) {
                        Image("user_1")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                            .padding()
                            .background(.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .frame(width: 50, height: 50)
                }
                .padding(.top, 10)
                .padding(.horizontal, 20)
             
                
                // Quick Actions - visible in quickActions and history stages
                if currentStage == .quickActions || currentStage == .history {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 10) {
                            QuickActionButton(icon: "house.fill", text: "Home")
                                .frame(maxWidth: .infinity)
                            QuickActionButton(icon: "car.fill", text: "Rides")
                                .frame(maxWidth: .infinity)
                            QuickActionButton(icon: "clock.fill", text: "Recent")
                                .frame(maxWidth: .infinity)
                            QuickActionButton(icon: "exclamationmark.triangle.fill", text: "Help")
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    .transition(.opacity.animation(.easeIn(duration: 1)))
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
                    .transition(.opacity.animation(.easeIn(duration: 1)))
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 50))
            .shadow(color: .black.opacity(0.1), radius: 10)
            .offset(y: max(offset + gestureOffset, 0))
            .onAppear {
                updateOffset()
            }
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
                        } else if height < -50 { // Swipe up
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
                        
                        // Update stage and animate
                        withAnimation(.spring()) {
                            currentStage = nextStage
                            updateOffset()
                        }
                        
                        // Haptic feedback
                        if nextStage != currentStage {
                            hapticFeedback.impactOccurred()
                        }
                    }
            )
        }
    }
    
    private func updateOffset() {
        switch currentStage {
        case .collapsed:
            offset = maxHeight - minHeight
        case .quickActions:
            offset = maxHeight - quickActionsHeight
        case .history:
            offset = 0
        }
    }
}

// MARK: - Preview
struct SearchBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background to simulate the main view
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                SearchBottomSheet(
                    navigationPath: .constant(NavigationPath()),
                    showingSearchScreen: .constant(false),
                    onProfileTap: {
                        print("Profile tapped")
                    }
                )
                .frame(height: UIScreen.main.bounds.height - 100)
            }
        }
        .previewDisplayName("SearchBottomSheet - Collapsed")
        
        // Preview with Quick Actions stage
        ZStack {
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                SearchBottomSheetWithStage(stage: .quickActions)
                    .frame(height: UIScreen.main.bounds.height - 100)
            }
        }
        .previewDisplayName("SearchBottomSheet - Quick Actions")
        
        // Preview with History stage
        ZStack {
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                SearchBottomSheetWithStage(stage: .history)
                    .frame(height: UIScreen.main.bounds.height - 100)
            }
        }
        .previewDisplayName("SearchBottomSheet - History")
    }
}

// Helper view for previewing different stages
struct SearchBottomSheetWithStage: View {
    @State private var currentStage: BottomSheetStage
    
    init(stage: BottomSheetStage) {
        _currentStage = State(initialValue: stage)
    }
    
    var body: some View {
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
                    // Mock action
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                        Text("Search Destination")
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding()
                    .background(.blue.opacity(0.3))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                
                // Profile Button
                Button(action: {}) {
                    Image(systemName: "person.circle")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                        .padding()
                        .background(.blue.opacity(0.3))
                        .clipShape(Circle())
                }
                .frame(width: 50, height: 50)
            }
            .padding(.horizontal, 5)
            .padding(.top, 10)
            
            // Quick Actions - visible in quickActions and history stages
            if currentStage == .quickActions || currentStage == .history {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 10) {
                        QuickActionButton(icon: "home", text: "Home")
                            .frame(maxWidth: .infinity)
                        QuickActionButton(icon: "car.fill", text: "Rides")
                            .frame(maxWidth: .infinity)
                        QuickActionButton(icon: "clock.fill", text: "Recent")
                            .frame(maxWidth: .infinity)
                        QuickActionButton(icon: "exclamationmark.triangle.fill", text: "Help")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
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
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 50))
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

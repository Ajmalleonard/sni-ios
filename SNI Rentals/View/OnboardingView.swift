//
//  OnboardingView.swift
//  SNI Rentals
//
//  Created by Ajmal on 1/22/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme
    var onOnboardingComplete: () -> Void
    
    private let pages = [ 
        OnboardingPage(
            title: "With Love",
            icon: "heart_1",
            subtitle: "We've come to simplify the mess",
            imageName: "car.circle.fill",
            description: "From luxury cars to everyday vehicles, we have the perfect ride waiting for you."
        ),
        OnboardingPage(
            title: "We Connect The World",
            icon: "universe",
            subtitle: "Book your rental in just a few taps",
            imageName: "calendar.circle.fill",
            description: "Our streamlined booking process makes renting a vehicle quick and hassle-free."
        ),
        OnboardingPage(
            title: "Safe & Secure",
            icon: "complex",
            subtitle: "Your safety is our top priority",
            imageName: "shield.checkered",
            description: "All vehicles are regularly maintained and fully insured for your peace of mind."
        )
    ]
    
    // Computed property to check if we're in dark mode
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        ZStack {
            // Background with fallback
            BackgroundView()
            
            VStack(spacing: 0) {
                
           
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom Buttons
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // Get Started Button
                        Button(action: onOnboardingComplete) {
                            Text("Get Started")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .padding(.vertical,10)
                                .background(Color("Secondary").opacity(0))
                                .foregroundColor(Color("Secondary"))
                                .clipShape(Capsule())
                                .background(.ultraThinMaterial, in: .capsule)
                        }
                     
                        // Page Indicator
                       
                    } else {
                        // Next and Skip Buttons
                        Button{
                            withAnimation(){
                                currentPage += 1
                            }
                            
                        }label: {
                    
                        HStack {
                         
                            Text("Next")
                             
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .padding(.vertical,10)
                            .background(Color("Secondary").opacity(0))
                            .foregroundColor(Color("Secondary"))
                            .clipShape(Capsule())
                            .background(.ultraThinMaterial, in: .capsule)
                        }
                       
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
            HStack {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color("Secondary") : Color("Secondary").opacity(0.3))
                        .frame(width: 10, height: 10)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.top, 50)
            .padding(.bottom, 30)
        }
        .onAppear {
            // You can now use the colorScheme in your logic
            print("🌓 Current color scheme: \(isDarkMode ? "Dark" : "Light")")
        }
        .onChange(of: colorScheme) { oldValue, newValue in
            // React to color scheme changes
            print("🌓 Color scheme changed from \(oldValue) to \(newValue)")
        }
    }
}

// Robust background view that tries video first, then falls back to static
struct BackgroundView: View {
    var body: some View {
        // Use optimized background instead of video
        OptimizedBackground()
    }
}

// Static background as fallback for onboarding
struct OnboardingStaticBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: isDarkMode ? darkModeColors : lightModeColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var lightModeColors: [Color] {
        [
            Color("Primary").opacity(0.8),
            Color("Secondary").opacity(0.6),
            Color("Primary").opacity(0.9)
        ]
    }
    
    private var darkModeColors: [Color] {
        [
            Color("Primary").opacity(0.95),
            Color("Secondary").opacity(0.4),
            Color("Primary").opacity(1.0)
        ]
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Simplified icon with single entrance animation
            if !page.icon.isEmpty {
                Image(page.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 300)
                    .foregroundColor(Color("Secondary"))
                    .padding(.bottom, 20)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .onAppear {
                        // Single entrance animation only
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            hasAppeared = true
                        }
                    }
            } else {
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(Color("Secondary"))
                    .padding(.bottom, 20)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            hasAppeared = true
                        }
                    }
            }
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("Secondary"))
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(Color("Secondary"))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(Color("Secondary").opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct OnboardingPage {
    let title: String
    let icon : String
    let subtitle: String
    let imageName: String
    let description: String
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
} 

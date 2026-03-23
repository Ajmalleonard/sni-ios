//
//  SplashScreen.swift
//  SNI Rentals
//
//  Created by AI Assistant on 1/22/25.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isVisible = false
    @State private var loadingAngle: Double = 0
    
    var onSplashComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color("AppPrimary")
                .ignoresSafeArea()
            
            ZStack {
                // Centered logo
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                // Bottom content
                VStack {
                    Text("Your Journey Starts Here")
                        .font(.subheadline)
                        .foregroundColor(Color("AppSecondary").opacity(0.8))
                        .opacity(isVisible ? 1.0 : 0.0)
                    
                    Image("Loading")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(loadingAngle))
                        .onAppear {
                            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                loadingAngle = 360
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 40) // adjust well padding as desired
            }
            .animation(.easeInOut(duration: 0.8), value: isVisible)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Single unified animation
        withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
            isVisible = true
        }
        
        // Complete splash after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onSplashComplete()
        }
    }
}

#Preview {
    SplashScreen {
        print("Splash completed")
    }
} 


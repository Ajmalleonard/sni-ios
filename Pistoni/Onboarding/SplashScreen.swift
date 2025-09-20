//
//  SplashScreen.swift
//  SNI Rentals
//
//  Created by AI Assistant on 1/22/25.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isVisible = false
    
    var onSplashComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color("Primary")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image("sni_white")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(Color("Secondary"))
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                
                Text("Your Journey Starts Here")
                    .font(.subheadline)
                    .foregroundColor(Color("Secondary").opacity(0.8))
                    .opacity(isVisible ? 1.0 : 0.0)
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

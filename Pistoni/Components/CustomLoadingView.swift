import SwiftUI

struct CustomLoadingView: View {
    @State private var isRotating = 0.0
    @State private var trimEnd = 0.1
    
    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()
            
            // Custom spinner
            VStack(spacing: 20) {
                ZStack {
                    // Background circle
                    
                    
                    Image("Loading")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .rotationEffect(Angle(degrees: isRotating))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
                    
                    
                }
                
            }
        }
        .onAppear {
            isRotating = 360
            trimEnd = 0.8
        }
    }
}

// Loading overlay modifier
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
            
            if isLoading {
                CustomLoadingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading))
    }
}

#Preview {
    CustomLoadingView()
} 

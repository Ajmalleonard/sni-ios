//
//  Backgrounds.swift
//  SNI Rentals
//
//  Created by Jesus on 7/7/25.
//

import SwiftUI
import AVKit

// MARK: - Optimized Background System
struct OptimizedBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animationOffset: CGFloat = 0
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle animated overlay
            AnimatedOverlay(animationOffset: $animationOffset, isDarkMode: isDarkMode)
        }
        .onAppear {
            startSubtleAnimation()
        }
    }
    
    private var gradientColors: [Color] {
        if isDarkMode {
            return [
                Color("Primary").opacity(0.95),
                Color("Secondary").opacity(0.1),
                Color("Accent").opacity(0.3),
                Color("Primary").opacity(0.9)
            ]
        } else {
            return [
                Color("Primary").opacity(0.8),
                Color("Secondary").opacity(0.2),
                Color("Accent").opacity(0.4),
                Color("Primary").opacity(0.85)
            ]
        }
    }
    
    private func startSubtleAnimation() {
        withAnimation(.easeInOut(duration: 20.0).repeatForever(autoreverses: true)) {
            animationOffset = 50
        }
    }
}

// MARK: - Animated Overlay
struct AnimatedOverlay: View {
    @Binding var animationOffset: CGFloat
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            // First layer
            Circle()
                .fill(Color("Accent").opacity(isDarkMode ? 0.1 : 0.15))
                .frame(width: 300, height: 300)
                .offset(x: -100 + animationOffset, y: -150 + animationOffset * 0.5)
                .blur(radius: 50)
            
            // Second layer
            Circle()
                .fill(Color("Secondary").opacity(isDarkMode ? 0.05 : 0.1))
                .frame(width: 200, height: 200)
                .offset(x: 120 - animationOffset * 0.7, y: 200 - animationOffset * 0.3)
                .blur(radius: 40)
        }
        .clipped()
    }
}

// MARK: - Fallback Background (Enhanced)
struct FallbackBackground: View {
    var body: some View {
        OptimizedBackground()
    }
}

// MARK: - Deprecated Video Background (Kept for backward compatibility)
struct LoopingVideo: View {
    var videoName: String
    var videoType: String
    var isMuted: Bool = true
    
    var body: some View {
        // Fallback to optimized background instead of video
        OptimizedBackground()
    }
}

// MARK: - Static Background (Lightweight)
struct StaticBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        ZStack {
            // Main gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("Primary").opacity(isDarkMode ? 0.95 : 0.8),
                    Color("Secondary").opacity(isDarkMode ? 0.1 : 0.2),
                    Color("Primary").opacity(isDarkMode ? 0.9 : 0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            Image("bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(isDarkMode ? 0.1 : 0.15)
                .blur(radius: 30)
                .clipped()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Minimal Background (Most efficient)
struct MinimalBackground: View {
    var body: some View {
        Color("Primary")
            .ignoresSafeArea()
    }
}

// MARK: - Background Factory
struct BackgroundFactory {
    enum BackgroundType {
        case optimized
        case staticBackground
        case minimal
    }
    
    @ViewBuilder
    static func background(type: BackgroundType) -> some View {
        switch type {
        case .optimized:
            OptimizedBackground()
        case .staticBackground:
            StaticBackground()
        case .minimal:
            MinimalBackground()
        }
    }
}

// MARK: - Deprecated Classes (Kept for backward compatibility)
class PlayerUI: UIView {
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    private var hasVideo = false
    private var isMuted: Bool = true
    
    init(frame: CGRect, videoName: String, videoType: String, isMuted: Bool = true) {
        self.isMuted = isMuted
        super.init(frame: frame)
        // No longer setup video player - use background color instead
        setupFallbackBackground()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFallbackBackground()
    }
    
    private func setupFallbackBackground() {
        hasVideo = false
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.8).cgColor,
            UIColor.systemPurple.withAlphaComponent(0.6).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.9).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradientLayer = layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = bounds
        }
    }
    
    func setMuted(_ muted: Bool) {
        // No-op for backward compatibility
    }
    
    func cleanup() {
        // No-op for backward compatibility
    }
}

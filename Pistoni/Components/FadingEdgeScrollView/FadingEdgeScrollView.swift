//
//  FadingEdgeScrollView.swift
//  Pistoni
//
//  A reusable ScrollView with fading edges at top/bottom for a smooth scroll UI.
//

import SwiftUI

/// A vertical ScrollView that applies a fade gradient mask at the top and/or bottom edges.
///
/// **How it works:**
/// - The content is rendered inside a standard `ScrollView`.
/// - A `.mask()` modifier is applied with a `LinearGradient` that transitions from transparent → opaque → transparent.
/// - The gradient's alpha channel controls which parts of the content are visible (0 = hidden, 1 = fully visible).
/// - Only the edges fade; the middle content remains fully opaque.
///
/// **Customization:**
/// - Adjust `fadeHeight` to control how tall the fade zone is (in points).
/// - Use `topFadeEnabled` / `bottomFadeEnabled` to toggle fades independently.
/// - For stronger/softer fade, tweak the gradient stop locations (e.g., change 0.3 to 0.5 for a gentler fade).
///
/// **Usage:**
/// ```swift
/// FadingEdgeScrollView(fadeHeight: 40, topFadeEnabled: true, bottomFadeEnabled: true) {
///     VStack(spacing: 16) {
///         ForEach(0..<50, id: \.self) { index in
///             Text("Row \(index)")
///         }
///     }
/// }
/// ```
struct FadingEdgeScrollView<Content: View>: View {
    // MARK: - Properties
    
    /// The content to display inside the scroll view.
    let content: Content
    
    /// Height (in points) of the fade gradient zone at each edge.
    let fadeHeight: CGFloat
    
    /// Whether to apply fade at the top edge.
    let topFadeEnabled: Bool
    
    /// Whether to apply fade at the bottom edge.
    let bottomFadeEnabled: Bool
    
    /// Optional: Whether to add a subtle blur overlay at the edges (experimental).
    let blurEdgesEnabled: Bool
    
    /// Blur radius for edge blur effect (if enabled).
    let edgeBlurRadius: CGFloat
    
    // MARK: - Initializers
    
    /// Creates a fading edge scroll view with customizable fade zones.
    ///
    /// - Parameters:
    ///   - fadeHeight: Height of the fade zone at each edge (default: 32).
    ///   - topFadeEnabled: Enable fade at top (default: true).
    ///   - bottomFadeEnabled: Enable fade at bottom (default: true).
    ///   - blurEdgesEnabled: Add subtle blur overlay at edges (default: false).
    ///   - edgeBlurRadius: Blur radius if blur is enabled (default: 8).
    ///   - content: The scrollable content.
    init(
        fadeHeight: CGFloat = 32,
        topFadeEnabled: Bool = true,
        bottomFadeEnabled: Bool = true,
        blurEdgesEnabled: Bool = false,
        edgeBlurRadius: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.fadeHeight = fadeHeight
        self.topFadeEnabled = topFadeEnabled
        self.bottomFadeEnabled = bottomFadeEnabled
        self.blurEdgesEnabled = blurEdgesEnabled
        self.edgeBlurRadius = edgeBlurRadius
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                content
                    .frame(maxWidth: .infinity)
            }
            .mask(
                // The LinearGradient acts as an alpha mask:
                // - Clear (0) = content is hidden
                // - White (1) = content is fully visible
                // - The gradient creates a smooth transition at the edges
                LinearGradient(
                    gradient: Gradient(stops: gradientStops(for: geometry.size.height)),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .top) {
                // Optional: Blur overlay at top edge
                if blurEdgesEnabled && topFadeEnabled {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: fadeHeight)
                        .background(.ultraThinMaterial)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(colors: [.black, .clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .bottom) {
                // Optional: Blur overlay at bottom edge
                if blurEdgesEnabled && bottomFadeEnabled {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: fadeHeight)
                        .background(.ultraThinMaterial)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    // MARK: - Gradient Calculation
    
    /// Builds the gradient stops for the fade mask based on enabled edges and scroll view height.
    ///
    /// **How gradient stops work:**
    /// - Each stop is a tuple: (color, location from 0.0 to 1.0)
    /// - Location 0.0 = top of view, 1.0 = bottom of view
    /// - The gradient interpolates smoothly between stops
    ///
    /// **Tweaking fade strength:**
    /// - Change the stop locations to adjust fade softness:
    ///   - Current: fade zone is ~fadeHeight, transition happens over 30% of that zone
    ///   - For gentler fade: increase the middle transition range (e.g., 0.0...0.5 instead of 0.0...0.3)
    ///   - For sharper fade: decrease the transition range (e.g., 0.0...0.15)
    private func gradientStops(for height: CGFloat) -> [Gradient.Stop] {
        // Calculate the relative position of the fade zone as a fraction of total height
        let topFadePoint = fadeHeight / height
        let bottomFadePoint = 1.0 - (fadeHeight / height)
        
        var stops: [Gradient.Stop] = []
        
        if topFadeEnabled {
            // Top edge: starts clear (hidden), becomes opaque at topFadePoint
            stops.append(Gradient.Stop(color: .clear, location: 0.0))
            stops.append(Gradient.Stop(color: .white, location: topFadePoint))
        } else {
            // No top fade: start fully opaque
            stops.append(Gradient.Stop(color: .white, location: 0.0))
        }
        
        if bottomFadeEnabled {
            // Bottom edge: becomes clear (hidden) at bottomFadePoint, ends clear
            stops.append(Gradient.Stop(color: .white, location: bottomFadePoint))
            stops.append(Gradient.Stop(color: .clear, location: 1.0))
        } else {
            // No bottom fade: end fully opaque
            stops.append(Gradient.Stop(color: .white, location: 1.0))
        }
        
        return stops
    }
}

// MARK: - Preview

#Preview("Default Fade") {
    FadingEdgeScrollView {
        VStack(spacing: 16) {
            ForEach(0..<50, id: \.self) { index in
                Text("Row \(index)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview("Top Fade Only") {
    FadingEdgeScrollView(topFadeEnabled: true, bottomFadeEnabled: false) {
        VStack(spacing: 16) {
            ForEach(0..<50, id: \.self) { index in
                Text("Row \(index)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview("With Blur Overlay") {
    FadingEdgeScrollView(fadeHeight: 40, blurEdgesEnabled: true) {
        VStack(spacing: 16) {
            ForEach(0..<50, id: \.self) { index in
                Text("Row \(index)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

//
//  FadingEdgeScrollViewDemo.swift
//  Pistoni
//
//  Demo screen showing various configurations of the FadingEdgeScrollView component.
//

import SwiftUI

/// A demo screen showcasing different fade configurations and use cases.
struct FadingEdgeScrollViewDemo: View {
    // MARK: - State
    
    @State private var selectedDemo: DemoType = .defaultFade
    
    // MARK: - Demo Types
    
    enum DemoType: String, CaseIterable {
        case defaultFade = "Default Fade"
        case topOnly = "Top Only"
        case bottomOnly = "Bottom Only"
        case customHeight = "Custom Height (60pt)"
        case withBlur = "With Blur Overlay"
        case darkMode = "Dark Mode Test"
        
        var fadeHeight: CGFloat {
            switch self {
            case .customHeight: return 60
            default: return 32
            }
        }
        
        var topEnabled: Bool {
            switch self {
            case .bottomOnly: return false
            default: return true
            }
        }
        
        var bottomEnabled: Bool {
            switch self {
            case .topOnly: return false
            default: return true
            }
        }
        
        var blurEnabled: Bool {
            switch self {
            case .withBlur: return true
            default: return false
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Demo selector
                Picker("Demo Type", selection: $selectedDemo) {
                    ForEach(DemoType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Demo content
                FadingEdgeScrollView(
                    fadeHeight: selectedDemo.fadeHeight,
                    topFadeEnabled: selectedDemo.topEnabled,
                    bottomFadeEnabled: selectedDemo.bottomEnabled,
                    blurEdgesEnabled: selectedDemo.blurEnabled
                ) {
                    VStack(spacing: 12) {
                        // Header
                        Text("Scroll to see the fade effect")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        // Sample content rows
                        ForEach(0..<50, id: \.self) { index in
                            HStack {
                                Image(systemName: "\(index % 50).circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(gradientColor(for: index))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Item \(index + 1)")
                                        .font(.headline)
                                    
                                    Text("Scroll to see fade at edges")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                        }
                        
                        // Footer
                        Text("End of list")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    .padding(.horizontal)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Fading Scroll Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Text("Fade Height: \(Int(selectedDemo.fadeHeight))pt")
                        Text("Top: \(selectedDemo.topEnabled ? "✓" : "✗")")
                        Text("Bottom: \(selectedDemo.bottomEnabled ? "✓" : "✗")")
                        Text("Blur: \(selectedDemo.blurEnabled ? "✓" : "✗")")
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .preferredColorScheme(selectedDemo == .darkMode ? .dark : nil)
    }
    
    // MARK: - Helpers
    
    /// Returns a gradient color based on the row index.
    private func gradientColor(for index: Int) -> LinearGradient {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green]
        let color = colors[index % colors.count]
        
        return LinearGradient(
            gradient: Gradient(colors: [color, color.opacity(0.6)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Simple Usage Example

/// A minimal example showing basic usage of FadingEdgeScrollView.
struct SimpleFadingScrollExample: View {
    var body: some View {
        FadingEdgeScrollView(fadeHeight: 40) {
            VStack(spacing: 20) {
                ForEach(1...100, id: \.self) { number in
                    Text("Row \(number)")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            .padding()
        }
    }
}

// MARK: - Real-World Use Case: Chat Messages

/// Example: Chat-style message list with fading scroll edges.
struct ChatMessageListExample: View {
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                VStack(alignment: .leading) {
                    Text("John Doe")
                        .font(.headline)
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Messages with fading scroll
            FadingEdgeScrollView(fadeHeight: 30) {
                VStack(spacing: 12) {
                    ForEach(0..<40, id: \.self) { index in
                        HStack {
                            if index % 3 == 0 {
                                Spacer()
                            }
                            
                            Text("Message \(index + 1)\nThis is a sample message")
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(index % 3 == 0 ? Color.blue : Color(.systemGray5))
                                )
                                .foregroundColor(index % 3 == 0 ? .white : .primary)
                            
                            if index % 3 != 0 {
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            
            // Input field
            HStack {
                TextField("Type a message...", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {}) {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Previews

#Preview("Demo Screen") {
    FadingEdgeScrollViewDemo()
}

#Preview("Simple Example") {
    SimpleFadingScrollExample()
}

#Preview("Chat Example") {
    ChatMessageListExample()
}

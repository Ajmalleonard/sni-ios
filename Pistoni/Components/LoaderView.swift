//
//  LoaderView.swift
//  SNI Rentals
//
//  Created by Assistant on 1/27/25.
//

import SwiftUI

struct LoaderView: View {
    var isLoading: Bool = true
    var loadingText: String = "Loading..."
    var symbols: [String] = ["circle", "ellipsis", "checkmark.circle.fill"]
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 12) {
                    PhaseAnimator(symbols) { symbol in
                        Image(systemName: symbol)
                            .font(.system(size: 100))
                            .contentTransition(.symbolEffect)
                            .frame(width: 150, height: 150)
                            .foregroundColor(Color("AppSecondary"))
                    } animation: { _ in
                        .linear(duration: 1.2)
                    }
                    .frame(height: 150)
                    
                    Text(loadingText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AppSecondary"))
                }
                .geometryGroup()
                .transition(.blurReplace)
            }
        }
        .background(Color("AppPrimary"))
        .animation(.snappy(duration: 0.3, extraBounce: 0), value: isLoading)
    }
}

#Preview {
    LoaderView(isLoading: true, loadingText: "Sending Verification Code...")
}



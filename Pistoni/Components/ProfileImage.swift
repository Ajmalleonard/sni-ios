//
//  ProfileImage.swift
//  SNI Rentals
//
//  Created by Assistant on 20/01/25.
//

import SwiftUI

// MARK: - Optimized Profile Image Component
struct ProfileImage: View {
    let url: String?
    let displayName: String
    let size: CGFloat
    
    var body: some View {
        Group {
            if let url = url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    CustomLoadingView()
                        .scaleEffect(0.3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                }
            } else {
                ProfileInitials(displayName: displayName)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Profile Initials Fallback
struct ProfileInitials: View {
    let displayName: String
    
    var body: some View {
        Circle()
            .fill(Color("Accent").opacity(0.3))
            .overlay(
                Text(displayName.isEmpty ? "U" : displayName.prefix(1).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                           .linearGradient(
                               colors: [.blue, .white],
                               startPoint: .top,
                               endPoint: .trailing
                           )
                       )
            )
    }
}

#if DEBUG
struct ProfileImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProfileImage(
                url: nil,
                displayName: "John Doe",
                size: 55
            )
            
            ProfileImage(
                url: "https://example.com/avatar.jpg",
                displayName: "Jane Smith",
                size: 80
            )
        }
        .padding()
    }
}
#endif
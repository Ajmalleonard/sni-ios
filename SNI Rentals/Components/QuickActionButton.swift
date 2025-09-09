//
//  QuickActionButton.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 04/09/2025.
//

import SwiftUI

struct QuickActionButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.black)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .foregroundColor(.black)
        }
    }
}

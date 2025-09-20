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
            Image(icon)
                .renderingMode(.template)
                .resizable()
                
                .foregroundColor(.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .foregroundColor(.black)
        }
    }
}

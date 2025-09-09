//
//  RecentRouteItem.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 04/09/2025.
//
import SwiftUI

struct RecentRouteItem: View {
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.gray)
            Text(title)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

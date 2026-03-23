import SwiftUI

//
//  RouteDetailItem.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 04/09/2025.
//
import SwiftUI


// MARK: - Route Detail Item
struct RouteDetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color("AppSecondary"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

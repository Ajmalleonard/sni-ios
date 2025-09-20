//
//  VehicleCategoryRow.swift
//  SNI Rentals
//
//  Created by Assistant on 20/01/25.
//

import SwiftUI

// MARK: - Vehicle Category Row Component
struct VehicleCategoryRow: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Vehicle icon
            Image(systemName: getSystemIcon(for: icon))
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Arrow indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // Helper function to map icon names to system icons
    private func getSystemIcon(for iconName: String) -> String {
        switch iconName.lowercased() {
        case "coaster":
            return "bus.fill"
        case "suv":
            return "car.fill"
        case "truck":
            return "truck.box.fill"
        default:
            return "car.fill"
        }
    }
}

#if DEBUG
struct VehicleCategoryRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            VehicleCategoryRow(
                title: "Coasters",
                description: "Compact and efficient city cars",
                icon: "coaster"
            )
            
            VehicleCategoryRow(
                title: "SUVs",
                description: "Spacious vehicles for any terrain",
                icon: "suv"
            )
            
            VehicleCategoryRow(
                title: "Huge Vehicles",
                description: "Large capacity for groups and cargo",
                icon: "truck"
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif

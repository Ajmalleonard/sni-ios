//
//  RentalCard.swift
//  SNI Rentals
//
//  Created by Assistant on 1/20/25.
//

import SwiftUI

// MARK: - Rental Data Model
struct RentalData {
    let id: Int
    let carName: String
    let price: String
    let distance: String
}

// MARK: - Optimized Rental Card
struct RentalCard: View {
    let rental: RentalData
    
    var body: some View {
        HStack {
            // Simplified car placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.3))
                .frame(width: 60, height: 40)
                .overlay(
                    Image(systemName: "car.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 16))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(rental.carName)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(rental.distance)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(rental.price)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Button("Rent") {
                    // Rent action
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.black)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    RentalCard(rental: RentalData(
        id: 1,
        carName: "Tesla Model 3",
        price: "$89/day",
        distance: "0.2 mi"
    ))
    .padding()
}
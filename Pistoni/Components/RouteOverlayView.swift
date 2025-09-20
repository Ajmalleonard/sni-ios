//
//  RouteOverlayView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 04/09/2025.
//

import SwiftUI



// MARK: - Route Overlay View (Uber-style)
struct RouteOverlayView: View {
    let route: RouteInfo
    let onClose: () -> Void
    let onBookRide: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Route information
            VStack(spacing: 16) {
                // Route header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Route Preview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(route.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // From and To locations
                VStack(spacing: 12) {
                    LocationRow(
                        icon: "circle.fill",
                        iconColor: .green,
                        title: "From",
                        location: route.fromLocation.name,
                        subtitle: route.fromLocation.address
                    )
                    
                    // Dotted line
                    VStack {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 4, height: 4)
                        }
                    }
                    
                    LocationRow(
                        icon: "circle.fill",
                        iconColor: .red,
                        title: "To",
                        location: route.toLocation.name,
                        subtitle: route.toLocation.address
                    )
                }
                .padding(.vertical, 8)
                
                // Route details
                HStack(spacing: 20) {
                    RouteDetailItem(
                        icon: "location.fill",
                        title: "Distance",
                        value: route.distance
                    )
                    
                    RouteDetailItem(
                        icon: "clock.fill",
                        title: "Duration",
                        value: route.duration
                    )
                    
                    RouteDetailItem(
                        icon: "dollarsign.circle.fill",
                        title: "Cost",
                        value: route.estimatedCost
                    )
                }
                .padding(.horizontal)
                
                // Book ride button
                Button(action: onBookRide) {
                    Text("Book This Ride")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }
}

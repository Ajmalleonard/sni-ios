//
//  RentalConfirmationView.swift
//  SNI Rentals
//
//  Created by Assistant on 25/01/25.
//

import SwiftUI

struct RentalConfirmationView: View {
    let car: Car
    let startDate: Date
    let endDate: Date
    let totalPrice: Double
    
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingChat = false
    
    private var numberOfDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section - ProfileView Style
                    confirmationHeaderSection
                    
                    // Content Sections
                    VStack(spacing: 20) {
                        bookingSummarySection
                        carDetailsSection
                        tripDetailsSection
                        contactSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Space for action buttons
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                actionButtons
            }
            .sheet(isPresented: $showingChat) {
                // Navigate to chat with owner
                Text("Chat with \(car.owner?.displayName ?? "Owner")")
            }
        }
    }
    
    // MARK: - Header Section
    private var confirmationHeaderSection: some View {
        VStack(spacing: 0) {
            // Success Icon
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 8) {
                    Text("Booking Confirmed!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Your rental has been successfully booked")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(Color("Primary"))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Booking Summary Section
    private var bookingSummarySection: some View {
        ProfileSection(title: "Booking Summary") {
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "doc.text.fill",
                    title: "Booking ID",
                    subtitle: "RENT-\(Int.random(in: 100000...999999))",
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "calendar",
                    title: "Booking Date",
                    subtitle: Date().formatted(date: .abbreviated, time: .shortened),
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "creditcard.fill",
                    title: "Total Paid",
                    subtitle: String(format: "$%.2f", totalPrice),
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "checkmark.shield.fill",
                    title: "Status",
                    subtitle: "Confirmed",
                    action: {}
                )
            }
        }
    }
    
    // MARK: - Car Details Section
    private var carDetailsSection: some View {
        ProfileSection(title: "Car Details") {
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "car.fill",
                    title: "Vehicle",
                    subtitle: car.displayName,
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "paintbrush.fill",
                    title: "Color",
                    subtitle: car.color,
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "number",
                    title: "License Plate",
                    subtitle: car.licensePlate,
                    action: {}
                )
                
                if let location = car.location {
                    ProfileMenuItem(
                        icon: "location.fill",
                        title: "Pickup Location",
                        subtitle: location.address,
                        action: {}
                    )
                }
            }
        }
    }
    
    // MARK: - Trip Details Section
    private var tripDetailsSection: some View {
        ProfileSection(title: "Trip Details") {
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "calendar.badge.plus",
                    title: "Start Date",
                    subtitle: startDate.formatted(date: .abbreviated, time: .shortened),
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "calendar.badge.minus",
                    title: "End Date",
                    subtitle: endDate.formatted(date: .abbreviated, time: .shortened),
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "clock.fill",
                    title: "Duration",
                    subtitle: "\(numberOfDays) day\(numberOfDays == 1 ? "" : "s")",
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "dollarsign.circle.fill",
                    title: "Daily Rate",
                    subtitle: car.priceFormatted,
                    action: {}
                )
            }
        }
    }
    
    // MARK: - Contact Section
    private var contactSection: some View {
        ProfileSection(title: "Contact Information") {
            VStack(spacing: 0) {
                if let owner = car.owner {
                    ProfileMenuItem(
                        icon: "person.circle.fill",
                        title: "Owner",
                        subtitle: owner.displayName,
                        action: {}
                    )
                    
                    ProfileMenuItem(
                        icon: "envelope.fill",
                        title: "Email",
                        subtitle: owner.email,
                        action: {}
                    )
                    
                    if let phone = owner.phoneNumber {
                        ProfileMenuItem(
                            icon: "phone.fill",
                            title: "Phone",
                            subtitle: phone,
                            action: {}
                        )
                    }
                }
                
                ProfileMenuItem(
                    icon: "message.fill",
                    title: "Chat with Owner",
                    subtitle: "Send a message to the car owner",
                    action: {
                        showingChat = true
                    }
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                Button {
                    showingChat = true
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Chat")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Button {
                    // View booking details
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("View Details")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    RentalConfirmationView(
        car: Car.sampleCar,
        startDate: Date(),
        endDate: Date().addingTimeInterval(24 * 60 * 60),
        totalPrice: 150.0
    )
    .environmentObject(AuthModel())
} 
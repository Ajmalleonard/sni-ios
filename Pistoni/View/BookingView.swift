//
//  BookingView.swift
//  SNI Rentals
//
//  Created by Assistant on 25/01/25.
//

import SwiftUI

struct BookingView: View {
    let car: Car
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(24 * 60 * 60) // Next day
    @State private var pickupLocation = ""
    @State private var dropoffLocation = ""
    @State private var additionalServices: Set<String> = []
    @State private var isLoading = false
    @State private var showingConfirmation = false
    
    private var numberOfDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
    }
    
    private var basePrice: Double {
        car.price * Double(numberOfDays)
    }
    
    private var serviceFees: Double {
        basePrice * 0.05 // 5% service fee
    }
    
    private var totalPrice: Double {
        basePrice + serviceFees
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section - ProfileView Style
                    bookingHeaderSection
                    
                    // Content Sections
                    VStack(spacing: 20) {
                        tripDetailsSection
                        pickupLocationSection
                        dropoffLocationSection
                        priceBreakdownSection
                        additionalServicesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Space for booking button
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                confirmBookingButton
            }
            .sheet(isPresented: $showingConfirmation) {
                RentalConfirmationView(
                    car: car,
                    startDate: startDate,
                    endDate: endDate,
                    totalPrice: totalPrice
                )
                .environmentObject(authModel)
            }
        }
    }
    
    // MARK: - Header Section
    private var bookingHeaderSection: some View {
        VStack(spacing: 0) {
            // Car Image
            if let primaryImage = car.primaryImage, let imageURL = URL(string: primaryImage) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "car.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 200)
                .clipped()
            }
            
            // Booking Info Header
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 16) {
                    // Car Icon
                    Image(systemName: car.vehicleType.icon)
                        .font(.system(size: 40))
                        .foregroundColor(Color("Secondary"))
                        .frame(width: 60, height: 60)
                        .background(Color("Secondary").opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Book Your Trip")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(car.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("\(numberOfDays) day\(numberOfDays == 1 ? "" : "s")")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("Secondary"))
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(totalPrice, format: .currency(code: "USD"))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("Secondary"))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(Color("Primary"))
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .padding(.horizontal, 20)
            .offset(y: -30)
        }
    }
    
    // MARK: - Trip Details Section
    private var tripDetailsSection: some View {
        ProfileSection(title: "Trip Details") {
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "calendar",
                    title: "Start Date",
                    subtitle: startDate.formatted(date: .abbreviated, time: .shortened),
                    action: {
                        // Date picker would be shown here
                    }
                )
                
                ProfileMenuItem(
                    icon: "calendar.badge.clock",
                    title: "End Date",
                    subtitle: endDate.formatted(date: .abbreviated, time: .shortened),
                    action: {
                        // Date picker would be shown here
                    }
                )
                
                ProfileMenuItem(
                    icon: "clock.fill",
                    title: "Duration",
                    subtitle: "\(numberOfDays) day\(numberOfDays == 1 ? "" : "s")",
                    action: {
                        // Duration is calculated automatically
                    }
                )
            }
        }
    }
    
    // MARK: - Pickup Location Section
    private var pickupLocationSection: some View {
        ProfileSection(title: "Pickup Location") {
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "location.fill",
                    title: "Pickup Address",
                    subtitle: pickupLocation.isEmpty ? "Select pickup location" : pickupLocation,
                    action: {
                        // Location picker would be shown here
                    }
                )
                
                if let location = car.location {
                                    ProfileMenuItem(
                    icon: "mappin.circle.fill",
                    title: "Car Location",
                    subtitle: location.address,
                    action: {
                        // Car location is read-only
                    }
                )
                }
            }
        }
    }
    
    // MARK: - Dropoff Location Section
    private var dropoffLocationSection: some View {
        ProfileSection(title: "Dropoff Location") {
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "location.fill",
                    title: "Dropoff Address",
                    subtitle: dropoffLocation.isEmpty ? "Select dropoff location" : dropoffLocation,
                    action: {
                        // Location picker would be shown here
                    }
                )
                
                ProfileMenuItem(
                    icon: "info.circle.fill",
                    title: "Same as Pickup",
                    subtitle: "Return to pickup location",
                    action: {
                        dropoffLocation = pickupLocation
                    }
                )
            }
        }
    }
    
    // MARK: - Price Breakdown Section
    private var priceBreakdownSection: some View {
        ProfileSection(title: "Price Breakdown") {
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "dollarsign.circle.fill",
                    title: "Daily Rate",
                    subtitle: car.priceFormatted,
                    action: {
                        // Daily rate is read-only
                    }
                )
                
                ProfileMenuItem(
                    icon: "calendar",
                    title: "Number of Days",
                    subtitle: "\(numberOfDays) × \(car.priceFormatted)",
                    action: {
                        // Number of days is calculated automatically
                    }
                )
                
                ProfileMenuItem(
                    icon: "creditcard.fill",
                    title: "Service Fee",
                    subtitle: String(format: "$%.2f", serviceFees),
                    action: {
                        // Service fee is calculated automatically
                    }
                )
                
                Divider()
                    .padding(.horizontal, 20)
                
                ProfileMenuItem(
                    icon: "sum",
                    title: "Total",
                    subtitle: String(format: "$%.2f", totalPrice),
                    action: {
                        // Total is calculated automatically
                    }
                )
            }
        }
    }
    
    // MARK: - Additional Services Section
    private var additionalServicesSection: some View {
        ProfileSection(title: "Additional Services") {
            VStack(spacing: 0) {
                let services = [
                    ("shield.fill", "Insurance", "Additional coverage", 25.0),
                    ("fuelpump.fill", "Fuel", "Full tank included", 15.0),
                    ("car.2.fill", "Child Seat", "Safety seat for children", 10.0),
                    ("wifi", "WiFi Hotspot", "Mobile internet", 5.0)
                ]
                
                ForEach(services, id: \.0) { icon, title, subtitle, price in
                    ProfileMenuItem(
                        icon: icon,
                        title: title,
                        subtitle: "\(subtitle) - $\(String(format: "%.2f", price))",
                        action: {
                            if additionalServices.contains(title) {
                                additionalServices.remove(title)
                            } else {
                                additionalServices.insert(title)
                            }
                        }
                    )
                    .overlay(
                        HStack {
                            Spacer()
                            if additionalServices.contains(title) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            }
                        }
                        .padding(.trailing, 20)
                    )
                }
            }
        }
    }
    
    // MARK: - Confirm Booking Button
    private var confirmBookingButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "$%.2f", totalPrice))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    createBooking()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 120, height: 50)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    } else {
                        Text("Confirm Booking")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 50)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .disabled(isLoading || !isValidBooking)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Validation
    private var isValidBooking: Bool {
        !pickupLocation.isEmpty && 
        !dropoffLocation.isEmpty && 
        endDate > startDate &&
        startDate > Date()
    }
    
    // MARK: - Actions
    private func createBooking() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            showingConfirmation = true
        }
    }
}

#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return BookingView(car: Car.sampleCar)
        .environmentObject(mockAuthModel)
}

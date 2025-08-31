//
//  CarDetailView.swift
//  SNI Rentals
//
//  Created by Assistant on 25/01/25.
//

import SwiftUI

struct CarDetailView: View {
    let car: Car
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex = 0
    @State private var showingBookingView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section - ProfileView Style
                    carHeaderSection
                    
                    // Content Sections
                    VStack(spacing: 20) {
                        carSpecificationsSection
                        ownerInformationSection
                        locationDetailsSection
                        reviewsSection
                        pricingSection
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Share car details
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                bookingButton
            }
            .sheet(isPresented: $showingBookingView) {
                BookingView(car: car)
                    .environmentObject(authModel)
            }
        }
    }
    
    // MARK: - Header Section
    private var carHeaderSection: some View {
        VStack(spacing: 0) {
            // Car Image Gallery
            CarImageGallery(
                images: car.images,
                selectedIndex: $selectedImageIndex
            )
            .frame(height: 300)
            
            // Car Info Header
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
                        Text(car.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(car.year) • \(car.color) • \(car.licensePlate)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(car.priceFormatted)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("Secondary"))
                            
                            Text("per day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    Text(car.status.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(car.status.color))
                        .clipShape(Capsule())
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
    
    // MARK: - Car Specifications Section
    private var carSpecificationsSection: some View {
        ProfileSection(title: "Car Specifications") {
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "car.fill",
                    title: "Make & Model",
                    subtitle: "\(car.make) \(car.model)",
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "calendar",
                    title: "Year",
                    subtitle: "\(car.year)",
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
                
                ProfileMenuItem(
                    icon: "gearshift",
                    title: "Transmission",
                    subtitle: car.transmissionType,
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "fuelpump.fill",
                    title: "Fuel Type",
                    subtitle: car.fuelType,
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "person.3.fill",
                    title: "Seat Count",
                    subtitle: "\(car.seatCount) seats",
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: car.vehicleType.icon,
                    title: "Vehicle Type",
                    subtitle: car.vehicleType.displayName,
                    action: {}
                )
            }
        }
    }
    
    // MARK: - Owner Information Section
    private var ownerInformationSection: some View {
        ProfileSection(title: "Owner Information") {
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
                } else {
                    ProfileMenuItem(
                        icon: "person.circle.fill",
                        title: "Owner",
                        subtitle: "Information not available",
                        action: {}
                    )
                }
            }
        }
    }
    
    // MARK: - Location Details Section
    private var locationDetailsSection: some View {
        ProfileSection(title: "Location Details") {
            VStack(spacing: 0) {
                if let location = car.location {
                    ProfileMenuItem(
                        icon: "location.fill",
                        title: "Pickup Location",
                        subtitle: location.address,
                        action: {}
                    )
                    
                    ProfileMenuItem(
                        icon: "mappin.circle.fill",
                        title: "Coordinates",
                        subtitle: "\(location.latitude), \(location.longitude)",
                        action: {}
                    )
                } else {
                    ProfileMenuItem(
                        icon: "location.fill",
                        title: "Location",
                        subtitle: "Location information not available",
                        action: {}
                    )
                }
            }
        }
    }
    
    // MARK: - Reviews Section
    private var reviewsSection: some View {
        ProfileSection(title: "Reviews & Ratings") {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Rating")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(car.averageRating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            
                            Text(String(format: "%.1f", car.averageRating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(car.reviewIds?.count ?? 0) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                if let reviews = car.reviewIds, !reviews.isEmpty {
                    ProfileMenuItem(
                        icon: "text.bubble.fill",
                        title: "View All Reviews",
                        subtitle: "Read what others say about this car",
                        action: {
                            // Navigate to reviews
                        }
                    )
                } else {
                    ProfileMenuItem(
                        icon: "text.bubble",
                        title: "No Reviews Yet",
                        subtitle: "Be the first to review this car",
                        action: {}
                    )
                }
            }
        }
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        ProfileSection(title: "Pricing & Availability") {
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "dollarsign.circle.fill",
                    title: "Daily Rate",
                    subtitle: car.priceFormatted,
                    action: {}
                )
                
                ProfileMenuItem(
                    icon: "calendar.badge.clock",
                    title: "Availability",
                    subtitle: car.isAvailable ? "Available for booking" : "Currently rented",
                    action: {}
                )
                
                if !car.features.isEmpty {
                    ProfileMenuItem(
                        icon: "checkmark.circle.fill",
                        title: "Features",
                        subtitle: car.features.joined(separator: ", "),
                        action: {}
                    )
                }
            }
        }
    }
    
    // MARK: - Booking Button
    private var bookingButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(car.priceFormatted)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    showingBookingView = true
                } label: {
                    Text("Book Now")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(car.isAvailable ? Color.blue : Color.gray)
                        .clipShape(Capsule())
                }
                .disabled(!car.isAvailable)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Car Image Gallery
struct CarImageGallery: View {
    let images: [String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        ZStack {
            if images.isEmpty {
                // Placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack {
                            Image(systemName: "car.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No images available")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            } else {
                if #available(iOS 17.0, *) {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.5)
                                    )
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                } else {
                    // Fallback for iOS 16 and earlier
                    AsyncImage(url: URL(string: images[selectedIndex])) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.5)
                            )
                    }
                }
            }
            
            // Image counter
            VStack {
                HStack {
                    Spacer()
                    
                    Text("\(selectedIndex + 1)/\(images.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}

#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return CarDetailView(car: Car.sampleCar)
        .environmentObject(mockAuthModel)
}
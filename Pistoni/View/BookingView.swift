//
//  BookingView.swift
//  Pistoni Rentals
//
//  Created by Assistant on 25/01/25.
//

import SwiftUI
import GoogleMaps


struct BookingView: View {
    let car: Car
    let routeInfo: RouteInfo
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(24 * 60 * 60) // Next day
    @State private var additionalServices: Set<String> = []
    @State private var isLoading = false
    @State private var showingConfirmation = false
    
    // Map State
#if canImport(GoogleMaps)
    @State private var mapPosition: GMSCameraPosition?
#endif
    
    init(car: Car, routeInfo: RouteInfo) {
        self.car = car
        self.routeInfo = routeInfo
#if canImport(GoogleMaps)
        _mapPosition = State(initialValue: GMSCameraPosition.camera(withLatitude: routeInfo.fromLocation.latitude, longitude: routeInfo.fromLocation.longitude, zoom: 12.0))
#endif
    }
    
    private var numberOfDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
    }
    
    private var basePrice: Double {
        car.price // Daily rate
    }
    
    private var totalBasePrice: Double {
         basePrice * Double(numberOfDays)
    }
    
    private var serviceFees: Double {
        totalBasePrice * 0.05 // 5% service fee
    }
    
    private var totalPrice: Double {
        totalBasePrice + serviceFees
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Map Background (Top Half)
                GeometryReader { geometry in
                    Group {
#if canImport(GoogleMaps)
                        if let _ = mapPosition {
                            GoogleMapsView(mapPosition: Binding(
                                get: { mapPosition ?? GMSCameraPosition.camera(withLatitude: routeInfo.fromLocation.latitude, longitude: routeInfo.fromLocation.longitude, zoom: 12.0) },
                                set: { mapPosition = $0 }
                            ), polylineToDraw: routeInfo.routePolyline)
                        } else {
                            Color.gray.opacity(0.1)
                        }
#else
                        ZStack {
                            Color.gray.opacity(0.1)
                            VStack(spacing: 8) {
                                Image(systemName: "map")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                Text("Map preview unavailable")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
#endif
                    }
                    .frame(height: geometry.size.height * 0.45)
                    .edgesIgnoringSafeArea(.top)
                }
                
                // Content ScrollView (Bottom Sheet Style)
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer for Map
                        Color.clear
                            .frame(height: UIScreen.main.bounds.height * 0.35)
                        
                        // Main Content Card
                        VStack(spacing: 24) {
                            // Route & Car Header
                            bookingHeaderSection
                            
                            // Form Sections
                            VStack(spacing: 20) {
                                tripDetailsSection
                                pickupLocationSection
                                dropoffLocationSection
                                priceBreakdownSection
                                additionalServicesSection
                            }
                            .padding(.bottom, 100)
                        }
                        .padding(.top, 20)
                        .background(Color("AppPrimary")) // Using AppPrimary for the card background
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .background(Color("AppPrimary"))
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 2)
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
        VStack(spacing: 16) {
            // Pill for Route Info
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text(routeInfo.duration)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 16)
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.caption)
                    Text(routeInfo.distance)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(Color("AppSecondary"))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color("AppSecondary").opacity(0.1))
            .clipShape(Capsule())
            
            // Car Info
            HStack(spacing: 16) {
                if let imageURLString = car.primaryImage, let url = URL(string: imageURLString) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(width: 100, height: 65)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "car.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 65)
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(car.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(car.vehicleType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(car.priceFormatted + "/day")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AppSecondary"))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
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
                    subtitle: routeInfo.fromLocation.name,
                    action: {}
                )
                
                // Show extra address details if different from name
                if routeInfo.fromLocation.name != routeInfo.fromLocation.address {
                    ProfileMenuItem(
                        icon: "mappin.and.ellipse",
                        title: "Details",
                        subtitle: routeInfo.fromLocation.address,
                        action: {}
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
                    subtitle: routeInfo.toLocation.name,
                    action: {}
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
                        Text("Confirm")
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


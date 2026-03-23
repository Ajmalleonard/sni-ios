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
    @StateObject private var vehicleDataManager = VehicleDataManager.shared
    @State private var selectedImage: String?
    @State private var showingBookingView = false
    @State private var isLiked: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            
            VStack(spacing: 0) {
                // 1. Hero Image Carousel (Fixed at top)
                imageCarousel
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .ignoresSafeArea(.all, edges: .top)
                    
                // 2. Scrollable Content Sheet
                ZStack {
                   
                    
                    FadingEdgeScrollView (
                        fadeHeight: 20,
                         topFadeEnabled: true,
                         bottomFadeEnabled: false,
                         blurEdgesEnabled: true
                    ){
                        VStack(alignment: .leading, spacing: 24) {
                            // Handle bar (optional visual cue)
                            Center {
                                Capsule()
                                    .fill(Color.blue.opacity(0.05))
                                    .frame(width: 60, height: 6)
                                    .padding(.top, 10)
                            }
                            
                            // Header (Title, Make, Rating)
                            headerSection
                            
                            // Description
                            if let description = car.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                    
                                    Button("Read More") {
                                        // Expand action
                                    }
                                    .font(.caption)
                                
                                    .foregroundColor(Color("AppSecondary"))
                                }
                            }
                            
                            // Overview Stats (Square Cards)
                            overviewSection
                            
                            // Features
                            if !car.features.isEmpty {
                                featuresSection
                            }
                            
                            // Location
                            if let location = car.location {
                                locationSection(location: location)
                            }
                            
                            // Related Cars
                            relatedCarsSection
                            
                            // Bottom Padding for Footer
                            Spacer().frame(height: 120)
                        }
                     
                        .padding(10)
                       
                 
                        
                     
                    }   .background(Color("AppPrimary"))
                }
                .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                
                // Negative padding to slightly overlap the rounded corners onto the image if desired,
                // but user said "won't enter to image". A small overlap for the corners proper is usually fine/expected for this design.
                // Let's stick to straight stacking if "won't enter" is strict.
                // However, without small overlap, the rounded corners show background color behind them at the corners of the image.
                // To fix that, we usually offset y by -30.
                // "Clip content so they wont enter to image on scroll"
                // If I offset by -30, the top 30pts of content layer covers the bottom 30pts of image.
                // This is typically NOT what they mean by "enter on scroll". They mean the scrolling content shouldn't go HIGHER.
                // So I will apply an offset of -30 to creates the visual "sheet" effect, but strict scrolling inside.
                .padding(.bottom, -65)
                
                .offset(y: -40)
                
                
            }
            .ignoresSafeArea(.all, edges: .top)
            
            // 3. Navigation Bar Buttons (Overlaid on Image)
            HStack {
                backButton
                Spacer()
                likeButton
            }
            .padding(.horizontal)
            .padding(.top, 60) // Safe area adjustment
            
            // 4. Floating Footer
            VStack {
                Spacer()
                bookingFooter
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .sheet(isPresented: $showingBookingView) {
            BookingView(car: car, routeInfo: defaultRouteInfo)
                .environmentObject(authModel)
        }
        .background(Color.white)
    }
    
    // MARK: - Components
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "arrow.left")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
    
    private var likeButton: some View {
        Button(action: { isLiked.toggle() }) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isLiked ? .red : .white)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
    
    private var imageCarousel: some View {
        TabView(selection: $selectedImage) {
            ForEach(Array(car.images.enumerated()), id: \.element) { index, imageUrl in
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image("car_placeholder")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .tag(imageUrl)
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .center)
                )
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .overlay(
            Group {
                if !car.images.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(currentIndex + 1)/\(car.images.count)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                .padding(.trailing, 16)
                                .padding(.bottom, 50) // Adjust this value to move the badge up or down
                        }
                    }
                }
            }
        )
        .onChange(of: selectedImage) { _, newImage in
             // Optional: Handle side effects if needed
        }
    }
    
    private var currentIndex: Int {
        guard let selectedImage = selectedImage else { return 0 }
        return car.images.firstIndex(of: selectedImage) ?? 0
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                
                HStack{
                    
                    Text(car.model)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        
                        .font(.subheadline)
                    Text(String(format: "%.1f", car.averageRating))
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(50)
            }
            
            
        }
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Overview")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(alignment:.center , spacing:10) {
                // Top Speed / Engine (using transmission as proxy or separate logic)
                OverviewCard(icon: "gauge.with.dots.needle.bottom.50percent", title: "Type", value: car.vehicleType.displayName)
                
                // Capacity
                OverviewCard(icon: "person.2.fill", title: "Capacity", value: "\(car.seatCount) Seats")
                
                // Fuel/Charging
                OverviewCard(icon: "fuelpump.fill", title: "Fuel", value: car.fuelType)
            }
            .frame(maxWidth: .infinity)
            .padding(2)
           
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(car.features, id: \.self) { feature in
                    Text(feature)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private func locationSection(location: Location) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
            // Existing location logic...
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(Color("Main"))
                
                VStack(alignment: .leading) {
                    Text(location.city)
                        .font(.headline)
                    Text(location.fullAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
        }
    }
    
    private var relatedCarsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Similar Cars")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    let related = vehicleDataManager.getAvailableVehiclesByType(car.vehicleType)
                        .filter { $0.id != car.id }
                    
                    if related.isEmpty {
                        Text("No similar cars found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(related) { relatedCar in
                            NavigationLink(value: relatedCar) {
                                RelatedCarCard(car: relatedCar)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    private var bookingFooter: some View {
        VStack {
            HStack(alignment: .center, spacing: 2) {
                Text("Rent Price")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(car.priceFormatted)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("/ Day")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            

            
            Button(action: { showingBookingView = true }) {
                HStack {
                    Image(systemName: "bag.fill")
                    Spacer()
                    Text("Book Now")
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chevron.right")
                    Image(systemName: "chevron.right")
                        .opacity(0.6)
                    Image(systemName: "chevron.right")
                        .opacity(0.3)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color("Main"))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
                .shadow(color: Color("Main").opacity(0.4), radius: 10, x: 0, y: 5)
            }
        }
        .padding()
       
        .background(.thickMaterial)
     // Rounded top corners effect for footer container if needed, or just float
        .clipShape(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
        .padding(4)
        
        
       
        .frame(maxWidth: .infinity)
    }
    
    private var defaultRouteInfo: RouteInfo {
        if let loc = car.location {
            let from = SearchLocation(
                placeId: loc.id,
                name: loc.city,
                address: loc.fullAddress,
                latitude: loc.latitude,
                longitude: loc.longitude,
                city: loc.city,
                country: loc.country,
                postalCode: loc.zipCode
            )
            return RouteInfo(
                fromLocation: from,
                toLocation: from,
                distance: "--",
                duration: "--",
                estimatedCost: car.priceFormatted,
                routePolyline: nil
            )
        } else {
            let placeholder = SearchLocation(
                placeId: nil,
                name: "Pickup Location",
                address: "Not specified",
                latitude: 0,
                longitude: 0,
                city: nil,
                country: nil,
                postalCode: nil
            )
            return RouteInfo(
                fromLocation: placeholder,
                toLocation: placeholder,
                distance: "--",
                duration: "--",
                estimatedCost: car.priceFormatted,
                routePolyline: nil
            )
        }
    }
    
    // Helper view for centering
    struct Center<Content: View>: View {
        let content: Content
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        var body: some View {
            HStack {
                Spacer()
                content
                Spacer()
            }
        }
    }
}

// MARK: - Supporting Views

struct OverviewCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack( spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primary)
                .padding(10)
             
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
            
   
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
       
        .frame(width: 120, height: 120)
        .background(Color("Main").opacity(0.05)) // Light tint
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("Main").opacity(0.1), lineWidth: 1)
        )
    }
}

struct RelatedCarCard: View {
    let car: Car
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: car.images.first ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 140, height: 90)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(car.make)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("Main"))
                
                Text(car.model)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(car.pricePerDayFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(10)
        }
        .frame(width: 140)
        
        .clipShape(RoundedRectangle(cornerRadius: 16))
        
    }
}

// Keep ReviewRow if needed for expansion
struct ReviewRow: View {
    let review: Review
    var body: some View {
        HStack {
            // simplified review row
            VStack(alignment: .leading) {
                HStack {
                    Text(review.author?.displayName ?? "User")
                        .font(.caption)
                        .fontWeight(.bold)
                    Spacer()
                    Text(review.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let comment = review.comment {
                    Text(comment)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return CarDetailView(car: Car.sampleCar)
        .environmentObject(mockAuthModel)
}


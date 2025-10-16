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
    @State private var selectedTab = "About"
    @State private var showingBookingView = false
    
    var body: some View {
  
            ZStack(alignment: .bottom) {
                // The background now consists of the image and a solid color, preventing a black screen.
                Color(.black).ignoresSafeArea()
                VStack(spacing: 0) {
                    AsyncImage(url: URL(string: car.images.first ?? "")) { image in
                        image.resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.45)
                            .clipped()
                    } placeholder: {
                        Color.gray
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.45)
                    }
                    Color(UIColor.systemGroupedBackground)
                }
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height * 0.45)
                .frame(maxHeight: .infinity, alignment: .top)
                

                // Draggable details card
                DraggableView(geometry: geometry) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        tabView
                        
                        if selectedTab == "About" {
                            aboutSection
                        } else if selectedTab == "Gallery" {
                            gallerySection
                        } else if selectedTab == "Review" {
                            reviewSection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)
                }

                // Header with back button, aligned to the top.
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text("Car Details")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                
                // Booking footer is now correctly aligned to the bottom.
                bookingFooter
            }
        
            .ignoresSafeArea()
        
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(car.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(car.make)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", car.averageRating))
                    .fontWeight(.semibold)
            }
            .font(.headline)
        }
    }

    // Tabs header
    private var tabView: some View {
        HStack {
            ForEach(["About", "Gallery", "Review"], id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(selectedTab == tab ? Color.black : Color.clear)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }

    // About section (specifications only)
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            specificationsSection
        }
    }

    private var specificationsSection: some View {
        VStack(alignment: .leading) {
            Text("Specifications")
                .font(.title2)
                .fontWeight(.bold)
            HStack(spacing: 16) {
                SpecificationIcon(icon: "person.3.fill", text: "\(car.seatCount) Seats")
                SpecificationIcon(icon: "bolt.fill", text: car.transmissionType)
                SpecificationIcon(icon: "fuelpump.fill", text: car.fuelType)
            }
        }
    }

    // Gallery section
    private var gallerySection: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                ForEach(car.images, id: \.self) { imageUrl in
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(10)
                    } placeholder: {
                        Color.gray.frame(height: 120)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }

    // Review section
    private var reviewSection: some View {
        VStack {
            let reviews = car.reviews ?? []
            if reviews.isEmpty {
                Text("No reviews yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(reviews) { review in
                            ReviewRow(review: review)
                        }
                    }
                }
            }
        }
    }

    // Review row component (nested)
    struct ReviewRow: View {
        let review: Review
        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    AsyncImage(url: URL(string: review.author?.profilePicture ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill").resizable()
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(review.author?.displayName ?? "Anonymous")
                            .font(.headline)
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < review.rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    Spacer()
                    Text(review.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let comment = review.comment, !comment.isEmpty {
                    Text(comment)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }

    // Booking footer
    private var bookingFooter: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Price")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text(car.priceFormatted)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)

            Spacer()

            Button(action: { showingBookingView = true }) {
                Text("Book Now")
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(red: 0.8, green: 1.0, blue: 0.0))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.black)
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.bottom, 8)
        .sheet(isPresented: $showingBookingView) {
            BookingView(car: car)
                .environmentObject(authModel)
        }
    }
}

struct DraggableView<Content: View>: View {
    @GestureState private var dragOffset = CGSize.zero
    @State private var position = CGSize.zero
    
    let geometry: GeometryProxy
    let content: Content
    
    init(geometry: GeometryProxy, @ViewBuilder content: () -> Content) {
        self.geometry = geometry
        self.content = content()
    }
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 40, height: 6)
                .foregroundColor(.gray)
                .padding(.vertical, 10)
            
            content
            
            Spacer()
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(50)
        .shadow(radius: 20)
        .offset(y: self.position.height + self.dragOffset.height + geometry.size.height * 0.35)
        .gesture(
            DragGesture()
                .updating($dragOffset, body: { (value, state, _) in
                    state = value.translation
                })
                .onEnded({ value in
                    let dragHeight = value.translation.height
                    let screenHeight = geometry.size.height
                    
                    if dragHeight < -screenHeight * 0.1 {
                        self.position.height = -screenHeight * 0.4
                    } else if dragHeight > screenHeight * 0.1 {
                        self.position.height = 0
                    }
                })
        )
        .animation(.interactiveSpring(), value: position)
        .animation(.interactiveSpring(), value: dragOffset)
    }
}

#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return CarDetailView(car: Car.sampleCar)
        .environmentObject(mockAuthModel)
}

struct SpecificationIcon: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(text)
                .font(.caption)
        }
    }
}

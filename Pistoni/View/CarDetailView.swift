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
  
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(car.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(car.make)
                    .font(.subheadline)
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

    private var tabView: some View {
        HStack {
            ForEach(["About", "Gallery", "Review"], id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(selectedTab == tab ? Color.black : Color.clear)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(4)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            specificationsSection
            Text("This vehicle is well-maintained and ideal for city and highway drives. Enjoy great mileage, comfort, and safety features for your trip.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var specificationsSection: some View {
        VStack(alignment: .leading) {
            Text("Specifications")
                .font(.headline)
                .fontWeight(.bold)
            HStack(spacing: 12) {
                SpecificationIcon(icon: "person.3.fill", text: "\(car.seatCount) Seats")
                SpecificationIcon(icon: "bolt.fill", text: car.transmissionType)
                SpecificationIcon(icon: "fuelpump.fill", text: car.fuelType)
            }
        }
    }

    private var gallerySection: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                ForEach(car.images, id: \.self) { imageUrl in
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(10)
                    } placeholder: {
                        Color.gray.frame(height: 100)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }

    private var reviewSection: some View {
        VStack {
            let reviews = car.reviews ?? []
            if reviews.isEmpty {
                VStack(alignment: .center) {
                    Text("No reviews yet.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .frame(alignment: .center)
                .background(Color("Accent"))
                .clipShape(Capsule())
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(reviews) { review in
                            ReviewRow(review: review)
                        }
                    }
                }
            }
        }
    }

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
                            .font(.subheadline)
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
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
        }
    }

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
                .font(.headline)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(text)
                .font(.caption2)
        }
    }
}


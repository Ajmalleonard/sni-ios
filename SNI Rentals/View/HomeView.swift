//
//  HomeView.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 21/07/2025.
//

import SwiftUI

// Sample car model matching schema.prisma crucial fields (excluding price)
struct CarDisplay: Identifiable {
    let id: String
    let make: String
    let model: String
    let year: Int
    let color: String
    let seatCount: Int
    
    let transmissionType: String
    let fuelType: String
    let imageURL: String?
}

enum HomeTab: String, CaseIterable {
    case home = "homepage"
    case rides = "calendar"
    case explore = "chatbox"
}

struct HomeView: View {
    // MARK: - State
    @EnvironmentObject var authModel: AuthModel
    @State private var selectedTab: HomeTab = .home
    @State private var showSearch = false
    @State private var searchText: String = ""
    @State private var showScheduleTrip = false
    
    
    // Dummy data – replace with real API fetch
    private let cars: [CarDisplay] = [
        CarDisplay(id: "1", make: "Porsche", model: "911", year: 2024, color: "Black", seatCount: 2, transmissionType: "Automatic", fuelType: "Petrol", imageURL: nil),
        CarDisplay(id: "2", make: "Toyota", model: "Camry", year: 2023, color: "Silver", seatCount: 5, transmissionType: "Automatic", fuelType: "Hybrid", imageURL: nil),
        CarDisplay(id: "3", make: "Tesla", model: "Model S", year: 2024, color: "White", seatCount: 5, transmissionType: "Automatic", fuelType: "Electric", imageURL: nil),
        CarDisplay(id: "4", make: "BMW", model: "X5", year: 2023, color: "Blue", seatCount: 7, transmissionType: "Automatic", fuelType: "Petrol", imageURL: nil)
    ]
    
    private let popularCars = ["Tesla Model 3", "Ferrari 488", "Lamborghini Huracan", "McLaren 720S"]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main content based on selected tab
                Group {
                    switch selectedTab {
                    case .home:
                        homeContent
                    case .rides:
                        ScheduleTripView()
                    case .explore:
                        ExploreView()
                    }
                }
                
                // Bottom Navigation
                BottomNavigationBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showScheduleTrip) {
            ScheduleTripView()
        }
    }
    
    var homeContent: some View {
        ZStack(alignment:.top) {
            backgroundGradient.ignoresSafeArea()
            VStack(spacing: 0) {
            // Header
                HeaderView().ignoresSafeArea(edges: .top)
            
           
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        
                        // Top Trends Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Top trends")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                Button("View all") {
                                    // View all action
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    .ultraThinMaterial,
                                    in: RoundedRectangle(
                                        cornerRadius: 50,
                                        style:.continuous
                                    )
                                    
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack(spacing: 16) {
                                    ForEach(cars.prefix(3)) { car in
                                        TrendingCarCard(car: car)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Popular Vehicles Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Popular vehicles")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Text("The perfect car for your trip!")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button("View all") {
                                    // View all action
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    .ultraThinMaterial,
                                    in: RoundedRectangle(
                                        cornerRadius: 50,
                                        style:.continuous
                                    ))
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(popularCars, id: \.self) { car in
                                        PopularCarCard(name: car)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        
                    }
                    .padding(.top, )
                }
            }
        }
    }
}

// MARK: - Trending Car Card
struct TrendingCarCard: View {
    let car: CarDisplay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Car image
            if let url = car.imageURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    ZStack {
                        Color(.systemGray6)
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 160)
                    .overlay(
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(car.make) \(car.model)").foregroundColor(.white)
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Label {
                        Text("\(car.seatCount) seats")
                            .font(.caption)
                            
                    } icon: {
                        Image(systemName: "person.2")
                            .font(.caption)
                          
                    }  .foregroundColor(.white)
                    
                    Label {
                        Text(car.transmissionType)
                            .font(.caption)
                           
                    } icon: {
                        Image(systemName: "gearshape")
                            .font(.caption)
                           
                    } .foregroundColor(.white)
                }
                
                HStack {
                    Text("$650")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("/day")
                        .font(.subheadline)
                        .foregroundColor(.white)
                } .foregroundColor(.white)
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Popular Car Card
struct PopularCarCard: View {
    let name: String
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .frame(width: 120, height: 100)
                .overlay(
                    Image(systemName: "car.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                )
            
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(width: 120)
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    @Binding var selectedTab: HomeTab
    
    var body: some View {
        HStack {
            ForEach(HomeTab.allCases, id: \.rawValue) { tab in
                Spacer()
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(tab.rawValue)
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 30,height: 30)
                            .foregroundColor(.white)
                        
                        
                    }
                    .foregroundColor(selectedTab == tab ? .primary : .secondary)
                }
                Spacer()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
                .ultraThinMaterial,                // forces a live blur
                in: RoundedRectangle(cornerRadius: 28,
                                     style: .continuous)
            )
            // 2️⃣ subtle white‑ish stroke for the frosted edge
            .overlay(
                RoundedRectangle(cornerRadius: 50, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            // 3️⃣ keep the blur inside the shape
            .compositingGroup()
            .foregroundColor(.primary)
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }
}


#Preview {
    HomeView().environmentObject(AuthModel())
}

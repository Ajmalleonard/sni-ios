import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    let categories = [
        ("Luxury", "crown.fill"),
        ("SUV", "car.2.fill"),
        ("Electric", "bolt.car.fill"),
        ("Sports", "speedometer"),
        ("Economy", "banknote.fill"),
        ("Convertible", "wind")
    ]
    
    let destinations = [
        "Dubai Marina",
        "Downtown Dubai",
        "Palm Jumeirah",
        "JBR Beach",
        "Business Bay",
        "DIFC"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search cars or locations...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Browse by Category")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(categories, id: \.0) { category in
                                CategoryCard(
                                    title: category.0,
                                    icon: category.1,
                                    isSelected: selectedCategory == category.0
                                ) {
                                    selectedCategory = selectedCategory == category.0 ? nil : category.0
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Popular Destinations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Popular Destinations")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(destinations, id: \.self) { destination in
                                    DestinationCard(name: destination)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Featured Deals
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Featured Deals")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            DealCard(
                                title: "Weekend Special",
                                description: "Get 20% off on weekend rentals",
                                color: .blue
                            )
                            
                            DealCard(
                                title: "Long Term Discount",
                                description: "Book for 7+ days and save 30%",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CategoryCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
    }
}

struct DestinationCard: View {
    let name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 100)
                .overlay(
                    Image(systemName: "building.2.crop.circle")
                        .font(.title)
                        .foregroundColor(.white)
                )
            
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct DealCard: View {
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

#Preview {
    ExploreView()
} 
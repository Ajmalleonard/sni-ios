import SwiftUI

// MARK: - Base Vehicle Type Home View
struct VehicleTypeHomeView: View {
    @StateObject private var vehicleDataManager = VehicleDataManager.shared
    @EnvironmentObject var authModel: AuthModel
    let vehicleType: VehicleType
    @State private var showingFilters = false
    @State private var showingCarDetail = false
    @State private var selectedCar: Car?
    @State private var filterState = FilterState()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section - ProfileView Style
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 16) {
                        // Vehicle Type Icon
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: vehicleType.icon)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            )
                        
                        // Vehicle Type Info
                        VStack(alignment: .leading, spacing: 1) {
                            Text(vehicleType.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("\(filteredCars.count) \(vehicleType.displayName)s available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .refreshable {
                            await vehicleDataManager.manualRefresh()
                        }
                        
                        Spacer()
                        
                        // Filter Button
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color("Primary"))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .padding(.horizontal, 20)
                
                // Main Content
                VStack(spacing: 15) {
                    // Quick Filters Section
                    ProfileSection(title: "Quick Filters") {
                        VStack(spacing: 0) {
                            QuickFilterMenuItem(
                                icon: "checkmark.circle",
                                title: "Available Only",
                                subtitle: "Show only available vehicles",
                                isSelected: filterState.status == .available,
                                action: {
                                    if filterState.status == .available {
                                        filterState.status = nil
                                    } else {
                                        filterState.status = .available
                                    }
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            QuickFilterMenuItem(
                                icon: "dollarsign.circle",
                                title: "Price Range",
                                subtitle: "Under $200 per day",
                                isSelected: filterState.maxPrice == 200,
                                action: {
                                    if filterState.maxPrice == 200 {
                                        filterState.maxPrice = nil
                                    } else {
                                        filterState.maxPrice = 200
                                    }
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            QuickFilterMenuItem(
                                icon: "person.2",
                                title: "5+ Seats",
                                subtitle: "Vehicles with 5 or more seats",
                                isSelected: filterState.seatCount == 5,
                                action: {
                                    if filterState.seatCount == 5 {
                                        filterState.seatCount = nil
                                    } else {
                                        filterState.seatCount = 5
                                    }
                                }
                            )
                        }
                    }
                    
                    // Available Vehicles Section
                    ProfileSection(title: "Available \(vehicleType.displayName)s") {
                        if vehicleDataManager.isLoading {
                            LoadingView()
                        } else if filteredCars.isEmpty {
                            EmptyStateView(
                                icon: vehicleType.icon,
                                title: "No \(vehicleType.displayName)s Found",
                                subtitle: "Try adjusting your filters or check back later"
                            )
                        } else {
                            VStack(spacing: 16) {
                                ForEach(filteredCars.prefix(5)) { car in
                                    VehicleCard(car: car) {
                                        selectedCar = car
                                        showingCarDetail = true
                                    }
                                }
                                
                                if filteredCars.count > 5 {
                                    Button {
                                        // TODO: Navigate to full list
                                    } label: {
                                        Text("View All \(filteredCars.count) \(vehicleType.displayName)s")
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    
                    // Recent Searches Section
                    ProfileSection(title: "Recent Searches") {
                        VStack(spacing: 0) {
                            ForEach(recentSearches, id: \.self) { search in
                                QuickFilterMenuItem(
                                    icon: "clock",
                                    title: search,
                                    subtitle: "Tap to search again",
                                    action: {
                                        // TODO: Apply recent search
                                    }
                                )
                                
                                if search != recentSearches.last {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 25)
                .padding(.horizontal, 25)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(vehicleType.displayName)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingFilters) {
            FilterView(initialFilter: filterState) { newFilter in
                filterState = newFilter
            }
        }
        .sheet(isPresented: $showingCarDetail) {
            if let selectedCar = selectedCar {
                CarDetailView(car: selectedCar)
                    .environmentObject(authModel)
            }
        }
        .onAppear {
            Task {
                await vehicleDataManager.initialFetch()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredCars: [Car] {
        var cars = vehicleDataManager.getVehiclesByType(vehicleType)
        
        // Apply additional filters
        if let status = filterState.status {
            cars = cars.filter { $0.status == status }
        }
        
        if let seatCount = filterState.seatCount {
            cars = cars.filter { $0.seatCount >= seatCount }
        }
        
        return cars
    }
    
    private var recentSearches: [String] {
        // TODO: Implement recent searches from UserDefaults
        return ["Under $100", "Automatic transmission", "Electric vehicles"]
    }
    
    // MARK: - Methods
    private func refreshData() async {
        await vehicleDataManager.refreshIfStale()
    }
}

// MARK: - Quick Filter Menu Item
struct QuickFilterMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    var isSelected: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : Color("Secondary"))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .blue : .primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vehicle Card
struct VehicleCard: View {
    let car: Car
    let action: () -> Void
    @State private var isPressed = false
    @State private var isFavorite = false
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 0) {
                // Car Image Section
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: car.primaryImage ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    Image(systemName: "car.fill")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                )
                        }
                        .frame(width: 120, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Unlimited Miles Badge
                    if car.features.contains("Unlimited Miles") || true { // Default to true for demo
                        Text("Unlimited Miles")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .padding(.top, 8)
                            .padding(.leading, 8)
                    }
                    
                    // Heart/Favorite Icon
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                isFavorite.toggle()
                            } label: {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 16))
                                    .foregroundColor(isFavorite ? .red : .white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                }
                
                // Car Details Section
                VStack(alignment: .leading, spacing: 8) {
                    // Car Name and Rating
                    VStack(alignment: .leading, spacing: 4) {
                        Text(car.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("5.0")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Location and Trip Count
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(car.location?.city ?? "San Francisco")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("91 Trips")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Price
                    VStack(alignment: .leading, spacing: 2) {
                        Text(car.pricePerDayFormatted)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("/Day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 12)
                .padding(.vertical, 12)
                
                Spacer()
                
                // Book Now Button
                VStack {
                    Spacer()
                    Button {
                        action()
                    } label: {
                        Text("Book Now")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 36)
                            .background(car.isAvailable ? Color.black : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .disabled(!car.isAvailable)
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
                }
            }
            .frame(height: 120)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            isPressed.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading vehicles...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 700)
    }
}


#Preview {
    NavigationView {
        VehicleTypeHomeView(
            vehicleType: .suv
        )
    }
}

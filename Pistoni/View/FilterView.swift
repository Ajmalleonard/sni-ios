import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var filterState: FilterState
    let onApplyFilters: (FilterState) -> Void
    
    init(initialFilter: FilterState = FilterState(), onApplyFilters: @escaping (FilterState) -> Void) {
        self._filterState = State(initialValue: initialFilter)
        self.onApplyFilters = onApplyFilters
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                   
                    
                    // Main Content
                    VStack(spacing: 15) {
                        // Vehicle Type Section
                        ProfileSection(title: "Vehicle Type") {
                            VStack(spacing: 0) {
                                ForEach(VehicleType.allCases, id: \.self) { vehicleType in
                                    FilterMenuItem(
                                        icon: vehicleType.icon,
                                        title: vehicleType.displayName,
                                        subtitle: "Browse \(vehicleType.displayName)s",
                                        isSelected: filterState.vehicleType == vehicleType,
                                        action: {
                                            filterState.vehicleType = filterState.vehicleType == vehicleType ? nil : vehicleType
                                        }
                                    )
                                    
                                    if vehicleType != VehicleType.allCases.last {
                                        Divider()
                                            .padding(.leading, 60)
                                    }
                                }
                            }
                        }
                        
                        // Price Range Section
                        ProfileSection(title: "Price Range") {
                            VStack(spacing: 0) {
                                PriceRangeSlider(
                                    minPrice: $filterState.minPrice,
                                    maxPrice: $filterState.maxPrice
                                )
                                
                                Divider()
                                    .padding(.leading, 60)
                                
                                FilterMenuItem(
                                    icon: "dollarsign.circle",
                                    title: "Price Range",
                                    subtitle: priceRangeText,
                                    action: {}
                                )
                            }
                        }
                        
                        // Seat Count Section
                        ProfileSection(title: "Seat Count") {
                            VStack(spacing: 0) {
                                ForEach([2, 4, 5, 7, 8, 12], id: \.self) { seatCount in
                                    FilterMenuItem(
                                        icon: "person.2",
                                        title: "\(seatCount) Seats",
                                        subtitle: "Vehicles with \(seatCount) seats",
                                        isSelected: filterState.seatCount == seatCount,
                                        action: {
                                            filterState.seatCount = filterState.seatCount == seatCount ? nil : seatCount
                                        }
                                    )
                                    
                                    if seatCount != 12 {
                                        Divider()
                                            .padding(.leading, 60)
                                    }
                                }
                            }
                        }
                        
                        // Transmission Type Section
                        ProfileSection(title: "Transmission") {
                            VStack(spacing: 0) {
                                ForEach(["Automatic", "Manual"], id: \.self) { transmission in
                                    FilterMenuItem(
                                        icon: "gearshape",
                                        title: transmission,
                                        subtitle: "\(transmission) transmission",
                                        isSelected: filterState.transmissionType == transmission,
                                        action: {
                                            filterState.transmissionType = filterState.transmissionType == transmission ? nil : transmission
                                        }
                                    )
                                    
                                    if transmission != "Manual" {
                                        Divider()
                                            .padding(.leading, 60)
                                    }
                                }
                            }
                        }
                        
                        // Fuel Type Section
                        ProfileSection(title: "Fuel Type") {
                            VStack(spacing: 0) {
                                ForEach(["Petrol", "Diesel", "Electric", "Hybrid"], id: \.self) { fuelType in
                                    FilterMenuItem(
                                        icon: fuelTypeIcon(for: fuelType),
                                        title: fuelType,
                                        subtitle: "\(fuelType) powered vehicles",
                                        isSelected: filterState.fuelType == fuelType,
                                        action: {
                                            filterState.fuelType = filterState.fuelType == fuelType ? nil : fuelType
                                        }
                                    )
                                    
                                    if fuelType != "Hybrid" {
                                        Divider()
                                            .padding(.leading, 60)
                                    }
                                }
                            }
                        }
                        
                        // Status Section
                        ProfileSection(title: "Availability") {
                            VStack(spacing: 0) {
                                ForEach([CarStatus.available, CarStatus.approved], id: \.self) { status in
                                    FilterMenuItem(
                                        icon: "checkmark.circle",
                                        title: status.displayName,
                                        subtitle: "\(status.displayName) vehicles",
                                        isSelected: filterState.status == status,
                                        action: {
                                            filterState.status = filterState.status == status ? nil : status
                                        }
                                    )
                                    
                                    if status != .approved {
                                        Divider()
                                            .padding(.leading, 60)
                                    }
                                }
                            }
                        }
                        
                        // Action Buttons Section
                        VStack(spacing: 12) {
                            // Apply Filters Button
                            Button {
                                onApplyFilters(filterState)
                                dismiss()
                            } label: {
                                Text("Apply Filters")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            
                            // Clear All Button
                            Button {
                                filterState = filterState.reset()
                            } label: {
                                Text("Clear All")
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                            
                            // Save Filter Preset Button
                            Button {
                                // TODO: Implement save filter preset
                            } label: {
                                Text("Save Filter Preset")
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 25)
                    }
                    .padding(.top, 25)
                    .padding(.horizontal, 25)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var priceRangeText: String {
        let min = filterState.minPrice ?? 0
        let max = filterState.maxPrice ?? 1000
        return "$\(Int(min)) - $\(Int(max)) per day"
    }
    
    private func fuelTypeIcon(for fuelType: String) -> String {
        switch fuelType {
        case "Petrol":
            return "fuelpump"
        case "Diesel":
            return "fuelpump.fill"
        case "Electric":
            return "bolt"
        case "Hybrid":
            return "bolt.fill"
        default:
            return "fuelpump"
        }
    }
}

// MARK: - Filter Menu Item
struct FilterMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    var isSelected: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .black : Color("Secondary").opacity(0.5))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .black : Color("Secondary").opacity(0.5))
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
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Price Range Slider
struct PriceRangeSlider: View {
    @Binding var minPrice: Double?
    @Binding var maxPrice: Double?
    
    @State private var minPriceValue: Double = 0
    @State private var maxPriceValue: Double = 1000
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Price Range")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("$\(Int(minPriceValue)) - $\(Int(maxPriceValue))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 25)
            
            RangeSlider(
                value: $minPriceValue,
                upperValue: $maxPriceValue,
                bounds: 0...1000,
                step: 10
            )
            .padding(.horizontal, 25)
            .onChange(of: minPriceValue) { _, _ in
                minPrice = minPriceValue
            }
            .onChange(of: maxPriceValue) { _, _ in
                maxPrice = maxPriceValue
            }
            .onAppear {
                minPriceValue = minPrice ?? 0
                maxPriceValue = maxPrice ?? 1000
            }
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Range Slider
struct RangeSlider: View {
    @Binding var value: Double
    @Binding var upperValue: Double
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Selected range
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat((upperValue - value) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width,
                           height: 4)
                    .offset(x: CGFloat((value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                    .cornerRadius(2)
                
                // Lower thumb
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                    .offset(x: CGFloat((value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 12)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * Double(gesture.location.x / geometry.size.width)
                                value = min(max(newValue, bounds.lowerBound), upperValue - step)
                            }
                    )
                
                // Upper thumb
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                    .offset(x: CGFloat((upperValue - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 12)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * Double(gesture.location.x / geometry.size.width)
                                upperValue = max(min(newValue, bounds.upperBound), value + step)
                            }
                    )
            }
        }
        .frame(height: 24)
    }
}

#Preview {
    FilterView { _ in }
}

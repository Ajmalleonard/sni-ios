import SwiftUI
// Car display model - Updated to use new Car model
// The Car model is now defined in CarModels.swift

struct TrendingCarCard: View {
    let car: Car
    let action: (() -> Void)?
    @State private var isPressed = false
    @State private var isFavorite = false
    
    init(car: Car, action: (() -> Void)? = nil) {
        self.car = car
        self.action = action
    }
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 0) {
                // Car Image Section
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: car.primaryImage ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                Image(systemName: "car.fill")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            )
                    }
                    .frame(width: 160, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
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
                            Text(String(format: "%.1f", car.averageRating > 0 ? car.averageRating : 5.0))
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
                            Text("\(car.rentals?.count ?? 0) Trips")
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
                        action?()
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

// MARK: - Popular Car Card
struct PopularCarCard: View {
    let car: Car
    let action: (() -> Void)?
    @State private var isPressed = false
    @State private var isFavorite = false
    
    init(car: Car, action: (() -> Void)? = nil) {
        self.car = car
        self.action = action
    }
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 0) {
                // Car Image Section
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: car.primaryImage ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                Image(systemName: "car.fill")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            )
                    }
                    .frame(width: 160, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
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
                            Text(String(format: "%.1f", car.averageRating > 0 ? car.averageRating : 5.0))
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
                                .clipShape(RoundedCorner(radius:20))
                            Text(car.location?.city ?? "San Francisco")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                              
                            Text("\(car.rentals?.count ?? 0) Trips")
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
                        action?()
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

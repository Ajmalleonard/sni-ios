
import SwiftUI
// MARK: - Car List Item (Updated to match horizontal card design)
struct CarListItem: View {
    let car: Car
    let action: () -> Void
    @State private var isPressed = false
    @State private var isFavorite = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Car Image Section
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: car.primaryImage ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure(_):
                            // Error state - show placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "car.fill")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                )
                        case .empty:
                            // Loading state - skeleton with blur effect
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(.systemGray6), Color(.systemGray5), Color(.systemGray6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.3))
                                        .blur(radius: 1)
                                        .animation(
                                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                            value: UUID()
                                        )
                                )
                                .overlay(
                                    Image(systemName: "car.fill")
                                        .font(.title2)
                                        .foregroundColor(.secondary.opacity(0.6))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Unlimited Miles Badge
                    if car.features.contains("Unlimited Miles") || true { // Default to true for demo
                        Text("Unlimited Miles")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
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
                                let generator = UIImpactFeedbackGenerator(style: .heavy)
                                          generator.impactOccurred()

                                      
                                
                                isFavorite.toggle()
                            } label: {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 16))
                                    .foregroundColor(isFavorite ? .red : .red)
                                    .frame(width: 28, height: 28)
                                    .background(Color.white.opacity(1))
                                    .clipShape(Circle())
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                }
                
                // Car Details Section
                VStack(alignment: .leading,) {
                    // Car Name and Rating
                    HStack( spacing: 4) {
                        Text(car.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
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
                    HStack( spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "map.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(car.location?.city ?? "San Francisco")
                                .font(.caption)
                                .foregroundColor(.black)
                        }.padding(.horizontal,8)
                            .padding(.vertical,8)
                            .background(.blue.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "handbag")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("\(car.rentals?.count ?? 0) Trips")
                                .font(.caption)
                                .foregroundColor(.black)
                              
                                
                          
                        }
                        .padding(.horizontal,8)
                        .padding(.vertical,8)
                        .background(.blue.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        Spacer()
                    }
                    
                    
                    
                   
                }
                .padding(.leading, 12)
                .padding(.vertical, 12)
               
            
                
                // Book Now Button
                HStack {
                    // Price
                    VStack(alignment: .leading, spacing: 2) {
                        Text(car.pricePerDayFormatted)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                    }
                    Spacer()
                    Button {
                        action()
                    } label: {
                        Text("Book Now")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 36)
                            .background(!car.isAvailable ? Color.black : Color.gray)
                            .clipShape(Capsule())
                    }
                    .disabled(!car.isAvailable)
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
                }
            }
           
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
          
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

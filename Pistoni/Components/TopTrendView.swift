import SwiftUI

struct TopTrendView: View {
    let cars: [Car]
    var onViewAllTapped: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top trends")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                Button("View all") {
                    onViewAllTapped()
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
            
            // Change from horizontal ScrollView to vertical VStack
            VStack(spacing: 50) {
                ForEach(cars.prefix(3)) { car in
                    TrendingCarCard(car: car)
                        .padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

struct PopularVehiclesView: View {
    let popularCars: [Car]
    var onViewAllTapped: () -> Void = {}
    
    var body: some View {
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
                    onViewAllTapped()
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
                HStack(spacing: 20) {
                    ForEach(popularCars, id: \.id) { car in
                        PopularCarCard(car: car)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .padding(.top, 20)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.8).ignoresSafeArea()
        
        VStack(spacing: 30) {
            TopTrendView(cars: Car.sampleCars)
            
            PopularVehiclesView(popularCars: Car.sampleCars)
        }
    }
}

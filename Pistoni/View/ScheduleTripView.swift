import SwiftUI

struct ScheduleTripView: View {
    @Environment(\.dismiss) var dismiss
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400) // +1 day
    @State private var pickupLocation = ""
    @State private var dropoffLocation = ""
    @State private var selectedCar: CarDisplay?
    @State private var showingCarPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Trip Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trip Details")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            // Trip Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Trip Name")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("Weekend Getaway", text: $tripName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding(.horizontal)
                            
                            // Date Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Dates")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    DatePicker("Start", selection: $startDate, displayedComponents: [.date])
                                        .datePickerStyle(.compact)
                                    
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.secondary)
                                    
                                    DatePicker("End", selection: $endDate, displayedComponents: [.date])
                                        .datePickerStyle(.compact)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Location Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pickup Location")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("Enter pickup location", text: $pickupLocation)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Drop-off Location")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("Enter drop-off location", text: $dropoffLocation)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Car Selection
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Select Vehicle")
                                .font(.headline)
                            Spacer()
                            Button("Browse") {
                                showingCarPicker = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if let car = selectedCar {
                            HStack {
                                Image(systemName: "car.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                    .frame(width: 60, height: 60)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                
                                VStack(alignment: .leading) {
                                    Text("\(car.make) \(car.model)")
                                        .font(.headline)
                                    Text("\(car.seatCount) seats • \(car.transmissionType)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    selectedCar = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        } else {
                            Button {
                                showingCarPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Add a vehicle")
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Schedule Trip")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save trip logic
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(tripName.isEmpty || pickupLocation.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ScheduleTripView()
} 
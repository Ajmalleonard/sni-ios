import SwiftUI


struct Badge: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            HStack(spacing: 18) {
                // — Icon —
                ZStack {
                    Circle()
                        .fill(Color.black)                 // dark circle
                    Image(systemName: "checkmark.seal")    // swap for any SF-Symbol you like
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 72, height: 72)
                
                // — Text —
                VStack(alignment: .leading, spacing: 4) {
                    Text("SNI Premium")
                        .font(.title3.weight(.semibold))
                    
                    Text("You enjoying full access of App")
                        .font(.body)
                }
                .foregroundStyle(.black)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                // Rounded container with a mesh gradient
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        MeshGradient(
                            width: 3, height: 3,
                            // Positions are in the 0–1 unit square; tweak for your exact look
                            points: [
                                [-0.2, -0.2], [0.5, 0.0], [1.2, -0.1],
                                [0.0,  0.5], [0.5, 0.5], [1.0,  0.6],
                                [-0.1, 1.1], [0.5, 1.1], [1.1,  1.2]
                            ],
                            // Soft pink palette (left-top lighter, bottom-right slightly deeper)
                            colors: [
                                Color(red: 1.00, green: 0.90, blue: 0.95), // pale pink
                                Color(red: 1.00, green: 0.84, blue: 0.92),
                                Color(red: 1.00, green: 0.78, blue: 0.88),
                                Color(red: 1.00, green: 0.88, blue: 0.94),
                                Color(red: 1.00, green: 0.82, blue: 0.90),
                                Color(red: 1.00, green: 0.75, blue: 0.86),
                                Color(red: 0.98, green: 0.92, blue: 0.96), // hint of peach top-left
                                Color(red: 1.00, green: 0.84, blue: 0.92),
                                Color(red: 0.95, green: 0.78, blue: 0.89)
                            ]
                        )
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        } else {
            // Fallback on earlier versions
        }
    }
}

#Preview {

        Badge()
   
    
}

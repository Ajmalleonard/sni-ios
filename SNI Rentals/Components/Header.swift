import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var authModel: AuthModel
    @State private var showLocationPicker = false
    
    // Reduce header height for more compact design
    private let headerHeight: CGFloat = 50
    
    var body: some View {
        ZStack(alignment: .top) {
            // Content container with proper safe area handling
            VStack(spacing: 0) {
                // Main content with reduced spacing
                VStack(spacing: 0) {
                    topBar
                }
                .padding(.top, 8)
            }
        }
        .frame(height: headerHeight)
        .clipShape(
            RoundedCorners(radius: 40, corners: [.bottomLeft, .bottomRight])
        )
    }
}

// MARK: Background (image clipped, faded & blurred at bottom)

private extension HeaderView {
    var headerBackground: some View {
        GeometryReader { geo in
            Image("header_bg")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .opacity(0.4)
                .background(.black)
                .clipShape(RoundedCorners(radius: 28, corners: [.bottomLeft, .bottomRight]))
                // Darken toward bottom so text is readable
                .overlay(
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.25), .black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // Fade out very bottom pixels
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.82),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // Extra blur strip overlayed on bottom edge
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: 70)
                        .blur(radius: 18)
                        .offset(y: 18)
                }
        }
    }
    
    var topBar: some View {
        HStack(alignment: .center, spacing: 6) {
            Text("Welcome back!")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
          
            Button {
                // Profile action
            } label: {
                ProfileAvatar(
                    urlString: authModel.currentUser?.profilePicture,
                    placeholder: authModel.currentUser?.displayName
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    var bodySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Hello, \(authModel.currentUser?.name ?? "Guest")")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}

// MARK: - Helpers --------------------------------------------------------------

struct CircleIcon: View {
    var icon: String
    var showBadge: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(12)
                .overlay(
                    Circle().stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            if showBadge {
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .offset(x: 4, y: -4)
            }
        }
        .foregroundColor(.primary)
    }
}

struct CircleImage: View {
    var image: String
    var showBadge: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(image)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(12)
                .foregroundColor(Color("Secondary"))
                .overlay(
                    Circle().stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            if showBadge {
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
                    .offset(x: 4, y: -4)
            }
        }
        .foregroundColor(.primary)
    }
}

struct ProfileAvatar: View {
    var urlString: String?
    var placeholder: String?
    
    var body: some View {
        AsyncImage(url: URL(string: urlString ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Image("user")
                .resizable()
                .renderingMode(.template)
                .frame(width: 30, height: 30)
                
        }
        .frame(width: 45, height: 45)
        .clipShape(Circle())
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 50,
                                 style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 50, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .compositingGroup()
        .foregroundColor(.white)
    }
}

// RoundedCorners shape to clip specific corners
struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        Path(
            UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            ).cgPath
        )
    }
}

// MARK: - Minimal Auth Model for Preview --------------------------------------
// MARK: Dark‑green mesh background  (iOS 17+)
@available(iOS 18.0, *)
var backgroundGradient: some View {
    MeshGradient(
        width: 3,                       // 3 columns
        height: 3,                      // 3 rows
        points: [
            // ── row‑0 ───────────────
            [0.0, 0.0],   [0.5, 0.0],   [1.0, 0.0],
            // ── row‑1 ───────────────
            [0.0, 0.5],   [0.8, 0.9],   [1.0, 0.5],
            // ── row‑2 ───────────────
            [0.0, 1.0],   [0.5, 1.0],   [1.0, 1.0]
        ],
        colors: [
            // row‑0 colours ↴  (rich green "glow" across the top)
            Color(red: 0.20, green: 0.45, blue: 0.30),   // forest green
            Color(red: 0.32, green: 0.60, blue: 0.40),   // bright emerald
            Color(red: 0.18, green: 0.40, blue: 0.28),   // deep jade
            // row‑1 colours ↴  (transition to darkness)
            Color(red: 0.08, green: 0.20, blue: 0.14),   // dark teal
            Color(red: 0.05, green: 0.10, blue: 0.08),   // near‑black green
            Color(red: 0.07, green: 0.16, blue: 0.12),   // deep spruce
            // row‑2 colours ↴  (pure shadows)
            .black,
            Color(red: 0.04, green: 0.05, blue: 0.05),
            .black
        ],
              // keep blends soft; lower → sharper blobs
    )
}


// MARK: - Preview --------------------------------------------------------------

#Preview {
    NavigationStack {
        HeaderView()
            .environmentObject(AuthModel())
    }
}

import SwiftUI

struct MessageSheetView: View {
    let errorMessage: String?
    let successMessage: String?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            VStack {
#if os(iOS)
            if #available(iOS 26, *) {
                Image("errormoji").resizable()
                    .frame(width: 300, height: 300)
            }
#endif
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                if let successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                onDismiss()
            } label: {
                Text("Dismiss")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(Color("AppPrimary"))
                    .background(Color("AppSecondary"))
                    .clipShape(Capsule())
            }

        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    MessageSheetView(errorMessage: "This is an error message.", successMessage: "This is a success message.") {}
}

import SwiftUI

struct ResendVerificationView: View {
    @State private var email: String = ""
    @State private var isLoading = false
    @StateObject private var authModel = AuthModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            ZStack {
                Color("Primary").ignoresSafeArea()
                VStack(spacing: 32) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                        .foregroundColor(Color("Secondary"))
                    }
                    
                    VStack(spacing: 2) {
                        Image("sni_white")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .padding(.bottom, 30)
                            .foregroundColor(Color("Secondary"))
                        
                        Text("Verify Email")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Text("Resend your verification code")
                            .font(.callout)
                    }
                    .padding()
                    
                    VStack(spacing: 16) {
                        TextField("Your Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.clear))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                        
                        Button(action: resendVerification) {
                            Text("Resend Verification Email")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Secondary"))
                                .foregroundColor(Color("Primary"))
                                .clipShape(Capsule())
                        }
                        .disabled(authModel.isLoading || email.isEmpty)
                    }
                    
                    // Error and Success Messages
                    if let errorMessage = authModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, -10)
                    }
                    
                    if let successMessage = authModel.successMessage {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.footnote)
                            .padding(.top, -10)
                    }
                    
                    // Help Text
                    VStack(spacing: 8) {
                        Text("Didn't receive the code?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Check your spam folder or try again in a few minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
        }
        .loadingOverlay(isLoading: authModel.isLoading)
        .onChange(of: authModel.successMessage) { newValue in
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
    
    private func resendVerification() {
        isLoading = true
        // TODO: Implement resend verification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            authModel.setSuccessMessage("Verification code sent successfully")
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    ResendVerificationView()
} 

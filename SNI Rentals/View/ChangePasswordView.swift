import SwiftUI

struct ChangePasswordView: View {
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
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
                        
                        Text("Change Password")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Text("Update your account password")
                            .font(.callout)
                    }
                    .padding()
                    
                    VStack(spacing: 16) {
                        SecureField("Current Password", text: $currentPassword)
                            .padding()
                            .background(Color(.clear))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                        
                        SecureField("New Password", text: $newPassword)
                            .padding()
                            .background(Color(.clear))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                        
                        SecureField("Confirm New Password", text: $confirmPassword)
                            .padding()
                            .background(Color(.clear))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                        
                        Button(action: { authModel.changePassword(currentPassword: currentPassword, newPassword: newPassword) }) {
                            if authModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Update Password")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("Secondary"))
                                    .foregroundColor(Color("Primary"))
                                    .clipShape(Capsule())
                            }
                        }
                        .disabled(authModel.isLoading || !isValidInput)
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
                    
                    // Password requirements
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password requirements:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Minimum 8 characters")
                            .font(.caption)
                            .foregroundColor(newPassword.count >= 8 ? .green : .secondary)
                        Text("• At least one uppercase letter")
                            .font(.caption)
                            .foregroundColor(newPassword.contains(where: { $0.isUppercase }) ? .green : .secondary)
                        Text("• At least one number")
                            .font(.caption)
                            .foregroundColor(newPassword.contains(where: { $0.isNumber }) ? .green : .secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
        }
        .onChange(of: authModel.successMessage) { newValue in
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8 &&
        newPassword.contains(where: { $0.isUppercase }) &&
        newPassword.contains(where: { $0.isNumber })
    }
    
    private func changePassword() {
        isLoading = true
        // TODO: Implement password change
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            authModel.setSuccessMessage("Password updated successfully")
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

#Preview {
    ChangePasswordView()
} 
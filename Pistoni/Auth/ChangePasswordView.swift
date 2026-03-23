import SwiftUI

struct ChangePasswordView: View {
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading = false
    @StateObject private var authModel = AuthModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showMessageSheet: Bool = false
    
    var body: some View {
        ScrollView {
            ZStack {
                Color("white").ignoresSafeArea()
                VStack(spacing: 32) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                        .foregroundColor(Color("AppSecondary"))
                    }
                    
                    VStack(spacing: 2) {
                        Image("sni_white")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .padding(.bottom, 30)
                            .foregroundColor(Color("AppSecondary"))
                        
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
                            .cornerRadius(100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                        
                        SecureField("New Password", text: $newPassword)
                            .padding()
                            .background(Color(.clear))
                            .cornerRadius(100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                        
                        SecureField("Confirm New Password", text: $confirmPassword)
                            .padding()
                            .background(Color(.clear))
                            .cornerRadius(100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                        
                        Button(action: { authModel.changePassword(currentPassword: currentPassword, newPassword: newPassword) }) {
                            Text("Update Password")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AppSecondary"))
                                .foregroundColor(Color("AppPrimary"))
                                .clipShape(Capsule())
                        }
                        .disabled(authModel.isLoading || !isValidInput)
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
        .onChange(of: authModel.successMessage) { _, newValue in
            if newValue != nil {
                showMessageSheet = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
        .onChange(of: authModel.errorMessage) { _, newValue in
            showMessageSheet = newValue != nil
        }
        .loadingOverlay(isLoading: authModel.isLoading)
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showMessageSheet) {
            MessageSheetView(
                errorMessage: authModel.errorMessage,
                successMessage: authModel.successMessage,
                onDismiss: { showMessageSheet = false }
            )
            .padding(.horizontal, 32)
            .presentationDetents([.height(UIScreen.main.bounds.height * 0.4)])
            .presentationDragIndicator(.visible)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white)
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

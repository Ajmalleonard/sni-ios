import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var newPassword: String = ""
    @State private var isLoading = false
    @State private var step: ResetPasswordStep = .enterEmail
    @StateObject private var authModel = AuthModel()
    
    enum ResetPasswordStep {
        case enterEmail
        case enterCode
        case enterNewPassword
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                Color("Primary").ignoresSafeArea()
                VStack(spacing: 32) {
                    HStack {
                        Spacer()
                        Button {
                            // TODO: Dismiss view
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
                        
                        Text("Reset Password")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Text("We'll help you get back into your account")
                            .font(.callout)
                    }
                    .padding()
                    
                    VStack(spacing: 10) {
                        // Email field (always visible)
                        TextField("Your Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(step != .enterEmail ? Color.gray.opacity(0.2) : Color(.clear))
                            .cornerRadius(15)
                            .disabled(step != .enterEmail)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                        
                        if step == .enterEmail {
                            Button(action: requestResetCode) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Send Reset Code")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color("Secondary"))
                                        .foregroundColor(Color("Primary"))
                                        .clipShape(Capsule())
                                }
                            }
                            .disabled(isLoading || !isValidEmail(email))
                        }
                        
                        if step == .enterCode {
                            TextField("6-digit code", text: $code)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(.clear))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color("Accent"), lineWidth: 1)
                                )
                                .onChange(of: code) { oldValue, newValue in
                                    if newValue.count == 6 {
                                        verifyCode()
                                    }
                                }
                        }
                        
                        if step == .enterNewPassword {
                            SecureField("New Password", text: $newPassword)
                                .padding()
                                .background(Color(.clear))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color("Accent"), lineWidth: 1)
                                )
                            
                            Button(action: resetPassword) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Reset Password")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color("Secondary"))
                                        .foregroundColor(Color("Primary"))
                                        .clipShape(Capsule())
                                }
                            }
                            .disabled(isLoading || newPassword.count < 6)
                        }
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
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
        }
    }
    
    private func requestResetCode() {
        isLoading = true
        // TODO: Implement reset code request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            withAnimation {
                step = .enterCode
            }
        }
    }
    
    private func verifyCode() {
        isLoading = true
        // TODO: Implement code verification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            withAnimation {
                step = .enterNewPassword
            }
        }
    }
    
    private func resetPassword() {
        isLoading = true
        // TODO: Implement password reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            // TODO: Navigate back to login
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    ForgotPasswordView()
} 
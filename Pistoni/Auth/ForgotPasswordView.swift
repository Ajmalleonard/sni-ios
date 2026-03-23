import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var newPassword: String = ""
    @State private var isLoading = false
    @State private var step: ResetPasswordStep = .enterEmail
    @StateObject private var authModel = AuthModel()
    @State private var showMessageSheet: Bool = false
    
    enum ResetPasswordStep {
        case enterEmail
        case enterCode
        case enterNewPassword
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                Color("AppPrimary").ignoresSafeArea()
                VStack(spacing: 32) {
                 
                    HStack(){
                        Spacer()
                        Image("logo")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .padding(.bottom, 30)
                            .foregroundColor(Color("AppSecondary"))
                      
                    }
                    Spacer(minLength: 50)
                    VStack(spacing: 2) {
                        
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
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color("Accent"), lineWidth: 0.1)
                            )
                        
                        Spacer(minLength: 10)
                        
                        if step == .enterEmail {
                            Button(action: requestResetCode) {
                                Text("Send Reset Code")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("AppSecondary"))
                                    .foregroundColor(Color("AppPrimary"))
                                    .clipShape(Capsule())
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
                            Spacer(minLength: 10)
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
                                Text("Reset Password")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("AppSecondary"))
                                    .foregroundColor(Color("AppPrimary"))
                                    .clipShape(Capsule())
                            }
                            .disabled(isLoading || newPassword.count < 6)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
            }
        }
        .loadingOverlay(isLoading: authModel.isLoading)
        .onChange(of: authModel.errorMessage) { _, newValue in
            showMessageSheet = newValue != nil
        }
        .onChange(of: authModel.successMessage) { _, newValue in
            if newValue != nil {
                showMessageSheet = true
            }
        }
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

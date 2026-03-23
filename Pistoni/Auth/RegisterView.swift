//
//  RegisterView.swift
//  SNI Rentals
//
//  Created by Jesus on 7/5/25.
//
import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseAuth
import CryptoKit


struct RegisterView: View {
    @State var name : String = ""
    @State var isVerified : Bool =  false
    @State var email : String = ""
    @State var password : String = ""
    @State private var showEmailVerification: Bool = false
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    
    @State var AuthErrorMessage: String = ""
    @State var showAuthAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var showMessageSheet: Bool = false
    @State private var nonce: String?
    @AppStorage("log_Status") private var logStatus: Bool = false
    
    var body: some View {
        ScrollView {
            ZStack {
             
                VStack(spacing: 32) {
                    VStack(alignment:.leading ,spacing: 2) {
                        Text("Create an account")
                            .font(.title2)
                            .foregroundColor(Color("AppSecondary"))
                    }
                    .padding()
                    VStack(spacing: 12) {
                        SignInWithAppleButton(.signIn){request in
                            let nonce = randomNonceString()
                            self.nonce = nonce
                            
                            
                            request.requestedScopes = [.email, .fullName]
                            request.nonce = sha256(nonce)
                            
                            
                        }onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                loginWithApple(authorization)
                            case .failure(let error):
                                showError(error.localizedDescription)
                                
                            }
                            
                            
                        }.frame(minHeight: 55).clipShape(Capsule())

                        
                        
                        
                        
                  
                        
                        
                       
                        
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack {
                                Image("google")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width:30, height: 30)
                                    .foregroundColor(Color("AppSecondary"))
                                Text("Continue With Google").padding(.horizontal,10)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .clipShape(Capsule())
                            .foregroundColor(Color("AppSecondary"))
                            .overlay(
                                RoundedRectangle(cornerRadius: .infinity)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 2) // Border color and width
                                           )
                        }
                        .disabled(authModel.isLoading)
                    }
                    .padding(.horizontal, 32)
                
                    
                    // Or Divider
                    HStack {
//                        Rectangle()
//                            .fill(Color("Accent"))
//                            .frame(height: 1)
                        Text("or")
                            .padding(.horizontal, 16)
                            .foregroundColor(Color("AppSecondary"))
//                        Rectangle()
//                            .fill(Color("Accent"))
//                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    VStack(spacing: 16) {
                        // Email field (always visible)
                        VStack(alignment: .leading, spacing: 0){
                            TextField("Your Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(20)
                                .background(authModel.registrationStep == .enterDetails ? Color.gray.opacity(0.1) : Color.clear)
                                .disabled(authModel.registrationStep == .enterDetails)
                                .overlay(
                                    RoundedRectangle(cornerRadius: .infinity)
                                        .stroke(Color("Accent"), lineWidth: 1)
                                )
                                .foregroundColor(Color("AppSecondary"))
                        }.frame(maxWidth: .infinity)
                        
                        // Show verify button if in email step
//                        if authModel.registrationStep == .enterEmail {
//                            Button(action: verifyEmail) {
//                                Text("Create account")
//                                    .fontWeight(.semibold)
//                                    .frame(maxWidth: .infinity)
//                                    .padding(20)
//                                    .background(Color("AppSecondary"))
//                                    .foregroundColor(Color("AppPrimary"))
//                                    .clipShape(Capsule())
//                            }
//                            .disabled(!isValidEmail(email))
//                        }
                        
                        
                        // Registration fields (animated in)
                        if authModel.registrationStep == .enterDetails {
                            VStack(spacing: 16) {
                                TextField("Your Name", text: $name)
                                    .autocapitalization(.words)
                                    .padding()
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color("Accent"), lineWidth: 1)
                                    )
                                    .foregroundColor(Color("AppSecondary"))
                                
                                SecureField("Your Password", text: $password)
                                    .padding()
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color("Accent"), lineWidth: 1)
                                    )
                                    .foregroundColor(Color("AppSecondary"))
                                
                                Button(action: completeRegistration) {
                                    if authModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else {
                                        Text("Sign Up")
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color("AppSecondary"))
                                            .foregroundColor(Color("AppPrimary"))
                                            .clipShape(Capsule())
                                    }
                                }
                                .disabled(authModel.isLoading || name.isEmpty || password.isEmpty)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Login prompt
                    VStack{
                        Text("Signing up for Pistoni account means you")
                        HStack{
                            Text("agree to the")
                            NavigationLink("Privacy Policy",destination: LoginView().environmentObject(authModel)).underline()
                            Text("and")
                            NavigationLink("Terms of Service.",destination: LoginView().environmentObject(authModel)).underline()
                        }}
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.horizontal,20)
                    .font(.caption)
                    
                    HStack {
                        Text("Have an account?")
                            .foregroundColor(Color("AppSecondary").opacity(0.7))
                        NavigationLink("Log in here", destination: LoginView().environmentObject(authModel).navigationBarHidden(true))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("Accent"))
                            .underline()
                    }
                    .font(.footnote)
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .alert(AuthErrorMessage, isPresented: $showAuthAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $showEmailVerification) {
            EmailVerificationView(email: email)
                .environmentObject(authModel)
        }
        .onChange(of: authModel.errorMessage) { _, newValue in
            showMessageSheet = newValue != nil
        }
        .onChange(of: authModel.successMessage) { _, newValue in
            if newValue != nil {
                showMessageSheet = true
                logStatus = true
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
    
    private func verifyEmail() {
        showEmailVerification = true
    }
    
    private func verifyCode() {
        authModel.verifyEmailCode(email: email, code: "")
    }
    
    private func completeRegistration() {
        authModel.completeRegistration(email: email, password: password, name: name, phoneNumber: nil, role: .client)
    }
    
    private func signInWithGoogle() {
        authModel.signInWithGoogle()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func showError(_ message: String){
        AuthErrorMessage = message
        showAuthAlert.toggle()
        isLoading = false
    }
    
    private func randomNonceString(length: Int = 32) -> String {
            precondition(length > 0)
            var randomBytes = [UInt8](repeating: 0, count: length)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                )
            }
            
            let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
            
            let nonce = randomBytes.map { byte in
                // Pick a random character from the set, wrapping around if needed.
                charset[Int(byte) % charset.count]
            }
            
            return String(nonce)
        }
        
        private func sha256(_ input: String) -> String {
            let inputData = Data(input.utf8)
            let hashedData = SHA256.hash(data: inputData)
            let hashString = hashedData.compactMap {
                String(format: "%02x", $0)
            }.joined()
            
            return hashString
        }
    
    func loginWithApple(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            showError("Apple Sign-In credential is not available.")
            return
        }
        
        guard self.nonce != nil else {
            showError("Nonce is missing.")
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            showError("Unable to get ID token from Apple credential.")
            return
        }
        
        guard let authorizationCode = appleIDCredential.authorizationCode,
              let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
            showError("Unable to get authorization code from Apple credential.")
            return
        }
        
        let userIdentifier = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        // Create the DTO for the backend
        let appleOAuthDto = AppleOAuthDto(
            identityToken: idTokenString,
            authorizationCode: authCodeString,
            email: email,
            fullName: PersonNameComponentsDto(
                givenName: fullName?.givenName,
                familyName: fullName?.familyName
            ),
            userIdentifier: userIdentifier
        )
        
        // Send the DTO to your backend
        authModel.signInWithApple(appleOAuthDto: appleOAuthDto) { result in
            switch result {
            case .success(let loginResponse):
                // Handle successful authentication
                print("Successfully signed in with Apple: \(loginResponse.user)")
                logStatus = true
                dismiss()
            case .failure(let error):
                showError(error.localizedDescription)
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthModel())
}

// Shake animation modifier
struct Shake: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(animatableData * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - DTOs for Backend Communication
nonisolated struct AppleOAuthDto: Codable, Sendable {
    let identityToken: String
    let authorizationCode: String
    let email: String?
    let fullName: PersonNameComponentsDto?
    let userIdentifier: String
}

nonisolated struct PersonNameComponentsDto: Codable, Sendable {
    let givenName: String?
    let familyName: String?
}

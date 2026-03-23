//
//  AuthChoiceView.swift
//  SNI Rentals
//
//  Created by Jesus on 1/22/25.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthChoiceView: View {


    
    @EnvironmentObject private var authModel: AuthModel
    @State private var nonce: String?
    @AppStorage("log_Status") private var logStatus: Bool = false
    @State private var showMessageSheet: Bool = false
    
    var body: some View {
        NavigationStack {
                ZStack {
                    Image("bg")
                        .resizable()
                        .ignoresSafeArea()
                        .blur(radius: 20)
                        .opacity(0.1)
                    
                    VStack(spacing: 20) {
                        Spacer(minLength: 30)

                        VStack(spacing: 0) {
                            Image("authc")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300)
                                .clipped()
                        }

                      

                        VStack(spacing: 16) {
                            // Register Button
                            NavigationLink(destination: RegisterView().environmentObject(authModel).navigationBarHidden(true)) {
                                Text("Create Account")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color("AppSecondary"))
                                .foregroundColor(Color("AppPrimary"))
                                .clipShape(Capsule())
                            }
                            
                            // Login Button
                            NavigationLink(destination: LoginView().environmentObject(authModel).navigationBarHidden(true)) {
                                Text("Sign In")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.clear)
                                .foregroundColor(Color("AppSecondary"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 50)
                                        .stroke(Color("AppSecondary").opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            // Or Divider
                            HStack {
                                Rectangle()
                                    .fill(Color("AppSecondary").opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.caption)
                                    .foregroundColor(Color("AppSecondary").opacity(0.6))
                                    .padding(.horizontal, 16)
                                
                                Rectangle()
                                    .fill(Color("AppSecondary").opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // Social Login Buttons
                            HStack(spacing: 12) {
                                // Apple button
                                SignInWithAppleButton(.signIn) { request in
                                    let nonce = randomNonceString()
                                    self.nonce = nonce
                                    request.requestedScopes = [.email, .fullName]
                                    request.nonce = sha256(nonce)
                                } onCompletion: { result in
                                    switch result {
                                    case .success(let authorization):
                                        loginWithApple(authorization)
                                    case .failure(let error):
                                        authModel.messageState = MessageState.error(error.localizedDescription)
                                    }
                                }
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .fill(Color.black)
                                        .allowsHitTesting(false)
                                )
                                .overlay(
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                        .allowsHitTesting(false)
                                )
                                .disabled(authModel.isLoading)
                                
                                Button {
                                    authModel.signInWithGoogle()
                                } label: {
                                    Image("google")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(Color("AppSecondary"))
                                        .frame(width: 55, height: 55)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(Circle())
                                }
                                .disabled(authModel.isLoading)
                            }
                        }
                        .padding(.horizontal, 32)

                        // Terms and Privacy
                        VStack(spacing: 6) {
                            Text("Signing up for Pistoni account means you")
                            HStack {
                                Text("agree to the")
                                NavigationLink("Privacy Policy", destination: LoginView().environmentObject(authModel)).underline()
                                Text("and")
                                NavigationLink("Terms of Service.", destination: LoginView().environmentObject(authModel)).underline()
                            }
                        }
                        .foregroundColor(Color("AppSecondary").opacity(0.8))
                        .padding(.horizontal, 20)
                        .font(.caption)

                        Spacer(minLength: 16)
                    }
                }
            }
            .ignoresSafeArea()
            .navigationBarHidden(true)
            .onChange(of: authModel.successMessage) { _, newValue in
                if newValue != nil {
                    showMessageSheet = true
                    logStatus = true
                }
            }
            .onChange(of: authModel.errorMessage) { _, newValue in
                showMessageSheet = newValue != nil
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
 
    
    private func loginWithApple(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authModel.messageState = MessageState.error("Apple Sign-In credential is not available.")
            return
        }
        
        guard self.nonce != nil else {
            authModel.messageState = MessageState.error("Nonce is missing.")
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            authModel.messageState = MessageState.error("Unable to get ID token from Apple credential.")
            return
        }
        
        guard let authorizationCode = appleIDCredential.authorizationCode,
              let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
            authModel.messageState = MessageState.error("Unable to get authorization code from Apple credential.")
            return
        }
        
        let userIdentifier = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
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
        
        authModel.signInWithApple(appleOAuthDto: appleOAuthDto) { result in
            switch result {
            case .success:
                authModel.setSuccessMessage("Welcome back!")
                logStatus = true
            case .failure(let error):
                authModel.messageState = MessageState.error(error.localizedDescription)
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    AuthChoiceView()
        .environmentObject(AuthModel())
}

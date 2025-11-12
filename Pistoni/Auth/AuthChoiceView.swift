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
    var onRegisterTapped: () -> Void = {}
    var onLoginTapped: () -> Void = {}

    
    @EnvironmentObject private var authModel: AuthModel
    @State private var nonce: String?
    
    var body: some View {
        NavigationStack {
            
                ZStack {
                    Image("bg")
                        .resizable()
                        .ignoresSafeArea()
                        .blur(radius: 20)
                        .opacity(0.1)
                    
                    VStack(spacing: 40) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                          
                            
                            VStack(spacing: 8) {
                                Text("Welcome")
                                    .font(.title)
                                    .fontWeight(.black)
                                    .foregroundColor(Color("Secondary").opacity(0.8))
                               
                            }
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 16) {
                            // Register Button
                            NavigationLink(destination: RegisterView().environmentObject(authModel).navigationBarHidden(true)) {
                                VStack(spacing: 8) {
                                    Text("Create Account")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color("Secondary"))
                                .foregroundColor(Color("Primary"))
                                .clipShape(Capsule())
                            }
                            
                            // Login Button
                            NavigationLink(destination: LoginView().environmentObject(authModel).navigationBarHidden(true)) {
                                VStack(spacing: 8) {
                                    Text("Sign In")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.clear)
                                .foregroundColor(Color("Secondary"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 50)
                                        .stroke(Color("Secondary").opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            // Or Divider
                            HStack {
                                Rectangle()
                                    .fill(Color("Secondary").opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.caption)
                                    .foregroundColor(Color("Secondary").opacity(0.6))
                                    .padding(.horizontal, 16)
                                
                                Rectangle()
                                    .fill(Color("Secondary").opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // Social Login Buttons
                            VStack(spacing: 12) {
                                
                                
                                // Replace the old Apple button
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
                                .frame(height: 55).clipShape(Capsule())
                                .disabled(authModel.isLoading)
                                
                                Button {
                                    authModel.signInWithGoogle()
                                } label: {
                                    HStack {
                                        Image("google")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 20)
                                            .foregroundColor(Color("Secondary"))
                                        Text("Continue with Google")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("Accent").opacity(0.2))
                                    .foregroundColor(Color("Secondary"))
                                    .clipShape(Capsule())
                                }
                                .disabled(authModel.isLoading)
                            }
                        }
                        .padding(.horizontal, 32)
                        .background(.white)
                        .clipShape(
                                     RoundedCorner(radius: 30, corners: [.topLeft, .topRight])
                                 )
                        
                       
                        
                        // Error and Success Messages
                        VStack(spacing: 8) {
                            if let errorMessage = authModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                            
                            if let successMessage = authModel.successMessage {
                                Text(successMessage)
                                    .foregroundColor(.green)
                                    .font(.footnote)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Terms and Privacy
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
                        
                        Spacer()
                    }
                }
            }
            .ignoresSafeArea()
            .navigationBarHidden(true)
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


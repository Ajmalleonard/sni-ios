//
//  AuthChoiceView.swift
//  SNI Rentals
//
//  Created by Jesus on 1/22/25.
//

import SwiftUI

struct AuthChoiceView: View {
    var onRegisterTapped: () -> Void = {}
    var onLoginTapped: () -> Void = {}
    
    @EnvironmentObject private var authModel: AuthModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    Image("bg")
                        .resizable()
                        .ignoresSafeArea()
                        .blur(radius: 20)
                        .opacity(0.1)
                    
                    VStack(spacing: 40) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image("sni_white")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .foregroundColor(Color("Secondary"))
                            
                            VStack(spacing: 8) {
                                Text("Welcome to")
                                    .font(.title2)
                                    .foregroundColor(Color("Secondary").opacity(0.8))
                                
                                Text("Your journey starts here")
                                    .font(.subheadline)
                                    .foregroundColor(Color("Secondary").opacity(0.7))
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
                                Button {
                                    authModel.signInWithApple()
                                } label: {
                                    HStack {
                                        Image(systemName: "apple.logo")
                                            .font(.title3)
                                        Text("Continue with Apple")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("Accent").opacity(0.2))
                                    .foregroundColor(Color("Secondary"))
                                    .clipShape(Capsule())
                                }
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
                        
                        Spacer()
                        
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
                        VStack(spacing: 4) {
                            Text("By continuing, you agree to our")
                                .font(.caption)
                                .foregroundColor(Color("Secondary").opacity(0.6))
                            
                            HStack(spacing: 8) {
                                Button("Terms of Service") {
                                    // TODO: Show Terms
                                }
                                .font(.caption)
                                .foregroundColor(Color("Accent"))
                                
                                Text("and")
                                    .font(.caption)
                                    .foregroundColor(Color("Secondary").opacity(0.6))
                                
                                Button("Privacy Policy") {
                                    // TODO: Show Privacy Policy
                                }
                                .font(.caption)
                                .foregroundColor(Color("Accent"))
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .ignoresSafeArea()
            .navigationBarHidden(true)
        }
    }
    

}

#Preview {
    AuthChoiceView()
        .environmentObject(AuthModel())
}

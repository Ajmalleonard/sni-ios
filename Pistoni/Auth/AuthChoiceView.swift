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
    }
    



#Preview {
    AuthChoiceView()
        .environmentObject(AuthModel())
}

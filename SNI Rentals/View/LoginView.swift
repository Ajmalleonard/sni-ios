//
//  LoginView.swift
//  SNI Rentals
//
//  Created by Jesus on 7/5/25.
//

import SwiftUI

struct LoginView: View {
    @State var email : String = ""
    @State var password : String = ""
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            ZStack {
                Color("Primary").ignoresSafeArea()
                VStack(spacing: 32) {
                    // Back Button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(Color("Secondary"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 10)
                    VStack(spacing: 2) {
                        Image("sni_white")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .padding(.bottom,30)
                            .foregroundColor(Color("Secondary"))
                        
                        Text("Welcome back")
                            .font(.largeTitle).fontWeight(.semibold)
                            .foregroundColor(Color("Secondary"))
                        
                        Text("Let's get you back into SNI")
                            .font(.callout)
                            .foregroundColor(Color("Secondary"))
                    }
                    .padding()
                    
                    VStack(spacing: 16) {
                        // Optimized TextField
                        TextField("Your Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                            .foregroundColor(Color("Secondary"))
                        
                        SecureField("Your Password", text: $password)
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                            .foregroundColor(Color("Secondary"))
                    }
                    .padding(.horizontal, 32)
                    
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
                    
                    Button("Forgot Password?") {
                        // TODO: Handle forgot password
                    }
                    .foregroundColor(Color("Accent"))
                    .padding(.horizontal, 32)
                    
                    Button(action: login) {
                        if authModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Sign in")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Secondary"))
                                .foregroundColor(Color("Primary"))
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(authModel.isLoading)
                    .padding(.horizontal, 32)
                    
                    // Or Divider
                    HStack {
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(height: 1)
                        Text("or")
                            .padding(.horizontal, 16)
                            .foregroundColor(Color("Secondary"))
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    
                    VStack(spacing: 12) {
                        Button {
                            // TODO: Apple Sign In
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("Continue With Apple")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Accent").opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundColor(Color("Secondary"))
                        }
                        .disabled(authModel.isLoading)
                        
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack {
                                Image("google")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width:25, height: 25)
                                    .foregroundColor(Color("Secondary"))
                                Text("Continue With Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Accent").opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundColor(Color("Secondary"))
                        }
                        .disabled(authModel.isLoading)
                    }
                    .padding(.horizontal, 32)
                    
                    // Registration prompt
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(Color("Secondary").opacity(0.7))
                        NavigationLink("Sign Up", destination: RegisterView().environmentObject(authModel).navigationBarHidden(true))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("Accent"))
                    }
                    .font(.footnote)
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func login() {
        authModel.login(email: email, password: password)
    }
    
    private func signInWithGoogle() {
        authModel.signInWithGoogle()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthModel())
}

//
//  RegisterView.swift
//  SNI Rentals
//
//  Created by Jesus on 7/5/25.
//

import SwiftUI

struct RegisterView: View {
    @State var name : String = ""
    @State var isVerified : Bool =  false
    @State var email : String = ""
    @State var password : String = ""
    @State private var showEmailVerification: Bool = false
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
                    
                    VStack(alignment:.leading ,spacing: 2) {
                        
                        Text("Create an account")
                            .font(.title2)
                            .foregroundColor(Color("Secondary"))
                    }
                    .padding()
                 
                    
                    VStack(spacing: 12) {
//                        Button {
//                            signInWithApple()
//                        } label: {
//                            HStack {
//                                Image(systemName: "apple.logo")
//                                Text("Continue With Apple")
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color("Accent").opacity(0.2))
//                            .clipShape(Capsule())
//                            .foregroundColor(Color("Secondary"))
//                        }
//                        .disabled(authModel.isLoading)
                        
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack {
                                Image("google")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width:30, height: 30)
                                    .foregroundColor(Color("Secondary"))
                                Text("Continue With Google").padding(.horizontal,10)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .clipShape(Capsule())
                            .foregroundColor(Color("Secondary"))
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
                            .foregroundColor(Color("Secondary"))
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
                                .foregroundColor(Color("Secondary"))
                        }.frame(maxWidth: .infinity)
                        
                        // Show verify button if in email step
                        if authModel.registrationStep == .enterEmail {
                            Button(action: verifyEmail) {
                                Text("Create account")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(20)
                                    .background(Color("Secondary"))
                                    .foregroundColor(Color("Primary"))
                                    .clipShape(Capsule())
                            }
                            .disabled(!isValidEmail(email))
                        }
                        
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
                                    .foregroundColor(Color("Secondary"))
                                
                                SecureField("Your Password", text: $password)
                                    .padding()
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color("Accent"), lineWidth: 1)
                                    )
                                    .foregroundColor(Color("Secondary"))
                                
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
                                            .background(Color("Secondary"))
                                            .foregroundColor(Color("Primary"))
                                            .clipShape(Capsule())
                                    }
                                }
                                .disabled(authModel.isLoading || name.isEmpty || password.isEmpty)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
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
                            .foregroundColor(Color("Secondary").opacity(0.7))
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
        .sheet(isPresented: $showEmailVerification) {
            EmailVerificationView(email: email)
                .environmentObject(authModel)
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
    
    private func signInWithApple() {
        authModel.signInWithApple()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
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

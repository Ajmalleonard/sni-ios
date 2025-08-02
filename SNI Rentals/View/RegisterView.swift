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
    @State var code: String = ""
    @State private var codeFieldShake = false
    @State private var codeFieldBlinkGreen = false
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
                        
                        Text("Create Account")
                            .font(.largeTitle).fontWeight(.semibold)
                            .foregroundColor(Color("Secondary"))
                        Text("Join the SNI community")
                            .font(.callout)
                            .foregroundColor(Color("Secondary"))
                    }
                    .padding()
                    
                    VStack(spacing: 16) {
                        // Email field (always visible)
                        TextField("Your Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(authModel.registrationStep == .enterDetails ? Color.gray.opacity(0.1) : Color.clear)
                            .disabled(authModel.registrationStep == .enterDetails)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("Accent"), lineWidth: 1)
                            )
                            .foregroundColor(Color("Secondary"))
                        
                        // Show verify button if in email step
                        if authModel.registrationStep == .enterEmail {
                            Button(action: verifyEmail) {
                                if authModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Verify Email")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color("Secondary"))
                                        .foregroundColor(Color("Primary"))
                                        .clipShape(Capsule())
                                }
                            }
                            .disabled(authModel.isLoading || !isValidEmail(email))
                        }
                        
                        // Code field (animated in)
                        if authModel.registrationStep == .enterCode {
                            codeField
                                .transition(.move(edge: .top).combined(with: .opacity))
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
                    
                    // Login prompt
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(Color("Secondary").opacity(0.7))
                        NavigationLink("Sign In", destination: LoginView().environmentObject(authModel).navigationBarHidden(true))
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
        .loadingOverlay(isLoading: authModel.isLoading)
    }
    
    var codeField: some View {
        TextField("6-digit code", text: $code)
            .keyboardType(.numberPad)
            .padding()
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(codeFieldBlinkGreen ? Color.green : Color("Accent"), lineWidth: 1)
            )
            .foregroundColor(Color("Secondary"))
            .modifier(Shake(animatableData: CGFloat(codeFieldShake ? 1 : 0)))
            .onChange(of: code) { _, newValue in
                if newValue.count == 6 {
                    verifyCode()
                }
            }
            .onChange(of: authModel.codeVerified) { _, newValue in
                if newValue {
                    codeFieldBlinkGreen = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        codeFieldBlinkGreen = false
                    }
                }
            }
            .onChange(of: authModel.errorMessage) { _, newValue in
                if newValue != nil && code.count == 6 {
                    codeFieldShake = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        codeFieldShake = false
                        code = ""
                    }
                }
            }
    }
    
    private func verifyEmail() {
        authModel.requestEmailVerification(email: email)
    }
    
    private func verifyCode() {
        authModel.verifyEmailCode(email: email, code: code)
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

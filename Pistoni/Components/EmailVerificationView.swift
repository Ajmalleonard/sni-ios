//
//  EmailVerificationView.swift
//  SNI Rentals
//
//  Created by Assistant on 1/27/25.
//

import SwiftUI

struct EmailVerificationView: View {
    var email: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authModel: AuthModel
    @State private var isCodeSent: Bool = false
    @State private var verificationCode: String = ""
    @FocusState private var isFocused: Bool
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isRequestingCode: Bool = true
    @State private var invalidCodeTrigger = false
    
    var isIOS26: Bool {
        if #available(iOS 26, *) {
            return true
        }
        return false
    }
    
    var body: some View {
        ZStack {
            if isCodeSent {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Verification")
                            .font(.title3)
                            .foregroundColor(Color("Secondary"))
                        
                        HStack(spacing: 4) {
                           Text("Enter the 6-digit code sent to \(email)")
                                .font(.caption)
                                .foregroundColor(Color("Secondary"))
                            
                        }
                    }
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .trailing) {
                        // Close Button
                        Button("", systemImage: "xmark.circle.fill") {
                            dismiss()
                        }
                        .font(.title)
                        .tint(Color("Secondary").opacity(0.7))
                        .offset(x: 10, y: -15)
                    }
                    .padding(.top, 10)
                    
                    // Verification Field
                    VerificationField(
                        type: .six,
                        value: $verificationCode,
                        invalidTrigger: $invalidCodeTrigger
                    ) { code in
                        if code.count == 6 {
                            authModel.verifyEmailCode(email: email, code: code)
                            return .typing
                        }
                        return .typing
                    }
                    .modifier(Shake(animatableData: invalidCodeTrigger ? 1 : 0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(invalidCodeTrigger ? Color.red : Color.clear, lineWidth: 2)
                    )
                    .padding(.top, 12)
                    
                    // Resend button
                    HStack {
                        Spacer()
                        Button("Resend Code") {
                            requestVerificationCode()
                        }
                        .font(.callout)
                        .foregroundColor(Color("Accent"))
                        .disabled(authModel.isLoading || isRequestingCode)
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .geometryGroup()
                .transition(.blurReplace)
                
            } else if authModel.messageState.isError && authModel.messageState.message != nil {
                // Error state - show error message instead of infinite animation
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.red)
                        .frame(width: 150, height: 150)
                    
                    Text("Failed to Send Code")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("Secondary"))
                    
                    Text(authModel.messageState.message ?? "Unknown error")
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Try Again") {
                        requestVerificationCode()
                    }
                    .font(.callout)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color("Accent"))
                    .cornerRadius(8)
                    .disabled(authModel.isLoading || isRequestingCode)
                }
                .geometryGroup()
                .transition(.blurReplace)
                
            } else {
                VStack(spacing: 12) {
                    let symbols = ["envelope", "ellipsis.message.fill", "checkmark.circle.fill"]
                    PhaseAnimator(symbols) { symbol in
                        Image(systemName: symbol)
                            .font(.system(size: 100))
                            .contentTransition(.symbolEffect)
                            .frame(width: 150, height: 150)
                            .foregroundColor(Color("Secondary"))
                    } animation: { _ in
                        .linear(duration: 1.2)
                    }
                    .frame(height: 150)
                    
                    Text("Sending Verification Code...")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("Secondary"))
                }
                .geometryGroup()
                .transition(.blurReplace)
            }
        }
        .background(Color("Primary"))
        .presentationDetents([.height(280)])
        .presentationBackground(Color("Primary"))
        .presentationCornerRadius(isIOS26 ? nil : 25)
        .interactiveDismissDisabled()
        .alert(alertMessage, isPresented: $showAlert) {
            Button("Dismiss", role: .cancel) {
                dismiss()
            }
        }
        .onAppear {
            requestVerificationCode()
        }
        .animation(.snappy(duration: 0.3, extraBounce: 0), value: isCodeSent)
        .focused($isFocused)
        .onChange(of: authModel.messageState) { _, newValue in
            if newValue.isError && newValue.message != nil {
                // 🔴 Wrong code
                invalidCodeTrigger.toggle()
            } else if !newValue.isError && authModel.codeVerified {
                // ✅ Correct code → dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }

    }
    
    private func requestVerificationCode() {
        isRequestingCode = true
        authModel.requestEmailVerification(email: email)
    }
    
    private func handleServerResponse(_ messageState: MessageState?) {
        guard let messageState = messageState else { return }
        
        if let message = messageState.message {
            if messageState.isError {
                // Server responded with error - show exact error message
                alertMessage = message
                showAlert = true
                isRequestingCode = false
            } else {
                // Server responded successfully - show the input field
                isCodeSent = true
                isFocused = true
                isRequestingCode = false
            }
        }
    }
}



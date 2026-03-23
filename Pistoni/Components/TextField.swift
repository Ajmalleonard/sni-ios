//
//  TextField.swift
//  SNI Rentals
//
//  Created by Jesus on 7/10/25.
//

import SwiftUI

struct FastTextField: View {
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool = false
    var isBordered: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }
        }
        .padding()
        .background(Color.clear)
        .foregroundColor(Color("AppSecondary"))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color("Accent"), lineWidth: 1)
        )
    }
}

struct FastTextFieldWithIcon: View {
    @Binding var text: String
    var placeholder: String
    var systemImageName: String?
    var isSecure: Bool = false
    var isBordered: Bool = false
    var bgColor: Color?
    
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            if let systemImageName = systemImageName {
                Image(systemName: systemImageName)
                    .foregroundColor(Color("Accent"))
                    .frame(width: 20)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(Group {
            if let bgColor = bgColor {
                bgColor
            } else {
                Color.clear
            }
        })
        .foregroundColor(Color("AppSecondary"))
        .clipShape(Capsule())
        .overlay(
            Group {
                if isBordered {
                    RoundedRectangle(cornerRadius: 15)
                .stroke(Color("Accent"), lineWidth: 1)
                }
            }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        FastTextField(text: .constant(""), placeholder: "Email Address", keyboardType: .emailAddress)
        FastTextField(text: .constant(""), placeholder: "Password", isSecure: true)
        FastTextFieldWithIcon(text: .constant(""), placeholder: "Email", systemImageName: "envelope")
    }
    .padding()
    .background(Color("AppPrimary"))
}

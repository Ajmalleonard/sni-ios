//
//  File.swift
//  SNI Rentals
//
//  Created by Ajmal Leonard on 19/09/2025.
//
import SwiftUI

struct GoogleButtonContent: View { // Computed property to break down complex button expression
    var body: some View {
        HStack {
            Image("google")
                .renderingMode(.template)
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(Color("Secondary"))
            Text("Continue With Google")
                .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .clipShape(Capsule())
        .foregroundColor(Color("Secondary"))
        .overlay(
            RoundedRectangle(cornerRadius: .infinity)
                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
        )
    }}
    

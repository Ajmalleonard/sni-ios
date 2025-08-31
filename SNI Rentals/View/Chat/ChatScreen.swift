//
//  ChatScreen.swift
//  SNI Rentals
//
//  Created by Assistant on 25/01/25.
//

import SwiftUI

struct ChatScreen: View {
    @EnvironmentObject var authModel: AuthModel
    
    var body: some View {
        EnhancedChatView()
            .environmentObject(authModel)
    }
}

#Preview {
    let mockAuthModel = AuthModel()
    mockAuthModel.isPreview = true
    return ChatScreen()
        .environmentObject(mockAuthModel)
}

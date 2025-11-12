//
//  ProgressButton.swift
//  Pistoni
//
//  Created by Love on 06/11/2025.
//

import SwiftUI

struct AnimatedProgressCornerRadius {
    var source: CGFloat = 30
    var destination: CGFloat = 45
    
}

fileprivate struct ProgressButtonProperties{
    var sourceLocation: CGRect = .zero
    var hideSource : Bool = false
    
    var animate: Bool = false
    var showView: Bool = false
    
    
}

struct ProgressiveButton<Content: View, Label: View >: View {
    var cornerRadius: AnimatedProgressCornerRadius = .init()
    @ViewBuilder var  content: Content
    @ViewBuilder var label: Label
    var action: (_ isCancelled: Bool) -> ()
    @State fileprivate var properties: ProgressButtonProperties = .init()
    
    
    
    var body: some View {
        Button{
            noAnimation{
                properties.showView = true
            }
        } label: {
            label
                .clipShape(.rect(cornerRadius:cornerRadius.source))
                .contentShape(.rect(cornerRadius:cornerRadius.source))
        }.buttonStyle(.plain)
        
       ///  Going to use fullscreen for the animattion so that the source view can be added anywhere deep inside and still animation will work!
            .fullScreenCover(isPresented: $properties.showView){
                
            }
    }
}
#Preview {
   RegisterView()
}


extension View {
    func noAnimation(_ content: @escaping()-> ()){
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction){
            content()
        }
    }
}

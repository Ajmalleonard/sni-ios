//
//  ContentView.swift
//  DeleteButton
//
//  Created by Balaji Venkatesh on 31/10/25.
//

import SwiftUI

struct MainView: View {
    @State private var showSheet: Bool = false
    @State private var isImage: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Section("Demo") {
                    Toggle("Smaller Button", isOn: $isImage)
                    
                    Button("Show Sheet") {
                        showSheet.toggle()
                    }
                    
                    ButtonView()
                }
                
                Section("Usage") {
                    Text(
                    """
                    AnimatedDeleteButton {
                        
                    } label: {
                        
                    } action: { isCancelled in
                        
                    }
                    """
                    )
                    .monospaced()
                }
            }
            .navigationTitle("Animated Delete Button")
            .sheet(isPresented: $showSheet) {
                NavigationStack {
                    List {
                        Section("Demo") {
                            ButtonView()
                        }
                        Section("Progressive Button Demo") {
                            ProgressiveButtonDemo()
                        }
                    }
                    .navigationTitle("Sheet Example")
                }
            }
        }
    }
    
    @ViewBuilder
    func ButtonView() -> some View {
        AnimatedButton(cornerRadius: .init(source: 30, destination: 45)) {
            /// Dummy Content
            VStack(alignment: .leading, spacing: 15) {
                Image(systemName: "exclamationmark.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Are you sure?")
                    .font(.title2.bold())
                
                Text("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s.")
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 10)
        } label: {
            if isImage {
                Image(systemName: "trash.fill")
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(.red.gradient)
            } else {
                Text("Delete Account?")
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(.red.gradient)
            }
        } action: { isCancelled in
            print(isCancelled)
        }
        .frame(maxWidth: .infinity, alignment: isImage ? .trailing : .center)
    }
}

struct ProgressiveButtonDemo: View {
    @State private var state: ProgressiveState = .idle
    var body: some View {
        VStack(spacing: 12) {
            ProgressiveButton(state: $state, confirmTitle: "Proceed") {
                // onConfirm: simulate async work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Randomize success/error for demo
                    if Bool.random() {
                        state = .success("Completed successfully")
                    } else {
                        state = .error("Something went wrong")
                    }
                }
            } onCancel: {
                // onCancel
            } onTap: {
                // onTap
            } label: {
                Text("Start Action")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color("Secondary"))
                    .foregroundColor(Color("Primary"))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainView()
}

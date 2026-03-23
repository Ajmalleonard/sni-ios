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
    @State private var processState: ProcessState = .confirm
    var body: some View {
        NavigationStack {
            List {
                Section("Demo") {
                    Toggle("Smaller Buttons", isOn: $isImage)
                    
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
                        Section("Main") {
                            ButtonView()
                        }
                        
                    }
                    .navigationTitle("Sheet Example")
                }
            }
        }
    }
    
    @ViewBuilder
    func ButtonView() -> some View {
        AnimatedButton(cornerRadius: .init(source: 30, destination: 45), state: $processState) {
       
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
        }// In your action:
        action: { isCancelled in
            if isCancelled {
                // User cancelled; reset if you want
                processState = .confirm
                return
            }

            // Start loading
            processState = .loading(message: "Working…")

            // Configure a timeout (e.g., 3 seconds)
            let timeoutNanos: UInt64 = 3_000_000_000

            Task {
                // Simulate your async work here.
                // For example, you could await a network call and return early on success.
                // If your real task completes first, set success and return before timeout triggers.

                // Simulate work taking 1.5 seconds
                try? await Task.sleep(nanoseconds: 1_500_000_000)

                let succeeded = Bool.random() // Replace with your real result
                if succeeded {
                    // If you succeed before timeout, set success and return
                    processState = .success(title: "Done", message: "Operation completed.")
                    return
                }

                // If not succeeded yet, wait until timeout for a last chance
                try? await Task.sleep(nanoseconds: timeoutNanos - 1_500_000_000)

                // If you're still here, consider it a failure
                processState = .error(title: "Timeout", message: "Please try again.")
            }
        }
        .frame(maxWidth: .infinity, alignment: isImage ? .center : .center)
    }
}



#Preview {
    MainView()
}


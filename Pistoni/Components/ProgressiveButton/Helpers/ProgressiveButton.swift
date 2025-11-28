import SwiftUI

enum ProgressiveState: Equatable {
    case idle
    case confirming
    case loading
    case success(String?)
    case error(String?)
}

struct ProgressiveButton<Label: View>: View {
    @Binding var state: ProgressiveState
    
    var confirmTitle: String = "Confirm"
    var onConfirm: () -> Void
    var onCancel: () -> Void = {}
    var onTap: () -> Void = {}
    
    @ViewBuilder var label: () -> Label
    
    @State private var successTask: DispatchWorkItem?
    
    var body: some View {
        switch state {
        case .idle:
            Button(action: {
                onTap()
                withAnimation {
                    state = .confirming
                }
            }) {
                label()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("Secondary"))
                    .foregroundColor(Color("Primary"))
                    .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            
        case .confirming:
            HStack(spacing: 8) {
                Button(action: {
                    onCancel()
                    withAnimation {
                        state = .idle
                    }
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("Secondary"))
                        .foregroundColor(Color("Primary"))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    onConfirm()
                    withAnimation {
                        state = .loading
                    }
                }) {
                    Text(confirmTitle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("Secondary"))
                        .foregroundColor(Color("Primary"))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color("Secondary"))
                .foregroundColor(Color("Primary"))
                .clipShape(Capsule())
                .disabled(true)
            
        case .success(let message):
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
                if let msg = message {
                    Text(msg)
                        .foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color("Secondary"))
            .clipShape(Capsule())
            .onAppear {
                successTask?.cancel()
                let task = DispatchWorkItem {
                    withAnimation {
                        state = .idle
                    }
                }
                successTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: task)
            }
            .onDisappear {
                successTask?.cancel()
            }
            
        case .error(let message):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                if let msg = message {
                    Text(msg)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color("Secondary"))
            .clipShape(Capsule())
            .onTapGesture {
                withAnimation {
                    state = .confirming
                }
            }
        }
    }
}

#Preview("Interactive") {
    @Previewable @State var state: ProgressiveState = .idle
    return VStack(spacing: 20) {
        ProgressiveButton(state: $state, onConfirm: {
            // Simulate loading then success or error after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    let success = Bool.random()
                    if success {
                        state = .success("Done")
                    } else {
                        state = .error("Failed")
                    }
                }
            }
        }, onCancel: {
            state = .idle
        }, onTap: {
            // tapped idle button
        }) {
            Text("Start Action")
                .fontWeight(.semibold)
        }

        Divider()

        VStack(alignment: .leading, spacing: 8) {
            Text("All States Preview").font(.headline)
            Group {
                Text("Idle State")
                ProgressiveButton(state: .constant(.idle), onConfirm: {}, onTap: {}) {
                    Text("Idle Button")
                        .fontWeight(.semibold)
                }
            }
            Group {
                Text("Confirming State")
                ProgressiveButton(state: .constant(.confirming), onConfirm: {}, onCancel: {}, onTap: {}) {
                    Text("Confirming Button")
                        .fontWeight(.semibold)
                }
            }
            Group {
                Text("Loading State")
                ProgressiveButton(state: .constant(.loading), onConfirm: {}, onTap: {}) {
                    Text("Loading Button")
                        .fontWeight(.semibold)
                }
            }
            Group {
                Text("Success State (with message)")
                ProgressiveButton(state: .constant(.success("Success!")), onConfirm: {}, onTap: {}) {
                    Text("Success Button")
                        .fontWeight(.semibold)
                }
            }
            Group {
                Text("Error State (with message)")
                ProgressiveButton(state: .constant(.error("Error occurred")), onConfirm: {}, onTap: {}) {
                    Text("Error Button")
                        .fontWeight(.semibold)
                }
            }
        }
    }
    .padding()
    .preferredColorScheme(.light)
    .frame(maxWidth: 400)
}

#Preview("Dark Mode") {
    @Previewable @State var state: ProgressiveState = .idle
    return ProgressiveButton(state: .constant(.idle), onConfirm: {}, onTap: {}) {
        Text("Start Action")
            .fontWeight(.semibold)
    }
    .padding()
    .preferredColorScheme(.dark)
}

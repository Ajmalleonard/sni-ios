//
//  AnimatedDeleteButton.swift
//  DeleteButton
//
//  Created by Balaji Venkatesh on 31/10/25.
//

import SwiftUI

struct AnimatedButtonCornerRadius {
    var source: CGFloat = 30
    var destination: CGFloat = 45
}

enum ProcessState: Equatable {
    case confirm
    case loading(message: String? = nil)
    case success(title: String? = nil, message: String? = nil)
    case error(title: String? = nil, message: String? = nil)
}

struct CustomAction {
    var title: String
    var background: Color
    var foreground: Color
}

fileprivate struct AnimatedButtonProperties {
    var sourceLocation: CGRect = .zero
    var sourceView: UIImage?
    var hideSource: Bool = false
    var animate: Bool = false
    var showDeleteView: Bool = false
    
}

struct AnimatedButton<Content: View, Label: View>: View {
    var cornerRadius: AnimatedButtonCornerRadius = .init()
    var customAction: CustomAction?
    @Binding var state: ProcessState
    @ViewBuilder var content: Content
    @ViewBuilder var label: Label
    var action: (_ isCancelled: Bool) -> ()
    @State fileprivate var properties: AnimatedButtonProperties = .init()
    @Environment(\.displayScale) private var displayScale: CGFloat

    private var _stateFallback: State<ProcessState> = .init(initialValue: .confirm)

    init(cornerRadius: AnimatedButtonCornerRadius = .init(), customAction: CustomAction? = nil, state: Binding<ProcessState>? = nil, @ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label, action: @escaping (_ isCancelled: Bool) -> ()) {
        self.cornerRadius = cornerRadius
        self.customAction = customAction
        if let state {
            self._state = state
        } else {
            self._state = _stateFallback.projectedValue
        }
        self.content = content()
        self.label = label()
        self.action = action
    }

    var body: some View {
        Button {
            let renderer = ImageRenderer(content:
                label
                    .frame(
                        width: properties.sourceLocation.width,
                        height: properties.sourceLocation.height
                    )
                    .clipShape(.rect(cornerRadius: cornerRadius.source))
            )
            renderer.scale = displayScale
            properties.sourceView = renderer.uiImage
            
            /// Going to show full-scree-cover without animation!
            noAnimation {
                properties.showDeleteView = true
            }
        } label: {
            label
                .clipShape(.rect(cornerRadius: cornerRadius.source))
                .contentShape(.rect(cornerRadius: cornerRadius.source))
                /// Hiding Source View
                .opacity(properties.showDeleteView ? 0 : 1)
        }
        .onGeometryChange(for: CGRect.self, of: {
            $0.frame(in: .global)
        }, action: { newValue in
            properties.sourceLocation = newValue
        })
        .buttonStyle(.plain)
        /// Going to use Full-screen-cover for the animation so that the source view can be added anywhere deep inside and still the animation will work!
        .fullScreenCover(isPresented: $properties.showDeleteView) {
            ButtonView(state: $state, customAction: customAction, cornerRadius: cornerRadius, properties: $properties) {
                content
            } action: { isUserCancelled in
                action(isUserCancelled)
            }
            .ignoresSafeArea()
            .presentationBackground(.clear)
            .persistentSystemOverlays(.hidden)
        }
    }
}

fileprivate struct ButtonView<Content: View>: View {
    @Binding var state: ProcessState
    var customAction: CustomAction?
    var cornerRadius: AnimatedButtonCornerRadius
    @Binding fileprivate var properties: AnimatedButtonProperties
    @ViewBuilder var content: Content
    var action: (_ isUserCancelled: Bool) -> ()

    var body: some View {
        let animate = properties.animate
        let hideSource = properties.hideSource
        let sourceLocation = properties.sourceLocation
        
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.black.opacity(animate ? 0.4 : 0))
            
            /// Content View
            VStack(spacing: 10) {
                switch state {
                case .confirm:
                    content
                case .loading(let message):
                    LoadingView(message: message)
                case .success(let title, let message):
                    SuccessView(title: title, message: message)
                case .error(let title, let message):
                    ErrorView(title: title, message: message)
                }
                ActionButtons()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .allowsHitTesting(animate)
            .padding(20)
            .compositingGroup()
            .geometryGroup()
            .background(.background, in: clipShape)
            .blur(radius: animate ? 0 : 10)
            /// If you dont want the fade in/fade out effect (Use this method!)
            .opacity(animate ? 1 : 0)
            /// Replace Opacity with this
            //.opacity(properties.showDeleteView ? 1 : 0)
            // Replace .background with .overlay
            .background {
                GeometryReader {
                    let size = $0.size
                    
                    if let sourceView = properties.sourceView {
                        Image(uiImage: sourceView)
                            .resizable()
                            .frame(
                                width: animate ? size.width : sourceLocation.width,
                                height: animate ? size.height : sourceLocation.height,
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .blur(radius: hideSource ? 10 : 0)
                            .opacity(hideSource ? 0 : 1)
                    }
                }
            }
            /// Using mask to change view size, instead of using frame, so that the content won't have any text clipping or wrapping and will look more clean!
            .mask {
                clipShape
                    .frame(
                        width: animate ? nil : sourceLocation.width,
                        height: animate ? nil : sourceLocation.height
                    )
            }
            .padding(.horizontal, 10)
            /// Using Visual Effect to animate from source to destination
            .visualEffect { content, proxy in
                content
                    .offset(
                        x: animate ? 0 : sourceLocation.midX - (proxy.size.width / 2),
                        y: animate ? -10 : sourceLocation.midY - (proxy.size.height / 2)
                    )
            }
            /// Since coordination system starts from top-left!
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: animate ? .bottom : .topLeading
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(animation) {
                properties.animate = true
            }
            
            /// Some times calling two withAnimations leading to animate only one, thus let's solve this by putting another one inside the Task!
            Task {
                withAnimation(sourceAnimation) {
                    properties.hideSource = true
                }
            }
        }
    }
    
    /// Action Buttons
    @ViewBuilder
    private func ActionButtons() -> some View {
        switch state {
        case .loading:
            EmptyView()
        case .success:
            HStack(spacing: 6) {
                Button { dismiss(true) } label: {
                    Text("Done")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Rectangle().fill(Color.green.gradient))
                        .clipShape(.capsule)
                }
                .disabled(isLoadingState)
            }
            .fontWeight(.medium)
        case .error:
            HStack(spacing: 6) {
                Button { dismiss(false) } label: {
                    Text("Cancel")
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(.gray.opacity(0.3))
                        .clipShape(.capsule)
                }
                .disabled(isLoadingState)

                Button { dismiss(true) } label: {
                    Text("Retry")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Rectangle().fill(Color.orange.gradient))
                        .clipShape(.capsule)
                }
                .disabled(isLoadingState)
            }
            .fontWeight(.medium)
        case .confirm:
            VStack {
                /// Dummy Content
                VStack(alignment: .leading, spacing: 15) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Are you sure?")
                        .font(.title2.bold())
                    
                    Text("We creating best stuff our of this powerfully language")
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 10)
                HStack(spacing: 6) {
                    
                    
                    Button { dismiss(false) } label: {
                        Text("Cancel")
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(.gray.opacity(0.3))
                            .clipShape(.capsule)
                    }
                    .disabled(isLoadingState)
                    
                    Button { dismiss(true) } label: {
                        if let customAction {
                            Text(customAction.title)
                                .foregroundStyle(customAction.foreground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(customAction.background.gradient)
                                .clipShape(.capsule)
                        } else {
                            Text("Delete")
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Rectangle().fill(Color.red.gradient))
                                .clipShape(.capsule)
                        }
                    }
                    .disabled(isLoadingState)
                }
                .fontWeight(.medium)
            }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    func dismiss(_ status: Bool) {
        withAnimation(animation, completionCriteria: .removed) {
            properties.animate = false
        } completion: {
            noAnimation {
                properties.sourceView = nil
                properties.showDeleteView = false
            }
            
            /// You can place this before the animation completion, but I'm placing it after, so it's your wish!
            action(status)
        }
        
        Task {
            withAnimation(sourceAnimation.delay(0.08)) {
                properties.hideSource = false
            }
        }
    }
    
    var clipShape: AnyShape {
        let radius = properties.animate ? cornerRadius.destination : cornerRadius.source
        
        return .init(.rect(cornerRadius: radius))
    }
    
    /// Change animations according to your own needs!
    var animation: Animation {
        .interpolatingSpring(duration: 0.3)
    }
    
    var sourceAnimation: Animation {
        .smooth(duration: 0.15, extraBounce: 0)
    }
    
    var isLoadingState: Bool { if case .loading = state { return true } else { return false } }
    
    @ViewBuilder
    private func LoadingView(message: String?) -> some View {
        VStack(alignment: .center, spacing: 12) {
            VStack(spacing: 10) {
                CustomLoadingView()
                if let message, !message.isEmpty { Text(message) }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ViewBuilder
    private func SuccessView(title: String?, message: String?) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            if let title, !title.isEmpty { Text(title).font(.title3.bold()) }
            if let message, !message.isEmpty { Text(message).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    private func ErrorView(title: String?, message: String?) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "xmark.octagon.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
            if let title, !title.isEmpty { Text(title).font(.title3.bold()) }
            if let message, !message.isEmpty { Text(message).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .fixedSize(horizontal: false, vertical: true)
    }
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


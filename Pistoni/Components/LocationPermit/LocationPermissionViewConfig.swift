//
//  LocationPermissionViewConfig.swift
//  Pistoni
//
//  Created by Love on 06/12/2025.
//




import SwiftUI
import CoreLocation

/// View Config's
struct LocationPermissionViewConfig {
    var appName: String
    var tint: Color = .blue
    var mapPinTint: Color = .white
    var mapPulseTint: Color = .white
    var showsMapPinAndPluse: Bool = true
    var dimsScreenContent: Bool = true
    var showsDynamicIsland: Bool = false
    var initialDelay: Double = 0.35
    var pinAndPulseOffset: CGSize = .zero
}

extension View {
    @ViewBuilder
    func locationPermissionFullScreenCover<ScreenContent: View>(
        isPresented: Binding<Bool>,
        config: LocationPermissionViewConfig,
        @ViewBuilder screenContent: @escaping () -> ScreenContent,
        authorizationDidChange: @escaping (CLAuthorizationStatus) -> (),
        askLater: @escaping () -> ()
    ) -> some View {
        self
            .fullScreenCover(isPresented: isPresented) {
                LocationPermissionView(
                    isPresented: isPresented,
                    config: config,
                    screenContent: screenContent,
                    authorizationDidChange: authorizationDidChange,
                    askLater: askLater
                )
                .presentationBackground(.background)
            }
    }
}

fileprivate struct LocationPermissionView<ScreenContent: View>: View {
    @Binding var isPresented: Bool
    var config: LocationPermissionViewConfig
    @ViewBuilder var screenContent: ScreenContent
    var authorizationDidChange: (CLAuthorizationStatus) -> ()
    var askLater: () -> ()
    /// View Properties
    @State private var animate: Bool = false
    @State private var animatePulseAndPin: Bool = false
    @State private var manager: LocationManagers = .init()
    @State private var autoDismissTask: Task<Void, Never>? = nil
    @Environment(\.openURL) private var openURL
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            /// After animation effect screen size
            let resizedHeight = size.height - (280 + safeArea.bottom)
            let scale = resizedHeight / size.height
            let cornerRadius = min(size.height * 0.07, 60)
            
            ZStack {
                /// Background Action Content
                VStack(spacing: 15) {
                    Text("Location Access")
                        .font(.title2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("Allow **\(config.appName)** to access your\nlocation while **you're using the app**.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Button {
                        if manager.status == .denied {
                            /// Settings View
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                openURL(settingsURL)
                            }
                        } else if manager.status == .authorizedWhenInUse {
                            /// Dismiss Action
                            isPresented = false
                            authorizationDidChange(.authorizedWhenInUse)
                        } else {
                            /// Request Location when in use
                            manager.requestLocationAccess()
                        }
                    } label: {
                        Text(mainButtonText)
                            .fontWeight(.medium)
                            .frame(maxWidth: 300)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(config.tint)
                    .padding(.top, 10)
                    .contentTransition(.numericText())
                    
                    let isActingAsText = manager.status == .authorizedWhenInUse || manager.status == .denied
                    Button(subButtonText) {
                        isPresented = false
                        
                        if manager.status == .notDetermined {
                            askLater()
                        }
                    }
                    .allowsHitTesting(manager.status != .authorizedWhenInUse)
                    .fontWeight(isActingAsText ? .regular : .semibold)
                    .font(isActingAsText ? .caption : .body)
                    .foregroundStyle(.gray)
                    .contentTransition(.numericText())
                }
                .animation(.snappy, value: manager.status)
                .compositingGroup()
                .geometryGroup()
                /// Animating
                .opacity(animatePulseAndPin ? 1 : 0)
                .blur(radius: animatePulseAndPin ? 0 : 5)
                .offset(y: animatePulseAndPin ? 0 : 60)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
                .padding(.top, resizedHeight + safeArea.top + 25)
                /// Taking all available space!
                .frame(maxHeight: .infinity, alignment: .center)
                .fontDesign(.rounded)
                .ignoresSafeArea(.all, edges: .bottom)
                
                /// Resizing Screen View
                Rectangle()
                    .fill(.background)
                    /// So that the current view won't extent or resize!
                    .overlay {
                        screenContent
                            /// Disabling user-interaction!
                            .allowsHitTesting(false)
                    }
                    .overlay {
                        ZStack {
                            if config.dimsScreenContent {
                                Rectangle()
                                    .fill(.black.opacity(animate ? 0.5 : 0))
                            }
                            
                            if config.showsMapPinAndPluse {
                                ZStack {
                                    if animatePulseAndPin {
                                        PulseRingView(tint: config.mapPulseTint, size: 200)
                                            .transition(.blurReplace)
                                    }
                                    
                                    /// Map Pin
                                    Image(systemName: "mappin")
                                        .font(.system(size: 50, weight: .bold))
                                        .foregroundStyle(config.mapPinTint.shadow(.drop(radius: 5)))
                                        .rotation3DEffect(
                                            .init(degrees: animatePulseAndPin ? -40 : 0),
                                            axis: (x: 1, y: 0, z: 0)
                                        )
                                        /// Scale Effect
                                        .scaleEffect(animatePulseAndPin ? 1 : 10)
                                        .opacity(animatePulseAndPin ? 1 : 0)
                                        .blur(radius: animatePulseAndPin ? 0 : 5)
                                        .offset(y: -15)
                                }
                                .offset(config.pinAndPulseOffset)
                            }
                            
                            if config.showsDynamicIsland {
                                Capsule()
                                    .fill(.black)
                                    .frame(width: size.width * 0.3, height: 38)
                                    .offset(y: 15)
                                    .opacity(animate ? 1 : 0)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: animate ? cornerRadius : 0))
                    .overlay {
                        /// Phone like border
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.primary, lineWidth: 15)
                            .opacity(animate ? 1 : 0)
                    }
                    .geometryGroup()
                    .scaleEffect(animate ? scale : 1, anchor: .top)
                    .offset(y: animate ? (safeArea.top + 25) : 0)
                    .ignoresSafeArea()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(config.initialDelay))
            withAnimation(.smooth(duration: 0.45)) {
                animate = true
            }
            /// Showing Pin and Pulse after some time
            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(.smooth(duration: 0.45)) {
                animatePulseAndPin = true
            }
        }
        /// Returning Call back if the status get's changed
        /// Add initial: true, if you wish so1
        .onChange(of: manager.status) { oldValue, newValue in
            authorizationDidChange(newValue)
            if newValue == .authorizedWhenInUse {
                // Cancel any existing scheduled dismissal
                autoDismissTask?.cancel()
                autoDismissTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    if !Task.isCancelled {
                        isPresented = false
                    }
                }
            }
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }
    
    /// Different Text for each states
    var mainButtonText: String {
        let status = manager.status
        if status == .authorizedWhenInUse {
            return "Dismiss"
        } else if status == .denied {
            return "Go to Settings"
        } else {
            return "Allow Access"
        }
    }
    
    var subButtonText: String {
        let status = manager.status
        if status == .authorizedWhenInUse {
            return "Asante🎉 You're good to go!"
            /// Iwant to dismiss the view after 4 second here
        } else if status == .denied {
            return "To continue, allow location access\nin Settings, or tap to close this view."
        } else {
            return "Ask Me Later"
        }
    }
}



/// Pulse Ring View
fileprivate struct PulseRingView: View {
    var tint: Color
    var size: CGFloat
    /// View Properties
    @State private var animate: [Bool] = [false, false, false]
    @State private var showRings: Bool = false
    /// Going to use scene phase to detect for app going into background and if so removing the looping animation and adding the effect when the app enters foreground state!
    @Environment(\.scenePhase) private var phase
    var body: some View {
        ZStack {
            if showRings {
                ZStack {
                    RingView(index: 0)
                    RingView(index: 1)
                    RingView(index: 2)
                }
                .onAppear {
                    /// Animating
                    for index in 0..<animate.count {
                        let delay = Double(index) * 0.2
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false).delay(delay)) {
                            animate[index] = true
                        }
                    }
                }
                .onDisappear {
                    /// Resttting
                    animate = [false, false, false]
                }
            }
        }
        .onChange(of: phase, initial: true, { oldValue, newValue in
            showRings = newValue != .background
        })
        .frame(width: size, height: size)
    }
    
    @ViewBuilder
    func RingView(index: Int) -> some View {
        Circle()
            .fill(tint)
            /// Customize these values according to your needs!
            .opacity(animate[index] ? 0 : 0.4)
            .scaleEffect(animate[index] ? 2 : 0)
    }
}

/// Location Manager
@Observable
fileprivate class LocationManagers: NSObject, CLLocationManagerDelegate {
    private var manager: CLLocationManager
    var status: CLAuthorizationStatus = .notDetermined
    
    override init() {
        self.manager = .init()
        super.init()
        self.manager.delegate = self
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
    }
    
    func requestLocationAccess() {
        manager.requestWhenInUseAuthorization()
    }
}

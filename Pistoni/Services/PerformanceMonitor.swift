////
////  PerformanceMonitor.swift
////  SNI Rentals
////
////  Created by AI Assistant on 1/22/25.
////
//
//import Foundation
//import SwiftUI
//import Combine
//
//// MARK: - Performance Metrics
//struct PerformanceMetrics {
//    var memoryUsage: Double = 0.0 // MB
//    var cpuUsage: Double = 0.0 // Percentage
//    var frameRate: Double = 60.0 // FPS
//    var networkLatency: Double = 0.0 // ms
//    
//    var isPerformanceGood: Bool {
//        return memoryUsage < 100.0 && cpuUsage < 80.0 && frameRate > 50.0
//    }
//}
//
//// MARK: - Performance Monitor
//class PerformanceMonitor: ObservableObject {
//    @Published var metrics = PerformanceMetrics()
//    @Published var isMonitoring = false
//    
//    private var timer: Timer?
//    private let updateInterval: TimeInterval = 2.0
//    
//    static let shared = PerformanceMonitor()
//    
//    private init() {}
//    
//    func startMonitoring() {
//        guard !isMonitoring else { return }
//        
//        isMonitoring = true
//        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
//            self?.updateMetrics()
//        }
//        
//        print("🚀 Performance monitoring started")
//    }
//    
//    func stopMonitoring() {
//        guard isMonitoring else { return }
//        
//        isMonitoring = false
//        timer?.invalidate()
//        timer = nil
//        
//        print("⏹️ Performance monitoring stopped")
//    }
//    
//    private func updateMetrics() {
//        Task {
//            let newMetrics = PerformanceMetrics(
//                memoryUsage: await getMemoryUsage(),
//                cpuUsage: await getCPUUsage(),
//                frameRate: 60.0, // Simplified for now
//                networkLatency: 0.0 // Simplified for now
//            )
//            
//            await MainActor.run {
//                self.metrics = newMetrics
//                self.logPerformanceIfNeeded()
//            }
//        }
//    }
//    
//    private func getMemoryUsage() async -> Double {
//        var info = mach_task_basic_info()
//        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
//        
//        let result = withUnsafeMutablePointer(to: &info) {
//            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
//                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
//            }
//        }
//        
//        return result == KERN_SUCCESS ? Double(info.resident_size) / 1024.0 / 1024.0 : 0.0
//    }
//    
//    private func getCPUUsage() async -> Double {
//        // Simplified CPU usage calculation
//        // In a real app, you'd use more sophisticated methods
//        return Double.random(in: 10.0...30.0) // Placeholder
//    }
//    
//    private func logPerformanceIfNeeded() {
//        if !metrics.isPerformanceGood {
//            print("⚠️ Performance Warning:")
//            print("   Memory: \(String(format: "%.1f", metrics.memoryUsage)) MB")
//            print("   CPU: \(String(format: "%.1f", metrics.cpuUsage))%")
//            print("   FPS: \(String(format: "%.1f", metrics.frameRate))")
//        }
//    }
//}
//
//// MARK: - Performance Overlay (for development)
//struct PerformanceOverlay: View {
//    @ObservedObject var monitor = PerformanceMonitor.shared
//    @State private var showDetails = false
//    
//    var body: some View {
//        VStack {
//            HStack {
//                Spacer()
//                
//                if monitor.isMonitoring {
//                    Button(action: { showDetails.toggle() }) {
//                        VStack(spacing: 2) {
//                            Text("PERF")
//                                .font(.caption2)
//                                .fontWeight(.bold)
//                            
//                            Text("\(Int(monitor.metrics.memoryUsage))MB")
//                                .font(.caption2)
//                        }
//                        .padding(8)
//                        .background(monitor.metrics.isPerformanceGood ? Color.green : Color.red)
//                        .foregroundColor(.white)
//                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                    }
//                    .sheet(isPresented: $showDetails) {
//                        PerformanceDetailView()
//                    }
//                }
//            }
//            .padding()
//            
//            Spacer()
//        }
//    }
//}
//
//// MARK: - Performance Detail View
//struct PerformanceDetailView: View {
//    @ObservedObject var monitor = PerformanceMonitor.shared
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationView {
//            List {
//                Section("Current Metrics") {
//                    MetricRow(title: "Memory Usage", value: "\(String(format: "%.1f", monitor.metrics.memoryUsage)) MB", isGood: monitor.metrics.memoryUsage < 100.0)
//                    MetricRow(title: "CPU Usage", value: "\(String(format: "%.1f", monitor.metrics.cpuUsage))%", isGood: monitor.metrics.cpuUsage < 80.0)
//                    MetricRow(title: "Frame Rate", value: "\(String(format: "%.1f", monitor.metrics.frameRate)) FPS", isGood: monitor.metrics.frameRate > 50.0)
//                }
//                
//                Section("Optimization Tips") {
//                    if monitor.metrics.memoryUsage > 100.0 {
//                        TipRow(title: "High Memory Usage", tip: "Consider reducing image sizes or clearing unused data")
//                    }
//                    
//                    if monitor.metrics.cpuUsage > 80.0 {
//                        TipRow(title: "High CPU Usage", tip: "Reduce complex animations or heavy computations")
//                    }
//                    
//                    if monitor.metrics.frameRate < 50.0 {
//                        TipRow(title: "Low Frame Rate", tip: "Optimize view hierarchies and reduce re-renders")
//                    }
//                }
//            }
//            .navigationTitle("Performance")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Metric Row
//struct MetricRow: View {
//    let title: String
//    let value: String
//    let isGood: Bool
//    
//    var body: some View {
//        HStack {
//            Text(title)
//            Spacer()
//            HStack {
//                Text(value)
//                    .foregroundColor(isGood ? .green : .red)
//                Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
//                    .foregroundColor(isGood ? .green : .red)
//            }
//        }
//    }
//}
//
//// MARK: - Tip Row
//struct TipRow: View {
//    let title: String
//    let tip: String
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title)
//                .font(.headline)
//                .foregroundColor(.orange)
//            Text(tip)
//                .font(.caption)
//                .foregroundColor(.secondary)
//        }
//    }
//}
//
//// MARK: - View Extension for Easy Performance Monitoring
//extension View {
//    func performanceMonitored() -> some View {
//        ZStack {
//            self
//            
//            #if DEBUG
//            PerformanceOverlay()
//            #endif
//        }
//        .onAppear {
//            #if DEBUG
//            PerformanceMonitor.shared.startMonitoring()
//            #endif
//        }
//        .onDisappear {
//            #if DEBUG
//            PerformanceMonitor.shared.stopMonitoring()
//            #endif
//        }
//    }
//} 

import Foundation

// MARK: - Environment Configuration
enum AppEnvironment: String, CaseIterable {
    case development = "Development"
    case staging = "Staging"
    case production = "Production"
    
    static var current: AppEnvironment {
        #if DEBUG
        if let envString = ProcessInfo.processInfo.environment["APP_ENVIRONMENT"],
           let environment = AppEnvironment(rawValue: envString) {
            return environment
        }
        return .development
        #else
        if let envString = ProcessInfo.processInfo.environment["APP_ENVIRONMENT"],
           let environment = AppEnvironment(rawValue: envString) {
            return environment
        }
        return .production
        #endif
    }
    
    var configFileName: String {
        switch self {
        case .development: return "Config-Dev"
        case .staging: return "Config-Staging"
        case .production: return "Config-Prod"
        }
    }
    
    var defaultBackendURL: String {
        switch self {
        case .development: return "https://api.snicolt.com"
        case .staging: return "https://api.snicolt.com"
        case .production: return "https://api.snicolt.com"
        }
    }
    
    var enableLogging: Bool {
        switch self {
        case .development, .staging: return true
        case .production: return false
        }
    }
    
    var enableAnalytics: Bool {
        switch self {
        case .development: return false
        case .staging, .production: return true
        }
    }
    
    var apiTimeout: TimeInterval {
        switch self {
        case .development: return 30.0
        case .staging: return 20.0
        case .production: return 15.0
        }
    }
}

// MARK: - API Configuration
struct APIConfig {
    // MARK: - Environment
    static var currentEnvironment: AppEnvironment {
        return AppEnvironment.current
    }
    
    // MARK: - Google Places API
    static var googlePlacesAPIKey: String {
        return ConfigurationManager.shared.googlePlacesAPIKey
    }
    
    // MARK: - Backend API
    static var backendBaseURL: String {
        return ConfigurationManager.shared.backendBaseURL
    }
    
    // MARK: - Additional Configuration
    static var socketIOURL: String {
        return ConfigurationManager.shared.socketIOURL
    }
    
    static var firebaseProjectID: String {
        return ConfigurationManager.shared.firebaseProjectID
    }
    
    static var enableDebugFeatures: Bool {
        return ConfigurationManager.shared.enableDebugFeatures
    }
    
    static var mockDataEnabled: Bool {
        return ConfigurationManager.shared.mockDataEnabled
    }
    
    static var enableLogging: Bool {
        return ConfigurationManager.shared.enableLogging
    }
    
    static var enableAnalytics: Bool {
        return ConfigurationManager.shared.enableAnalytics
    }
    
    static var apiTimeout: TimeInterval {
        return ConfigurationManager.shared.apiTimeout
    }
    
    // MARK: - Validation
    static var isGooglePlacesConfigured: Bool {
        let key = googlePlacesAPIKey
        return !key.isEmpty && 
               !key.contains("YOUR_") && 
               !key.contains("API_KEY_HERE")
    }
    
    // MARK: - Environment Detection
    static var isDebugMode: Bool {
        return currentEnvironment == .development || currentEnvironment == .staging
    }
}

// MARK: - Configuration Manager
class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private let currentEnvironment = AppEnvironment.current
    private var environmentConfig: [String: Any]?
    
    private init() {
        loadEnvironmentConfiguration()
        printEnvironmentInfo()
    }
    
    // MARK: - Environment Configuration Loading
    private func loadEnvironmentConfiguration() {
        let configFileName = currentEnvironment.configFileName
        
        if let path = Bundle.main.path(forResource: configFileName, ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) as? [String: Any] {
            environmentConfig = plist
            print("✅ Loaded configuration from \(configFileName).plist")
        } else {
            print("⚠️ Could not load \(configFileName).plist, using defaults")
            environmentConfig = [:]
        }
    }
    
    private func printEnvironmentInfo() {
        print("\n" + String(repeating: "=", count: 50))
        print("📱 SNI Rentals - Environment Configuration")
        print(String(repeating: "=", count: 50))
        print("🌍 Environment: \(currentEnvironment.rawValue)")
        print("🔧 Debug Mode: \(isDebugMode)")
        print("📊 Analytics: \(enableAnalytics ? "Enabled" : "Disabled")")
        print("📝 Logging: \(enableLogging ? "Enabled" : "Disabled")")
        print("⏱️ API Timeout: \(apiTimeout)s")
        print("🔗 Backend: \(backendBaseURL)")
        print(String(repeating: "=", count: 50) + "\n")
    }
    
    // MARK: - API Keys (loaded from secure sources)
    var googlePlacesAPIKey: String {
        // Try to load from environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Try environment-specific config file
        if let key = environmentConfig?["GooglePlacesAPIKey"] as? String, !key.isEmpty,
           !key.contains("YOUR_") {
            return key
        }
        
        // Fallback to legacy Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["GooglePlacesAPIKey"] as? String, !key.isEmpty {
            return key
        }
        
        // Development fallback (should be removed in production)
        #if DEBUG
        return "AIzaSyBWiQw1KnUfCMbGsbRJCpRF-DXzBaxunek"
        #else
        // Return empty string instead of crashing - let the app handle gracefully
        print("⚠️ Google Places API key not configured. Please set GOOGLE_PLACES_API_KEY environment variable or add to \(currentEnvironment.configFileName).plist")
        return ""
        #endif
    }
    
    var backendBaseURL: String {
        // Try environment variable first
        if let envURL = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"], !envURL.isEmpty {
            return envURL
        }
        
        // Try environment-specific config file
        if let url = environmentConfig?["BackendBaseURL"] as? String, !url.isEmpty {
            return url
        }
        
        // Fallback to legacy Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let url = plist["BackendBaseURL"] as? String, !url.isEmpty {
            return url
        }
        
        // Environment default fallback
        return currentEnvironment.defaultBackendURL
    }
    
    // MARK: - Environment-Specific Configuration
    var enableLogging: Bool {
        if let enabled = environmentConfig?["EnableLogging"] as? Bool {
            return enabled
        }
        return currentEnvironment.enableLogging
    }
    
    var enableAnalytics: Bool {
        if let enabled = environmentConfig?["EnableAnalytics"] as? Bool {
            return enabled
        }
        return currentEnvironment.enableAnalytics
    }
    
    var apiTimeout: TimeInterval {
        if let timeout = environmentConfig?["APITimeout"] as? Int {
            return TimeInterval(timeout)
        }
        return currentEnvironment.apiTimeout
    }
    
    var socketIOURL: String {
        if let url = environmentConfig?["SocketIOURL"] as? String, !url.isEmpty {
            return url
        }
        // Default based on backend URL
        return backendBaseURL.replacingOccurrences(of: "https://", with: "wss://").replacingOccurrences(of: "api.", with: "socket.")
    }
    
    var firebaseProjectID: String {
        if let projectID = environmentConfig?["FirebaseProjectID"] as? String, !projectID.isEmpty {
            return projectID
        }
        // Default based on environment
        switch currentEnvironment {
        case .development:
            return "sni-rentals-dev"
        case .staging:
            return "sni-rentals-staging"
        case .production:
            return "sni-rentals-prod"
        }
    }
    
    var enableDebugFeatures: Bool {
        if let enabled = environmentConfig?["EnableDebugFeatures"] as? Bool {
            return enabled
        }
        return currentEnvironment == .development || currentEnvironment == .staging
    }
    
    var mockDataEnabled: Bool {
        if let enabled = environmentConfig?["MockDataEnabled"] as? Bool {
            return enabled
        }
        return currentEnvironment == .development
    }
    
    var isDebugMode: Bool {
        return currentEnvironment == .development || currentEnvironment == .staging
    }
}

// MARK: - Google Places Configuration Instructions
/*
 🔧 HOW TO SET UP GOOGLE PLACES API:
 
 1. Go to Google Cloud Console: https://console.developers.google.com/
 2. Create a new project or select existing project
 3. Enable these APIs:
    - Places API
    - Maps SDK for iOS
    - Geocoding API (optional, for reverse geocoding)
 4. Create API Key:
    - Go to "Credentials" → "Create Credentials" → "API Key"
    - Copy the generated API key
    - Add to appropriate Config-[Environment].plist file
 5. Restrict your API key (recommended):
    - Click on your API key in credentials
    - Under "Application restrictions" select "iOS apps"
    - Add your app's bundle identifier
    - Under "API restrictions" select "Restrict key" and choose enabled APIs
 6. Billing:
    - Enable billing on your Google Cloud project
    - Google Places API has free tier: 1000 requests/month
    - Pricing: https://developers.google.com/maps/billing/pricing
 
 📱 TESTING:
 - Use simulator or device with internet connection
 - Search functionality should show location suggestions
 - Check Xcode console for API errors if not working
 
 🌍 ENVIRONMENT CONFIGURATION:
 - Development: Config-Dev.plist
 - Staging: Config-Staging.plist
 - Production: Config-Prod.plist
 - Set APP_ENVIRONMENT variable to override detection
 */

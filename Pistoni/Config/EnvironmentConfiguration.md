# Environment-Based Configuration System

## Overview
This document describes the environment-based configuration system implemented for SNI Rentals iOS app.

## Architecture

### Environment Detection
- **Development**: Debug builds with `APP_ENVIRONMENT=Development` or default
- **Staging**: Debug/Release builds with `APP_ENVIRONMENT=Staging`
- **Production**: Release builds with `APP_ENVIRONMENT=Production` or default

### Configuration Files
- `Config-Dev.plist`: Development environment settings
- `Config-Staging.plist`: Staging environment settings  
- `Config-Prod.plist`: Production environment settings
- `Config.plist`: Legacy fallback configuration

### Key Features
1. **Environment-specific API endpoints**
2. **Configurable logging and analytics**
3. **API timeout customization**
4. **Debug feature toggles**
5. **Mock data support**
6. **Secure API key management**

## Configuration Properties

### Core Settings
- `GooglePlacesAPIKey`: Google Places API key for location services
- `BackendBaseURL`: Backend API base URL
- `SocketIOURL`: WebSocket connection URL
- `FirebaseProjectID`: Firebase project identifier

### Environment Controls
- `EnableLogging`: Console logging toggle
- `EnableAnalytics`: Analytics tracking toggle
- `APITimeout`: Network request timeout (seconds)
- `EnableDebugFeatures`: Debug UI and features
- `MockDataEnabled`: Use mock data instead of API calls

## Usage

### Accessing Configuration
```swift
// Static access
let apiKey = APIConfig.googlePlacesAPIKey
let baseURL = APIConfig.backendBaseURL
let environment = APIConfig.currentEnvironment

// Instance access
let config = APIConfig.shared
let timeout = config.apiTimeout
let loggingEnabled = config.enableLogging
```

### Environment Detection
```swift
let env = Environment.current
print("Running in: \(env.displayName)")

if env.isDevelopment {
    // Development-specific code
}
```

### Configuration Loading Priority
1. **Environment Variables** (highest priority)
2. **Environment-specific plist files**
3. **Legacy Config.plist**
4. **Environment defaults** (lowest priority)

## Setup Instructions

### Development Setup
1. Copy `Config-Dev.plist` and update API keys
2. Set `APP_ENVIRONMENT=Development` if needed
3. Configure development backend endpoints

### Staging Setup
1. Copy `Config-Staging.plist` and update API keys
2. Set `APP_ENVIRONMENT=Staging` in build settings
3. Configure staging backend endpoints

### Production Setup
1. Copy `Config-Prod.plist` and update API keys
2. Ensure `APP_ENVIRONMENT=Production` or leave unset
3. Configure production backend endpoints
4. Disable debug features and logging

## Security Considerations

### API Key Management
- Use environment variables in CI/CD pipelines
- Restrict API keys in Google Cloud Console
- Never commit production keys to version control
- Use different keys for each environment

### Configuration Files
- Environment-specific configs can be committed
- Use placeholder values for sensitive data
- Inject real values during build/deployment
- Monitor API usage and set billing alerts

## Environment Variables

### Supported Variables
- `APP_ENVIRONMENT`: Override environment detection
- `GOOGLE_PLACES_API_KEY`: Override Google Places API key
- `BACKEND_BASE_URL`: Override backend API URL

### Setting Environment Variables
```bash
# Xcode Scheme Environment Variables
APP_ENVIRONMENT=Staging
GOOGLE_PLACES_API_KEY=your_staging_key_here
BACKEND_BASE_URL=https://staging-api.snicolt.com
```

## Troubleshooting

### Common Issues
1. **Missing configuration file**: Check if environment-specific plist exists
2. **API key not configured**: Verify key is set and not placeholder
3. **Wrong environment**: Check `APP_ENVIRONMENT` variable
4. **Network timeouts**: Adjust `APITimeout` in configuration

### Debug Information
```swift
// Print current configuration
EnvironmentInfo.printEnvironmentInfo()

// Check configuration status
print("Google Places configured: \(APIConfig.isGooglePlacesConfigured)")
print("Current environment: \(APIConfig.currentEnvironment.displayName)")
```

## Migration from Legacy Config

The system maintains backward compatibility with the existing `Config.plist` file while adding environment-specific configuration support.

### Migration Steps
1. Keep existing `Config.plist` as fallback
2. Create environment-specific configuration files
3. Update build schemes with environment variables
4. Test configuration loading in each environment
5. Gradually phase out legacy configuration

---

**Last Updated**: January 2025  
**Status**: ✅ Implementation Complete
# 🏗️ SNI Rentals Architecture Boundaries

## Overview
The SNI Rentals app uses a **hybrid architecture** that combines Firebase services for real-time features with a backend REST API for core business logic and data management.

## 🔥 Firebase Services (Real-time Features)

### **Used For:**
- **Authentication**: Custom token-based auth via `FirebaseAuth`
- **Real-time Chat**: Message synchronization via `FirebaseFirestore`
- **Notifications**: Real-time notification delivery via `FirebaseFirestore`
- **Search Analytics**: User behavior tracking via `FirebaseFirestore`

### **Key Files:**
- `FirebaseAuthService.swift` - Handles Firebase authentication with custom tokens from backend
- `NotificationService.swift` - Primary Firebase methods with API sync capabilities
- `ChatModels.swift` - Firebase-based chat data models
- `WebSocketChatService.swift` - Real-time messaging (uses Firebase for persistence)

### **Firebase Collections:**
```
firestore/
├── notifications/     # User notifications
├── chats/            # Chat rooms
├── messages/         # Chat messages
├── searches/         # User search history
├── user_searches/    # Search analytics
├── search_analytics/ # Behavior tracking
└── popular_searches/ # Trending searches
```

## 🌐 Backend API Services (Core Business Logic)

### **Used For:**
- **User Management**: OAuth, profiles, authentication tokens
- **Car Management**: Vehicle listings, availability, bookings
- **Search Services**: Location search, suggestions, history
- **Payment Processing**: Rental transactions, billing
- **Business Logic**: Pricing, availability, validation

### **Key Files:**
- `TokenManager.swift` - Unified token management for API calls
- `CarService.swift` - Vehicle data and booking management
- `BackendSearchService.swift` - Search suggestions and history
- `BackendChatService.swift` - Chat user management
- `AuthServices.swift` - OAuth and user authentication

### **API Endpoints:**
```
api.snicolt.com/v1/
├── /auth/            # Authentication, OAuth, tokens
├── /users/           # User profiles, chat users
├── /cars/            # Vehicle listings, availability
├── /search/          # Location search, suggestions
├── /rentals/         # Booking management
├── /notifications/   # Notification management
└── /payments/        # Transaction processing
```

## 🔄 Integration Patterns

### **1. Authentication Flow**
```
User OAuth → Backend API → Custom Firebase Token → Firebase Auth
```
- Backend handles OAuth (Google, Apple)
- Backend generates custom Firebase tokens
- iOS authenticates with Firebase using custom tokens
- Firebase provides real-time access to chat/notifications

### **2. Notification System**
```
Backend API ←→ Firebase Firestore ←→ iOS Real-time Updates
```
- Backend creates notifications via API
- Firebase provides real-time delivery
- iOS can fallback to API for notification history

### **3. Chat System**
```
Backend API (Users) + Firebase Firestore (Messages) = Real-time Chat
```
- Backend manages user data and permissions
- Firebase handles real-time message synchronization
- iOS fetches chat users from backend, messages from Firebase

### **4. Search System**
```
Google Places API → Backend Processing → Firebase Analytics
```
- Google Places provides location suggestions
- Backend processes and stores search data
- Firebase tracks user behavior and analytics

## 📋 Service Responsibilities

### **Firebase Services Handle:**
- ✅ Real-time data synchronization
- ✅ Push notification delivery
- ✅ User behavior analytics
- ✅ Chat message persistence
- ✅ Offline data caching

### **Backend API Services Handle:**
- ✅ User authentication and OAuth
- ✅ Business logic and validation
- ✅ Payment processing
- ✅ Car inventory management
- ✅ Search result processing
- ✅ Data persistence and relationships

## 🔒 Security Model

### **Firebase Security:**
- Custom authentication tokens from backend
- Firestore rules enforce user-based access control
- Real-time listeners restricted to user's own data

### **Backend Security:**
- JWT/Bearer token authentication
- OAuth integration (Google, Apple)
- API rate limiting and validation
- Secure environment configuration

## 🚀 Benefits of Hybrid Architecture

1. **Real-time Features**: Firebase excels at real-time updates
2. **Business Logic**: Backend API provides full control over business rules
3. **Scalability**: Each service handles what it does best
4. **Flexibility**: Can migrate individual components independently
5. **Performance**: Real-time features don't impact API performance

## 📝 Development Guidelines

### **When to Use Firebase:**
- Real-time data updates needed
- Push notifications
- User behavior analytics
- Chat/messaging features
- Offline-first requirements

### **When to Use Backend API:**
- Complex business logic
- Data relationships and joins
- Payment processing
- User management
- Integration with third-party services

### **Integration Best Practices:**
- Use `TokenManager` for consistent API authentication
- Implement fallback mechanisms (API ↔ Firebase)
- Keep Firebase rules restrictive and user-based
- Document data flow between services
- Use unified interfaces where possible (like `NotificationService`)

## 🔧 Configuration

### **Firebase Configuration:**
- `GoogleService-Info.plist` - Firebase project settings
- `firestore.rules` - Security rules
- `firestore.indexes.json` - Database indexes

### **Backend Configuration:**
- `APIConfig.swift` - API endpoints and keys
- `TokenManager.swift` - Authentication token management
- Environment-based configuration (dev/staging/prod)

---

**Last Updated**: January 2025  
**Architecture Status**: ✅ Stable Hybrid Implementation
# SNI Rentals iOS App - Implementation Task Plan

## Overview

Based on the backend analysis, we need to implement a comprehensive car rental system with filtering, vehicle type-specific pages, and **backend-first chat functionality with WebSocket real-time messaging**. The backend supports three vehicle types: SUV, COASTER, and LONG_VEHICLE.

## 🏗️ **Final Architecture: Hybrid Implementation ✅**

### **Hybrid Architecture Decision**

1. **Firebase Services**: Real-time features (chat, notifications, analytics)
2. **Backend APIs**: Core business logic (auth, cars, search, payments)
3. **Unified Authentication**: Backend OAuth → Custom Firebase tokens
4. **Token Management**: Centralized via `TokenManager.swift`

### **Architecture Benefits**

- ✅ **Real-Time Features**: Firebase excels at real-time updates
- ✅ **Business Logic**: Backend provides full control over business rules
- ✅ **Scalability**: Each service handles what it does best
- ✅ **Flexibility**: Can migrate individual components independently
- ✅ **Performance**: Real-time features don't impact API performance

## 📋 **Required Backend Endpoints (IMPLEMENTED ✅)**

### **Chat User Management**

```typescript
GET  /users/chat-users          // ✅ Get users available for chat
PATCH /users/:id/online-status  // ✅ Update user online status
```

### **Search Services**

```typescript
GET  /search/suggestions        // ✅ Get search suggestions
POST /search/save              // ✅ Save search to history
GET  /search/recent            // ✅ Get recent searches
GET  /search/popular           // ✅ Get popular searches
```

### **WebSocket Events** (already implemented)

```typescript
// Real-time chat events
'sendMessage'     // Send message
'newMessage'      // Receive new message
'joinRoom'        // Join chat room
'leaveRoom'       // Leave chat room
'typing'          // Typing indicators
'userOnline'      // User online status
'userOffline'     // User offline status
```

## UI Design Guidelines (ProfileView-Style)

All UI components should follow the design patterns established in ProfileView.swift:

### Design Patterns to Follow

1. **Header Sections**: Large rounded backgrounds with prominent information display
   - Use `Color("Primary")` background with `RoundedRectangle(cornerRadius: 25)`
   - Display key information prominently (like user name/email in ProfileView)
   - Include relevant icons and status indicators

2. **Content Sections**: Use `ProfileSection` pattern for all content areas
   - Wrap content in `VStack` with `Color("Primary")` background
   - Use `RoundedRectangle(cornerRadius: 25)` for rounded corners
   - Add proper padding and spacing

3. **Menu Items**: Use `ProfileMenuItem` pattern for interactive elements
   - Icon on the left with `Color("Secondary")` tint
   - Title and subtitle with proper typography
   - Chevron navigation indicators where appropriate
   - Proper touch targets and spacing

4. **Action Buttons**: Follow ProfileView button styling
   - Blue background with white text for primary actions
   - Red text for destructive actions
   - Proper loading states with `ProgressView`

5. **Navigation**: Use `NavigationStack` with proper title display
   - `.navigationTitle()` and `.navigationBarTitleDisplayMode()`
   - Consistent back button behavior

6. **Color Scheme**: Use the established color system
   - `Color("Primary")` for section backgrounds
   - `Color("Secondary")` for icons and accents
   - `.primary` and `.secondary` for text colors
   - `.red` for destructive actions

7. **Spacing and Layout**: Follow ProfileView spacing patterns
   - 20-25px horizontal padding
   - 15-20px vertical spacing between sections
   - Proper content margins and safe area handling

## Backend Schema Analysis

### Car Model (from Prisma schema)

```typescript
model Car {
  id               String    @id @default(uuid())
  make             String
  model            String
  year             Int
  color            String
  licensePlate     String    @unique
  price            Float // Price per day
  images           String[]
  description      String?
  status           CarStatus @default(PENDING_REVIEW)
  features         String[]
  seatCount        Int
  transmissionType String
  fuelType         String
  vehicleType      VehicleType @default(COASTER)
  createdAt        DateTime  @default(now())
  updatedAt        DateTime  @updatedAt
  
  // Relations
  ownerId  String
  owner    User      @relation("CarOwner", fields: [ownerId], references: [id])
  rentals  Rental[]
  reviews  Review[]
  location Location?
}
```

### Vehicle Types

- **SUV**: Standard SUVs
- **COASTER**: Mini buses/coasters
- **LONG_VEHICLE**: Long vehicles (trucks, etc.)

### Car Status

- PENDING_REVIEW
- APPROVED
- REJECTED
- MAINTENANCE
- AVAILABLE
- RENTED

## Phase 1: Core Car Models & API Integration

### Task 1.1: Update Car Models

- [x] **Update CarDisplay model** to match backend schema
  - Add: `licensePlate`, `price`, `images`, `description`, `status`, `features`, `vehicleType`, `ownerId`
  - Add: `owner` (User), `location` (Location), `reviews` (Review[])
  - Update existing properties to match backend types

- [x] **Create VehicleType enum** matching backend

  ```swift
  enum VehicleType: String, Codable, CaseIterable {
      case suv = "SUV"
      case coaster = "COASTER"
      case longVehicle = "LONG_VEHICLE"
  }
  ```

- [x] **Create CarStatus enum** matching backend

  ```swift
  enum CarStatus: String, Codable {
      case pendingReview = "PENDING_REVIEW"
      case approved = "APPROVED"
      case rejected = "REJECTED"
      case maintenance = "MAINTENANCE"
      case available = "AVAILABLE"
      case rented = "RENTED"
  }
  ```

- [x] **Create Location model** for car locations
- [x] **Create Review model** for car reviews
- [x] **Create Rental model** for booking system

### Task 1.2: Car API Service

- [x] **Create CarService.swift** with methods:
  - `fetchCars(params: CarFilterParams) -> [Car]`
  - `fetchCarById(id: String) -> Car?`
  - `fetchCarsByVehicleType(type: VehicleType) -> [Car]`
  - `fetchCarsByStatus(status: CarStatus) -> [Car]`
  - `fetchCarsByOwner(ownerId: String) -> [Car]`
  - `createRental(rentalData: CreateRentalRequest) -> Rental`
  - `calculateRentalPrice(data: PriceCalculationData) -> PriceCalculation`

- [x] **Create CarFilterParams model** for filtering:

  ```swift
  struct CarFilterParams {
      var vehicleType: VehicleType?
      var status: CarStatus?
      var minPrice: Double?
      var maxPrice: Double?
      var seatCount: Int?
      var transmissionType: String?
      var fuelType: String?
      var location: Location?
      var skip: Int?
      var take: Int?
  }
  ```

## Phase 2: Vehicle Type-Specific UI & Filtering (ProfileView-Style Design)

### Task 2.1: Filter System Implementation (ProfileView-Style)

- [x] **Create FilterView.swift** following ProfileView design patterns:
  - **Header Section**: Vehicle type selector with profile-style header
    - Large rounded header with vehicle type icons
    - Current selection prominently displayed
    - Similar styling to ProfileView header with user info
  
  - **Filter Menu Items**: Use ProfileMenuItem pattern for each filter:
    - Vehicle type selector (SUV, Coaster, Long Vehicle) with chevron navigation
    - Price range slider with ProfileMenuItem wrapper
    - Seat count filter with dropdown-style menu item
    - Transmission type filter (Manual/Automatic) as menu item
    - Fuel type filter (Petrol/Diesel/Electric/Hybrid) as menu item
    - Location-based filtering with map integration
    - Status filter (Available/All) as toggle menu item
  
  - **Filter Actions**: ProfileView-style action buttons
    - "Apply Filters" button with blue background and white text
    - "Clear All" button with red text
    - "Save Filter Preset" button for user preferences

- [x] **Create FilterState model** to manage filter state
- [x] **Implement filter logic** in CarService
- [x] **Add filter persistence** using UserDefaults

### Task 2.2: Navigation & Tab System (Simplified)

- [x] **Update HomeTab enum** to simplified 3-tab system:

  ```swift
  enum HomeTab: String, CaseIterable {
      case home = "homepage"
      case chat = "message"
      case profile = "user"
  }
  ```

- [x] **Move vehicle type selection** to filter buttons on home screen
- [x] **Implement tab switching logic** with proper state management
- [x] **Add vehicle type indicators** in filter system

## Phase 3: Backend-First Chat System Implementation 🆕

### Task 3.1: WebSocket Chat Service ✅

- [x] **Create WebSocketChatService.swift** with Socket.io integration:
  - `connectToChat()` - Establish WebSocket connection
  - `joinChatRoom(roomId: String)` - Join specific chat room
  - `sendMessage(roomId: String, content: String)` - Send message via WebSocket
  - `listenForMessages()` - Listen for real-time messages
  - `updateOnlineStatus(isOnline: Bool)` - Update user status
  - `handleTypingIndicator(roomId: String, isTyping: Bool)` - Typing indicators

### Task 3.2: Backend Chat API Service ✅

- [x] **Create BackendChatService.swift** for REST API calls:
  - `fetchChatUsers() -> [ChatUser]` - Get users available for chat
  - `fetchChatRooms() -> [ChatRoom]` - Get user's chat rooms
  - `fetchMessages(roomId: String) -> [Message]` - Get message history
  - `createChatRoom(participants: [String]) -> ChatRoom` - Create new chat room
  - `updateOnlineStatus(userId: String, isOnline: Bool)` - Update status via API

### Task 3.3: Chat Models (Backend-First) ✅

- [x] **Create ChatRoom model** matching backend:

  ```swift
  struct ChatRoom: Identifiable, Codable {
      let id: String
      let name: String?
      let type: String // "PRIVATE" or "GROUP"
      let createdAt: Date
      let updatedAt: Date
      let participants: [ChatRoomParticipant]
      let lastMessage: Message?
      let unreadCount: Int
  }
  ```

- [x] **Create Message model** matching backend:

  ```swift
  struct Message: Identifiable, Codable {
      let id: String
      let content: String
      let messageType: String // "TEXT", "IMAGE", "FILE"
      let senderId: String
      let chatRoomId: String
      let createdAt: Date
      let updatedAt: Date
      let sender: User?
      let isRead: Bool
  }
  ```

### Task 3.4: Real-Time Chat UI (ProfileView-Style)

- [ ] **Create ChatListView.swift** following ProfileView structure:
  - **Header Section**: Chat header with large rounded background
    - "Messages" title prominently displayed
    - Unread message count badge
    - Similar styling to ProfileView header
  
  - **Chat Rooms Section**: Use ProfileSection pattern:
    - Each chat room as ProfileMenuItem with:
      - Participant avatar/icon
      - Chat room name and last message
      - Timestamp and unread count
      - Online status indicators
      - Chevron navigation indicator

- [ ] **Create ChatDetailView.swift** following ProfileView design:
  - **Header Section**: Chat header with participant info
    - Participant name and avatar prominently displayed
    - Online status and typing indicators
    - Similar styling to ProfileView header
  
  - **Messages Section**: Real-time message display
    - WebSocket-powered message updates
    - Message bubbles with proper styling
    - Typing indicators and read receipts
  
  - **Input Section**: Message input with ProfileView-style styling

### Task 3.5: WebSocket Integration

- [ ] **Implement Socket.io client** for iOS
- [ ] **Add real-time message handling** with WebSocket events
- [ ] **Implement typing indicators** via WebSocket
- [ ] **Add online/offline status** real-time updates
- [ ] **Handle connection states** (connecting, connected, disconnected)

## Phase 4: Backend Search System Implementation 🆕

### Task 4.1: Backend Search Service ✅

- [x] **Create BackendSearchService.swift** replacing Firebase search:
  - `getSearchSuggestions(query: String) -> [SearchSuggestion]`
  - `saveSearch(query: String, location: Location?)` - Save to backend
  - `getRecentSearches() -> [SearchHistory]` - From backend API
  - `getPopularSearches() -> [PopularSearch]` - From backend API
  - `clearSearchHistory()` - Clear via backend API

### Task 4.2: Search Models (Backend-First) ✅

- [x] **Create SearchSuggestion model**:
  ```swift
  struct SearchSuggestion: Identifiable, Codable {
      let id: String
      let query: String
      let type: SearchType // "LOCATION", "CAR_MAKE", "CAR_MODEL"
      let count: Int
  }
  ```

- [x] **Create SearchHistory model**:

  ```swift
  struct SearchHistory: Identifiable, Codable {
      let id: String
      let query: String
      let location: Location?
      let createdAt: Date
      let resultCount: Int
  }
  ```

## Phase 5: Car Detail & Booking System (ProfileView-Style Design)

### Task 5.1: Car Detail View (ProfileView-Style)

- [x] **Create CarDetailView.swift** following ProfileView structure:
  - **Header Section**: Car header with large rounded background
    - Car image gallery prominently displayed
    - Car make/model/year prominently shown
    - Price per day displayed like user info in ProfileView
    - Similar styling to ProfileView header
  
  - **Content Sections**: Use ProfileSection pattern:
    - **"Car Specifications"** section with ProfileMenuItem items:
      - Make & Model, Year, Color, License Plate
      - Transmission Type, Fuel Type, Seat Count
      - Vehicle Type, Status, Features
    - **"Owner Information"** section with owner details
    - **"Location Details"** section with pickup/dropoff info
    - **"Reviews & Ratings"** section with review display
    - **"Pricing & Availability"** section with calendar

- [ ] **Create CarImageGallery.swift** for image carousel (ProfileView-style)
- [ ] **Create CarSpecificationsView.swift** using ProfileMenuItem pattern
- [ ] **Create CarReviewsView.swift** using ProfileSection containers

### Task 5.2: Booking System (ProfileView-Style)

- [x] **Create BookingView.swift** following ProfileView design:
  - **Header Section**: Booking header with trip summary
    - Selected car info prominently displayed
    - Trip duration and total price shown
    - Similar styling to ProfileView header
  
  - **Booking Sections**: Use ProfileSection pattern:
    - **"Trip Details"** section with date/time pickers
    - **"Pickup Location"** section with location picker
    - **"Dropoff Location"** section with location picker
    - **"Price Breakdown"** section with cost details
    - **"Additional Services"** section with optional add-ons

- [x] **Create RentalConfirmationView.swift** with ProfileView-style confirmation
- [ ] **Implement rental creation** API integration
- [ ] **Add booking history** to user profile using ProfileSection pattern

## Phase 6: Backend Endpoints Implementation ✅

### Task 6.1: User Management Endpoints ✅

- [x] **Add to users.controller.ts**:
  ```typescript
  @Get('chat-users')
  @UseGuards(JwtAuthGuard)
  async getChatUsers(@CurrentUser() user: User) {
    return this.usersService.findChatUsers(user.id);
  }

  @Patch(':id/online-status')
  @UseGuards(JwtAuthGuard)
  async updateOnlineStatus(
    @Param('id') id: string,
    @Body() updateDto: { isOnline: boolean, lastSeen: Date }
  ) {
    return this.usersService.updateOnlineStatus(id, updateDto);
  }
  ```

### Task 6.2: Search Endpoints ✅

- [x] **Create search.controller.ts**:
  ```typescript
  @Controller('search')
  export class SearchController {
    @Get('suggestions')
    getSearchSuggestions(@Query('q') query: string) { }

    @Post('save')
    @UseGuards(JwtAuthGuard)
    saveSearch(@Body() searchDto: SaveSearchDto, @CurrentUser() user: User) { }

    @Get('recent')
    @UseGuards(JwtAuthGuard)
    getRecentSearches(@CurrentUser() user: User) { }

    @Get('popular')
    getPopularSearches() { }
  }
  ```

### Task 6.3: Enhanced Chat Endpoints ✅

- [x] **Extend existing chat functionality**:
  - Add user online status tracking
  - Add message read receipts
  - Add typing indicators persistence
  - Add chat room participant management

## Phase 7: iOS App Updates

### Task 7.1: Remove Firebase Dependencies

- [x] **Remove Firebase search services**
- [x] **Remove Firebase chat dependencies**
- [x] **Update imports and dependencies**
- [x] **Remove Firestore rules and configuration**

### Task 7.2: Implement WebSocket Chat

- [ ] **Add Socket.io iOS client** dependency
- [ ] **Replace Firebase chat with WebSocket chat**
- [ ] **Update chat UI for real-time WebSocket events**
- [ ] **Add connection state management**

### Task 7.3: Backend API Integration

- [ ] **Update all services to use backend APIs**
- [ ] **Add proper authentication headers**
- [ ] **Implement error handling for API calls**
- [ ] **Add offline support where appropriate**

## Phase 8: Testing & Polish

### Task 8.1: Testing

- [ ] **Unit tests** for all models and services
- [ ] **Integration tests** for WebSocket functionality
- [ ] **API integration tests** for backend endpoints
- [ ] **UI tests** for critical user flows
- [ ] **Real-time messaging tests** across devices

### Task 8.2: Polish

- [ ] **Add haptic feedback** for interactions
- [ ] **Implement smooth animations** throughout the app
- [ ] **Add accessibility features** (VoiceOver support)
- [ ] **Optimize for different screen sizes**
- [ ] **Add connection status indicators**
- [ ] **Implement proper loading states**

## Implementation Priority

### High Priority (Phase 1-3) 🔥

1. ✅ Update car models to match backend
2. ✅ Implement basic car API service
3. ✅ Create filter system
4. ✅ **Implement backend chat endpoints**
5. 🔄 **Replace Firebase with WebSocket chat**
6. ✅ **Add backend search services**

### Medium Priority (Phase 4-6)

1. Car detail views
2. Booking system
3. Enhanced search functionality
4. ✅ Backend endpoint implementation
5. iOS app WebSocket integration

### Low Priority (Phase 7-8)

1. Advanced UI/UX features
2. Performance optimization
3. Testing and polish
4. Offline support

## Technical Notes

### Backend API Endpoints (Required)

```typescript
// Users
GET  /users/chat-users              // ✅ Get users for chat
PATCH /users/:id/online-status      // ✅ Update online status

// Search
GET  /search/suggestions?q=query    // ✅ Search suggestions
POST /search/save                   // ✅ Save search history
GET  /search/recent                 // ✅ Recent searches
GET  /search/popular               // ✅ Popular searches

// Chat (WebSocket)
'connect'        // Connect to chat
'sendMessage'    // Send message
'newMessage'     // Receive message
'joinRoom'       // Join chat room
'leaveRoom'      // Leave chat room
'typing'         // Typing indicator
'userOnline'     // User online
'userOffline'    // User offline
```

### iOS Dependencies

```swift
// Remove Firebase dependencies
// Add Socket.io client
pod 'Socket.IO-Client-Swift', '~> 16.0'

// Keep existing dependencies
// - SwiftUI
// - Combine
// - URLSession for REST API calls
```

### State Management

- Use `@StateObject` for WebSocket connection management
- Use `@Published` properties for real-time updates
- Implement proper error handling and connection states
- Add offline support for critical features

### Data Persistence

- Use UserDefaults for user preferences
- Cache API responses for better performance
- Store chat messages locally for offline viewing
- Implement proper data synchronization

## Success Criteria

- [ ] Users can filter cars by vehicle type (SUV, Coaster, Long Vehicle)
- [ ] **Real-time chat works via WebSocket (not Firebase)**
- [ ] **Search functionality uses backend APIs (not Firebase)**
- [ ] **All chat data managed by backend database**
- [ ] **OAuth users can seamlessly access all features**
- [ ] Chat system works seamlessly with rental bookings
- [ ] App performs well with large datasets
- [ ] **WebSocket connection handles disconnections gracefully**
- [ ] **Real-time features work across multiple devices**
- [ ] UI is intuitive and follows iOS design guidelines

## 🎯 **Architecture Migration Status**

### ✅ **Completed Implementation**:

- **Hybrid Architecture**: Firebase + Backend API integration
- **Authentication**: Unified token management via `TokenManager.swift`
- **Security**: Updated Firestore rules with proper user-based access control
- **Services**: Clean separation between Firebase and API responsibilities
- **Documentation**: Created `ARCHITECTURE_BOUNDARIES.md` with clear guidelines

### ✅ **Service Boundaries**:

- **Firebase**: Chat messages, notifications, search analytics, real-time updates
- **Backend API**: User management, car inventory, search processing, payments
- **Integration**: Custom Firebase tokens from backend, unified interfaces

### ✅ **Key Improvements**:

1. ✅ **Dependency Management**: Fixed Socket.io version conflicts
2. ✅ **Security**: Removed overly permissive Firestore rules
3. ✅ **Token Management**: Centralized authentication across all services
4. ✅ **Architecture Clarity**: Documented service responsibilities and boundaries

## 🚀 **Remaining Tasks**

### **Low Priority Improvements**:

1. **Dependency Management**: Establish consistent versioning for Swift packages
2. **Environment Configuration**: Create dev/staging/prod configuration system
3. **UI Enhancements**: Continue implementing car rental features
4. **Testing**: Add comprehensive tests for hybrid architecture
5. **Performance**: Monitor and optimize Firebase/API integration

### **Architecture Status**: ✅ **COMPLETE**

- Hybrid implementation successfully established
- Service boundaries clearly defined
- Security rules properly configured
- Token management unified across services
- Documentation created for future development

# 🔥 Firestore Database Schema

This document outlines all the collections and their attributes that need to be created in your Firestore database.

## 📊 Collections Overview

### 1. **searches** Collection

Stores all user search queries with full context and metadata.

```javascript
// Document ID: Auto-generated or custom search ID
{
  "id": "search_12345",                    // String - Unique search identifier
  "userId": "user_67890",                  // String - Reference to user who searched
  "searchText": "Times Square to Airport", // String - What user searched for
  "searchType": "general",                 // String - pickup|destination|general|nearby_vehicles
  "timestamp": "2024-01-15T10:30:00.000Z", // Timestamp - When search was performed
  "isConfirmed": true,                     // Boolean - Whether user selected a result
  
  // Location data (optional - when user selects specific locations)
  "fromLocation": {
    "placeId": "ChIJN1t_tDeuEmsRUsoyG83frY4",  // String - Google Places ID
    "name": "Times Square",                     // String - Location name
    "address": "Times Square, NYC, NY, USA",   // String - Full address
    "latitude": 40.7580,                       // Number - Latitude coordinate
    "longitude": -73.9855,                     // Number - Longitude coordinate
    "city": "New York",                        // String - City name
    "country": "USA",                          // String - Country name
    "postalCode": "10036"                      // String - Postal/ZIP code
  },
  
  "toLocation": {
    "placeId": "ChIJP3Sa8ziYEmsRUKgyFmh9AQM",
    "name": "JFK Airport",
    "address": "JFK Airport, Queens, NY, USA",
    "latitude": 40.6413,
    "longitude": -73.7781,
    "city": "Queens",
    "country": "USA",
    "postalCode": "11430"
  },
  
  // Search metadata for analytics
  "metadata": {
    "deviceInfo": "iPhone 15 Pro - iOS 17.2",  // String - Device information
    "appVersion": "1.0.0",                      // String - App version
    "searchDuration": 0.85,                     // Number - Time taken to search (seconds)
    "resultsCount": 8,                          // Number - Number of results returned
    "selectedResultIndex": 0                    // Number - Which result user selected (0-based)
  }
}
```

**Indexes needed:**

- `userId` + `timestamp` (descending)
- `isConfirmed` + `timestamp` (descending)
- `searchType` + `timestamp` (descending)

---

### 2. **user_searches** Collection

Tracks each user's search history and statistics.

```javascript
// Document ID: User ID
{
  "user_id": "user_67890",                    // String - User identifier
  "search_history": [                         // Array - List of search IDs (most recent first)
    "search_12345",
    "search_12344", 
    "search_12343"
  ],
  "last_search_at": "2024-01-15T10:30:00.000Z", // Timestamp - Last search time
  "total_searches": 47,                          // Number - Total number of searches
  "favorite_locations": [                        // Array - User's saved locations
    {
      "placeId": "ChIJN1t_tDeuEmsRUsoyG83frY4",
      "name": "Times Square",
      "address": "Times Square, NYC, NY, USA",
      "savedAt": "2024-01-10T15:20:00.000Z"
    }
  ],
  "search_preferences": {                        // Object - User search preferences
    "default_search_type": "general",           // String - Default search type
    "preferred_radius": 5000,                   // Number - Preferred search radius (meters)
    "auto_location": true                       // Boolean - Use current location automatically
  }
}
```

**Indexes needed:**

- `user_id` (single field)
- `last_search_at` (descending)

---

### 3. **search_analytics** Collection

Detailed analytics for search behavior and performance.

```javascript
// Document ID: Auto-generated
{
  "event": "prediction_selected",              // String - Event type
  "timestamp": "2024-01-15T10:30:00.000Z",    // Timestamp - When event occurred
  "search_id": "search_12345",                 // String - Related search ID
  "user_id": "user_67890",                     // String - User who triggered event
  
  "additional_data": {                         // Object - Event-specific data
    "prediction_index": 0,                     // Number - Which prediction was selected
    "search_type": "general",                  // String - Type of search
    "location_enabled": true,                  // Boolean - Was location access enabled
    "query_length": 15,                        // Number - Length of search query
    "results_shown": 8,                        // Number - How many results were shown
    "time_to_select": 3.2                      // Number - Time from search to selection (seconds)
  }
}
```

**Event types:**

- `search_started`
- `search_completed`
- `prediction_selected`
- `search_failed`
- `search_cleared`
- `location_selected`

**Indexes needed:**

- `event` + `timestamp` (descending)
- `user_id` + `timestamp` (descending)
- `search_id` + `timestamp` (descending)

---

### 4. **popular_searches** Collection

System-generated popular and trending searches.

```javascript
// Document ID: Auto-generated or search text hash
{
  "search_text": "Airport",                    // String - The popular search term
  "search_count": 1247,                        // Number - How many times searched
  "last_searched": "2024-01-15T10:30:00.000Z", // Timestamp - Most recent search
  "trend_score": 8.5,                          // Number - Trending score (0-10)
  "search_types": ["pickup", "destination"],   // Array - Common search types for this term
  
  "locations": [                               // Array - Popular locations for this search
    {
      "name": "JFK Airport",
      "count": 856,                            // Number - Times this location was selected
      "placeId": "ChIJP3Sa8ziYEmsRUKgyFmh9AQM"
    },
    {
      "name": "LaGuardia Airport", 
      "count": 391,
      "placeId": "ChIJ31dWgNBfwokRJYcTIiN7W5E"
    }
  ],
  
  "created_at": "2024-01-01T00:00:00.000Z",    // Timestamp - When record was created
  "updated_at": "2024-01-15T10:30:00.000Z"     // Timestamp - Last update
}
```

**Indexes needed:**

- `search_count` (descending)
- `trend_score` (descending)
- `updated_at` (descending)

---

### 5. **chats** Collection (Existing - for reference)

Chat rooms between users (car owners and renters).

```javascript
// Document ID: Auto-generated chat room ID
{
  "participants": ["user_123", "user_456"],    // Array - User IDs in chat
  "last_message": "Is the car still available?", // String - Most recent message
  "last_message_time": "2024-01-15T10:30:00.000Z", // Timestamp - Last message time
  "unread_count_user_123": 0,                   // Number - Unread count for user_123
  "unread_count_user_456": 2,                   // Number - Unread count for user_456
  "created_at": "2024-01-10T08:00:00.000Z",     // Timestamp - Chat creation time
  "rental_id": "rental_789",                    // String - Related rental (optional)
  "car_id": "car_101"                           // String - Related car (optional)
}
```

---

### 6. **messages** Collection (Existing - for reference)

Individual messages within chat rooms.

```javascript
// Document ID: Auto-generated message ID
{
  "text": "Is the car still available?",        // String - Message content
  "senderId": "user_123",                      // String - Who sent the message
  "senderName": "John Doe",                    // String - Sender's display name
  "chatId": "chat_room_789",                   // String - Which chat room
  "timestamp": "2024-01-15T10:30:00.000Z",    // Timestamp - When message was sent
  "isRead": false,                             // Boolean - Has been read by recipient
  "message_type": "text"                       // String - text|image|location|system
}
```

---

## 🔧 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own searches
    match /searches/{searchId} {
      allow read, write: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
    
    // Users can read/write their own search history
    match /user_searches/{userId} {
      allow read, write: if request.auth != null 
        && userId == request.auth.uid;
    }
    
    // Analytics - write only for authenticated users, read for admins only
    match /search_analytics/{analyticsId} {
      allow write: if request.auth != null;
      allow read: if request.auth != null 
        && request.auth.token.admin == true; // Custom claim for admins
    }
    
    // Popular searches - read only for all users
    match /popular_searches/{popularId} {
      allow read: if true;
      allow write: if false; // Server-generated only
    }
    
    // Existing chat rules
    match /chats/{chatId} {
      allow read, write: if request.auth != null 
        && request.auth.uid in resource.data.participants;
    }
    
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
      // Additional validation can be added here
    }
  }
}
```

---

## 📈 Required Firestore Indexes

Create these composite indexes in your Firestore console:

### searches Collection

```javascript
// For user search history
{
  "collectionGroup": "searches",
  "queryScope": "COLLECTION", 
  "fields": [
    {"fieldPath": "userId", "order": "ASCENDING"},
    {"fieldPath": "timestamp", "order": "DESCENDING"}
  ]
}

// For popular searches analysis
{
  "collectionGroup": "searches",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "isConfirmed", "order": "ASCENDING"}, 
    {"fieldPath": "timestamp", "order": "DESCENDING"}
  ]
}

// For search type filtering
{
  "collectionGroup": "searches",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "searchType", "order": "ASCENDING"},
    {"fieldPath": "timestamp", "order": "DESCENDING"}
  ]
}
```

### search_analytics Collection

```javascript
// For analytics queries
{
  "collectionGroup": "search_analytics",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "event", "order": "ASCENDING"},
    {"fieldPath": "timestamp", "order": "DESCENDING"}
  ]
}

// For user analytics
{
  "collectionGroup": "search_analytics", 
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "user_id", "order": "ASCENDING"},
    {"fieldPath": "timestamp", "order": "DESCENDING"}
  ]
}
```

---

## 🚀 Setup Instructions

1. **Create Collections**: Firestore collections are created automatically when you add the first document
2. **Set Security Rules**: Copy the rules above to your Firestore Rules tab
3. **Create Indexes**: Add the composite indexes in your Firestore Indexes tab
4. **Test Data**: Use the sample documents above to test your setup

---

## 📊 Data Flow Summary

```
User Search → SearchService → Firebase (searches + user_searches + search_analytics)
                ↓
Google Places API → PlacePredictions → User Selection → Confirmed Search
                ↓  
Route Calculation → Map Display → Ride Booking
```

This schema supports:

- ✅ Full search analytics and insights
- ✅ User personalization and history
- ✅ Popular searches and trends
- ✅ Performance monitoring
- ✅ Chat integration for bookings
- ✅ Scalable data structure

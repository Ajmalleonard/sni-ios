# Notification API Specification

This document outlines the API endpoints required for the notification system in the SNI Rentals application.

## Overview

The notification system consists of two main components:
1. **Firebase Realtime Database** - For real-time notification delivery and storage
2. **Backend REST API** - For managing notifications, retrieving history, and handling notification preferences

## Firebase Realtime Database Structure

### Collections

#### `notifications` Collection
- Document ID: Auto-generated
- Fields:
  - `userId`: String - ID of the user the notification is for
  - `title`: String - Notification title
  - `body`: String - Notification message body
  - `type`: String - Type of notification (CHAT, RENTAL, PAYMENT, SYSTEM, PROMOTION)
  - `relatedEntityId`: String (optional) - ID of related entity (chat, rental, etc.)
  - `isRead`: Boolean - Whether the notification has been read
  - `createdAt`: Timestamp - When the notification was created
  - `imageUrl`: String (optional) - URL to an image to display
  - `actionUrl`: String (optional) - Deep link URL for the notification

## REST API Endpoints

The following endpoints should be added to the existing SNI API:

### 1. Get User Notifications

**Endpoint:** `GET /notifications`

**Description:** Retrieves paginated notifications for the authenticated user

**Query Parameters:**
- `page`: Integer (default: 1) - Page number
- `limit`: Integer (default: 20) - Number of notifications per page
- `type`: String (optional) - Filter by notification type

**Headers:**
- `Authorization`: Bearer token

**Response:**
```json
{
  "notifications": [
    {
      "id": "string",
      "userId": "string",
      "title": "string",
      "body": "string",
      "type": "CHAT | RENTAL | PAYMENT | SYSTEM | PROMOTION",
      "relatedEntityId": "string (optional)",
      "isRead": boolean,
      "createdAt": "ISO date string",
      "imageUrl": "string (optional)",
      "actionUrl": "string (optional)"
    }
  ],
  "total": 45,
  "unreadCount": 3
}
```

### 2. Get Notification Count

**Endpoint:** `GET /notifications/unread-count`

**Description:** Gets the count of unread notifications for the authenticated user

**Headers:**
- `Authorization`: Bearer token

**Response:**
```json
{
  "unreadCount": 3
}
```

### 3. Mark Notifications as Read

**Endpoint:** `POST /notifications/read`

**Description:** Marks one or more notifications as read

**Headers:**
- `Authorization`: Bearer token
- `Content-Type`: application/json

**Request Body:**
```json
{
  "notificationIds": ["string", "string"]
}
```

**Response:**
```json
{
  "success": true,
  "updatedCount": 2
}
```

### 4. Mark All Notifications as Read

**Endpoint:** `POST /notifications/read-all`

**Description:** Marks all notifications as read for the authenticated user

**Headers:**
- `Authorization`: Bearer token

**Response:**
```json
{
  "success": true,
  "updatedCount": 5
}
```

### 5. Delete Notification

**Endpoint:** `DELETE /notifications/:id`

**Description:** Deletes a specific notification

**Headers:**
- `Authorization`: Bearer token

**Response:**
```json
{
  "success": true
}
```

### 6. Update Notification Preferences

**Endpoint:** `PUT /notifications/preferences`

**Description:** Updates notification preferences for the authenticated user

**Headers:**
- `Authorization`: Bearer token
- `Content-Type`: application/json

**Request Body:**
```json
{
  "preferences": {
    "CHAT": true,
    "RENTAL": true,
    "PAYMENT": true,
    "SYSTEM": true,
    "PROMOTION": false
  },
  "pushEnabled": true,
  "emailEnabled": false
}
```

**Response:**
```json
{
  "success": true,
  "preferences": {
    "CHAT": true,
    "RENTAL": true,
    "PAYMENT": true,
    "SYSTEM": true,
    "PROMOTION": false
  },
  "pushEnabled": true,
  "emailEnabled": false
}
```

### 7. Get Notification Preferences

**Endpoint:** `GET /notifications/preferences`

**Description:** Gets notification preferences for the authenticated user

**Headers:**
- `Authorization`: Bearer token

**Response:**
```json
{
  "preferences": {
    "CHAT": true,
    "RENTAL": true,
    "PAYMENT": true,
    "SYSTEM": true,
    "PROMOTION": false
  },
  "pushEnabled": true,
  "emailEnabled": false
}
```

## Integration with Firebase Cloud Messaging (FCM)

For push notifications, the backend should integrate with Firebase Cloud Messaging:

1. When creating a notification in the `notifications` collection, also send a push notification via FCM
2. Store FCM tokens in the user profile
3. Support both iOS and Android notification formats
4. Include deep links in the notification payload for direct navigation

## Implementation Guidelines

1. Use Firebase Firestore for real-time notification storage and retrieval
2. Implement server-side listeners for events that generate notifications
3. Create Firebase Cloud Functions to handle notification creation and delivery
4. Ensure proper security rules to prevent unauthorized access to notifications
5. Add indexes for efficient querying by userId, isRead, and createdAt
6. Implement proper error handling and rate limiting

## Client Integration

The iOS client should:

1. Listen for real-time updates to the notifications collection
2. Display badge counts for unread notifications
3. Support deep linking from notifications
4. Provide a unified notification center UI
5. Support both in-app and push notifications
6. Allow users to manage notification preferences 
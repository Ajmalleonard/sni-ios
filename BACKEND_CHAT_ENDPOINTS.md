# 🔧 Required Backend API Endpoints for Chat

## Overview
The iOS chat system now integrates with your backend APIs to handle user management while using Firebase for real-time messaging. This maintains OAuth integration and proper data consistency.

---

## 📋 **Required Endpoints**

### **1. Firebase Custom Token** 
**`POST /auth/firebase-token`**

**Purpose**: Generate custom Firebase tokens for authenticated users to access Firestore.

**Request Body**:
```json
{
  "userId": "22f9c61a-bf18-4d0f-b8e6-c2a19c61e3be",
  "email": "user@example.com",
  "name": "John Doe"
}
```

**Response**:
```json
{
  "customToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Implementation Notes**:
- Use Firebase Admin SDK to generate custom tokens
- Include user ID as the `uid` in the token
- Add custom claims if needed (role, permissions, etc.)

---

### **2. Chat Users List**
**`GET /users/chat-users`**

**Purpose**: Get all users available for chat (excluding current user).

**Headers**:
```
Authorization: Bearer <user-token>
Content-Type: application/json
```

**Response**:
```json
[
  {
    "id": "user-123",
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "profilePicture": "https://...",
    "isOnline": true,
    "lastSeen": "2025-01-08T10:30:00Z",
    "role": "client",
    "authProvider": "google"
  },
  {
    "id": "user-456",
    "name": "Bob Smith", 
    "email": "bob@example.com",
    "profilePicture": null,
    "isOnline": false,
    "lastSeen": "2025-01-08T09:15:00Z",
    "role": "client",
    "authProvider": "email"
  }
]
```

---

### **3. Update Online Status**
**`PATCH /users/:userId/online-status`**

**Purpose**: Update user's online status and last seen timestamp.

**Request Body**:
```json
{
  "isOnline": true,
  "lastSeen": "2025-01-08T10:30:00Z"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Online status updated"
}
```

---

### **4. Sync User to Firebase**
**`POST /users/sync-to-firebase`**

**Purpose**: Sync user data to Firebase for chat functionality.

**Request Body**:
```json
{
  "userId": "22f9c61a-bf18-4d0f-b8e6-c2a19c61e3be",
  "name": "John Doe",
  "email": "john@example.com", 
  "profilePicture": "https://...",
  "role": "client",
  "authProvider": "google"
}
```

**Response**:
```json
{
  "success": true,
  "message": "User synced to Firebase"
}
```

---

## 🛠️ **Implementation Guide**

### **Step 1: Install Firebase Admin SDK**
```bash
npm install firebase-admin
```

### **Step 2: Initialize Firebase Admin**
```typescript
import * as admin from 'firebase-admin';

// Initialize with service account
const serviceAccount = require('./path/to/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://your-project.firebaseio.com'
});
```

### **Step 3: Generate Custom Tokens**
```typescript
@Post('firebase-token')
async generateFirebaseToken(@Body() body: { userId: string, email: string, name: string }) {
  try {
    const customToken = await admin.auth().createCustomToken(body.userId, {
      email: body.email,
      name: body.name
    });
    
    return { customToken };
  } catch (error) {
    throw new BadRequestException('Failed to generate Firebase token');
  }
}
```

### **Step 4: Chat Users Endpoint**
```typescript
@Get('chat-users')
async getChatUsers(@Request() req) {
  const currentUserId = req.user.id;
  
  const users = await this.usersService.findAllExcept(currentUserId);
  
  return users.map(user => ({
    id: user.id,
    name: user.name,
    email: user.email,
    profilePicture: user.profilePicture,
    isOnline: user.isOnline || false,
    lastSeen: user.lastSeen,
    role: user.role,
    authProvider: user.authProvider
  }));
}
```

### **Step 5: Online Status Update**
```typescript
@Patch(':userId/online-status')
async updateOnlineStatus(
  @Param('userId') userId: string,
  @Body() body: { isOnline: boolean, lastSeen: string }
) {
  await this.usersService.update(userId, {
    isOnline: body.isOnline,
    lastSeen: new Date(body.lastSeen)
  });
  
  return { success: true, message: 'Online status updated' };
}
```

---

## 🔐 **Security Considerations**

### **Authentication**:
- All endpoints require valid user authentication
- Use your existing JWT/session validation
- Validate user permissions for accessing chat features

### **Firebase Security**:
- Custom tokens should be short-lived (1 hour max)
- Include minimal necessary claims
- Validate user identity before token generation

### **Data Privacy**:
- Only expose necessary user data for chat
- Respect user privacy settings
- Filter sensitive information

---

## 🧪 **Testing**

### **Test Firebase Token Generation**:
```bash
curl -X POST https://api.snicolt.com/auth/firebase-token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-token>" \
  -d '{
    "userId": "test-user-123",
    "email": "test@example.com", 
    "name": "Test User"
  }'
```

### **Test Chat Users List**:
```bash
curl -X GET https://api.snicolt.com/users/chat-users \
  -H "Authorization: Bearer <your-token>"
```

---

## 📊 **Database Schema Updates**

Add these fields to your Users table if not present:

```sql
ALTER TABLE users ADD COLUMN is_online BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

---

## 🎯 **Integration Flow**

1. **User Signs In** → Your existing OAuth flow
2. **Chat Access** → iOS requests Firebase token from backend
3. **Firebase Auth** → iOS authenticates with Firebase using custom token
4. **User List** → iOS fetches chat users from backend API
5. **Real-time Chat** → Firebase Firestore handles message sync
6. **Status Updates** → iOS updates online status via backend API

This approach maintains your existing user management while enabling real-time chat functionality! 
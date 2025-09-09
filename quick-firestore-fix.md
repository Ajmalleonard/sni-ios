# 🔥 Quick Firestore Rules Fix

## The Problem

You're still getting these errors:

- `Listen for query at user_searches/22f9c61a-bf18-4d0f-b8e6-c2a19c61e3be failed: Missing or insufficient permissions`
- `Listen for query at searches failed: Missing or insufficient permissions`

## Quick Solution (2 minutes)

### Step 1: Go to Firebase Console

1. Open: <https://console.firebase.google.com/>
2. Select project: **org-transpota-app**
3. Go to: **Firestore Database** → **Rules** tab

### Step 2: Replace Rules

Copy and paste this entire rule set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own searches
    match /searches/{searchId} {
      allow read, write: if request.auth != null && 
                        (resource == null || resource.data.userId == request.auth.uid);
    }
    
    // Allow authenticated users to read/write their search history
    match /user_searches/{userId} {
      allow read, write: if request.auth != null && userId == request.auth.uid;
    }
    
    // Allow authenticated users to read popular searches
    match /popular_searches/{searchId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Allow authenticated users to write analytics
    match /search_analytics/{analyticsId} {
      allow read, write: if request.auth != null;
    }
    
    // Notifications - users can only access their own notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
                         (resource == null || resource.data.userId == request.auth.uid);
    }
    
    // Chat collections
    match /chats/{chatId} {
      allow read, write: if request.auth != null;
    }
    
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // Cars collection - read access for all authenticated users
    match /cars/{carId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Users collection - users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && userId == request.auth.uid;
    }
    
    // Rentals - users can access their own rentals
    match /rentals/{rentalId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Step 3: Publish

Click the **"Publish"** button

### Step 4: Test

- Build and run your app
- Try searching - should work without permission errors

---

## ✅ Expected Result

After this fix, these errors should disappear:

- ❌ `Missing or insufficient permissions` for searches
- ❌ `Missing or insufficient permissions` for user_searches
- ❌ `Missing or insufficient permissions` for notifications

The search functionality should work properly! 🎉

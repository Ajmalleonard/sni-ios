# Fix Firebase Dependencies

## Steps to resolve Firebase dependency issues

### 1. Open Xcode

- Open the `SNI Rentals.xcodeproj` file in Xcode
- Wait for Xcode to finish indexing

### 2. Clean Build Folder

- In Xcode, go to `Product` → `Clean Build Folder` (Cmd+Shift+K)
- Or go to `Product` → `Clean Build Folder and Index` (Cmd+Shift+Alt+K)

### 3. Reset Package Caches

- In Xcode, go to `File` → `Packages` → `Reset Package Caches`
- Wait for the process to complete

### 4. Resolve Package Dependencies

- In Xcode, go to `File` → `Packages` → `Resolve Package Versions`
- Wait for all packages to be resolved

### 5. Build the Project

- Press `Cmd+B` to build the project
- If there are still errors, try building again after a few seconds

### 6. If Issues Persist

- Close Xcode completely
- Delete the derived data (already done via terminal)
- Reopen the project in Xcode
- Let it re-index and resolve packages

### 7. Alternative: Manual Package Resolution

If automatic resolution doesn't work:

- In Xcode, go to the project navigator
- Click on the project file (SNI Rentals)
- Go to the "Package Dependencies" tab
- Remove the Firebase package
- Click the "+" button to add it back
- Search for "firebase-ios-sdk"
- Add it back with version 11.15.0 or later

### 8. Check Firebase Configuration

Make sure your `GoogleService-Info.plist` file is:

- Added to the project
- Included in the target
- Has the correct bundle identifier

### 9. Verify Imports

Make sure your Swift files import the correct Firebase modules:

```swift
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase
import FirebaseStorage
import FirebaseMessaging
```

## Common Issues and Solutions

1. **"Missing package product" errors**: Usually resolved by cleaning and resetting package caches
2. **"Unable to find module" errors**: Often fixed by rebuilding the project
3. **Version conflicts**: Make sure all Firebase packages are from the same version

## If All Else Fails

- Create a new Xcode project
- Add Firebase packages manually
- Copy your source files to the new project
- This ensures a clean package resolution

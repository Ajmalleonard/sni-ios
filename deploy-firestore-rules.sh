#!/bin/bash

echo "🔥 Deploying Firestore Rules and Indexes..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Login to Firebase (if not already logged in)
echo "🔑 Checking Firebase authentication..."
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "🔑 Please login to Firebase..."
    firebase login
fi

# Initialize Firebase project (if not already initialized)
if [ ! -f "firebase.json" ]; then
    echo "🚀 Initializing Firebase project..."
    firebase init firestore --project org-transpota-app
fi

# Deploy Firestore rules
echo "📋 Deploying Firestore security rules..."
firebase deploy --only firestore:rules --project org-transpota-app

# Deploy Firestore indexes
echo "📊 Deploying Firestore indexes..."
firebase deploy --only firestore:indexes --project org-transpota-app

echo "✅ Firestore deployment completed!"
echo ""
echo "🔍 Next steps:"
echo "1. Check Firebase Console → Firestore → Rules"
echo "2. Check Firebase Console → Firestore → Indexes"
echo "3. Test your app - search functionality should work now!" 
#!/bin/bash

echo "🔥 Deploying Firestore Rules Only..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "   npm install -g firebase-tools"
    echo "   or"
    echo "   curl -sL https://firebase.tools | bash"
    exit 1
fi

# Deploy only Firestore rules (skip indexes since you already created them)
echo "📋 Deploying Firestore security rules to org-transpota-app..."
firebase deploy --only firestore:rules --project transpota

if [ $? -eq 0 ]; then
    echo "✅ Firestore rules deployed successfully!"
    echo ""
    echo "🔍 Next steps:"
    echo "1. Test your app - search functionality should work now!"
    echo "2. Check Firebase Console → Firestore → Rules to verify"
else
    echo "❌ Failed to deploy rules. Please check your Firebase authentication."
    echo "   Try: firebase login"
fi 
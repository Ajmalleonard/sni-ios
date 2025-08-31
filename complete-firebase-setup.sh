#!/bin/bash

echo "🔥 Complete Firebase Setup for SNI Rentals"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
echo -e "${BLUE}Checking Firebase CLI...${NC}"
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Firebase CLI. Please run manually:${NC}"
        echo "npm install -g firebase-tools"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Firebase CLI is ready${NC}"

# Login to Firebase
echo -e "${BLUE}Checking Firebase authentication...${NC}"
firebase projects:list > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Please login to Firebase...${NC}"
    firebase login
fi

# Check if project exists
echo -e "${BLUE}Checking project access...${NC}"
firebase projects:list | grep -q "transpota"
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Cannot access project 'transpota'${NC}"
    echo "Please ensure you have access to this project in Firebase Console"
    exit 1
fi

echo -e "${GREEN}✅ Project access confirmed${NC}"

# Create firebase.json if it doesn't exist
if [ ! -f "firebase.json" ]; then
    echo -e "${BLUE}Creating firebase.json...${NC}"
    cat > firebase.json << EOF
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
EOF
fi

# Create temporary permissive rules for immediate fix
echo -e "${BLUE}Creating temporary permissive Firestore rules...${NC}"
cat > firestore.rules << EOF
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // TEMPORARY: Allow all authenticated users full access
    // This fixes immediate permission issues
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
EOF

# Deploy rules and indexes
echo -e "${BLUE}Deploying Firestore rules and indexes...${NC}"
firebase deploy --only firestore --project transpota

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Firestore rules and indexes deployed successfully!${NC}"
    echo ""
    echo -e "${GREEN}🎉 SUCCESS! Your app should now work without permission errors.${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Build and run your app"
    echo "2. Try the search functionality"
    echo "3. All Firestore operations should work now"
    echo ""
    echo -e "${BLUE}Note: These are permissive rules for development.${NC}"
    echo "For production, you may want to implement more restrictive rules."
else
    echo -e "${RED}❌ Failed to deploy rules${NC}"
    echo "Please try the manual method in URGENT-FIRESTORE-FIX.md"
    exit 1
fi

echo ""
echo -e "${GREEN}🔥 Firebase setup complete!${NC}" 
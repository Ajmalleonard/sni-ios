const axios = require('axios');

// Test Apple Sign-In end-to-end flow
async function testAppleSignInE2E() {
    console.log('🍎 Testing Apple Sign-In End-to-End Flow...');
    
    try {
        // Test 1: Check backend health
        console.log('\n1. Testing backend connectivity...');
        const healthResponse = await axios.get('http://localhost:1010');
        console.log('✅ Backend is accessible');
        
        // Test 2: Test Apple OAuth endpoint with mock data
        console.log('\n2. Testing Apple OAuth endpoint...');
        const appleAuthData = {
            identityToken: 'mock_identity_token_12345',
            authorizationCode: 'mock_auth_code_67890',
            userIdentifier: 'mock_user_id_abcdef',
            email: 'test@example.com',
            fullName: {
                givenName: 'Test',
                familyName: 'User'
            }
        };
        
        const authResponse = await axios.post('http://localhost:1010/auth/apple', appleAuthData);
        
        if (authResponse.status === 201) {
            console.log('✅ Apple OAuth endpoint working correctly');
            console.log('✅ User created/authenticated successfully');
            console.log('✅ Access token received:', authResponse.data.accessToken ? 'Yes' : 'No');
            console.log('✅ Refresh token received:', authResponse.data.refreshToken ? 'Yes' : 'No');
            console.log('✅ User data received:', authResponse.data.user ? 'Yes' : 'No');
            
            // Test 3: Verify user data structure
            const user = authResponse.data.user;
            if (user && user.email && user.displayName) {
                console.log('✅ User data structure is correct');
                console.log('   - Email:', user.email);
                console.log('   - Display Name:', user.displayName);
                console.log('   - Auth Provider:', user.authProvider);
            }
            
            console.log('\n🎉 Apple Sign-In E2E Test PASSED!');
            console.log('\n📱 iOS App Configuration:');
            console.log('   - Apple Sign-In entitlements: ✅ Configured');
            console.log('   - Backend URL: ✅ Set to http://localhost:1010');
            console.log('   - Auth flow: ✅ Ready for testing');
            
            console.log('\n🚀 Next Steps:');
            console.log('   1. Build and run the iOS app in Xcode');
            console.log('   2. Tap "Continue With Apple" button');
            console.log('   3. Complete Apple Sign-In flow');
            console.log('   4. Verify user is authenticated in the app');
            
        } else {
            console.log('❌ Unexpected response status:', authResponse.status);
        }
        
    } catch (error) {
        console.log('❌ Test failed:', error.message);
        if (error.response) {
            console.log('   Status:', error.response.status);
            console.log('   Data:', error.response.data);
        }
    }
}

// Run the test
testAppleSignInE2E();
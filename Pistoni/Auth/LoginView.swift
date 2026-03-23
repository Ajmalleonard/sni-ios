import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @State var email : String = ""
    @State var password : String = ""
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    @State private var nonce: String?
    @AppStorage("log_Status") private var logStatus: Bool = false

//    ErrosState
    @State private var isError: Bool = false
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [ Color.white, Color(red: 0.92, green: 0.96, blue: 1.0)]), startPoint: .top, endPoint: .bottom).frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
        
        ScrollView {
            
             
                VStack(spacing: 32) {
              
                    VStack( ) {
                        VStack(spacing: 20) {
                            Spacer(minLength: 30)

                            VStack(spacing: 0) {
                                Image("newa")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200)
                                    .clipped()
                            }

                        }
                        .frame(maxWidth: .infinity)
                  
                        VStack(spacing: 16) {
                            // Optimized TextField
                            HStack {
                                Image(systemName: "envelope")
                                TextField("Your Email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }.padding()
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color("Accent"), lineWidth: 1)
                                )
                                .foregroundColor(Color("AppSecondary"))
                            
                            
                            HStack {
                                Image(systemName: "lock")
                                SecureField("Secure Code ***", text: $password)
                            }.padding()
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color("Accent"), lineWidth: 1)
                                )
                                .foregroundColor(Color("AppSecondary"))
                        }
                        
                        .padding(.horizontal, 32)
                        
                       
                        
                        Button("Forgot Password?") {
                            // TODO: Handle forgot password
                        }
                        .foregroundColor(Color("Accent"))
                        .padding(.horizontal, 32)
                        
                        Button(action: login) {
                            Text("Sign in")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AppSecondary"))
                                .foregroundColor(Color("AppPrimary"))
                                .clipShape(Capsule())
                        }
                        .disabled(authModel.isLoading)
                        .padding(.horizontal, 32)
                        // Registration prompt
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(Color("AppSecondary").opacity(0.7))
                            NavigationLink("Sign Up", destination: RegisterView().environmentObject(authModel).navigationBarHidden(true))
                                .fontWeight(.semibold)
                                .foregroundColor(Color("Accent"))
                        }
                        .font(.footnote)
                        .padding(.horizontal, 32)
                    }.padding(.vertical,50)
                       
                    
                    
                    // Or Divider
                    HStack {
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(height: 1)
                        Text("or")
                            .padding(.horizontal, 16)
                            .foregroundColor(Color("AppSecondary"))
                        Rectangle()
                            .fill(Color("Accent"))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    
                    HStack(spacing: 12) {
                        SignInWithAppleButton(.signIn) { request in
                            let nonce = randomNonceString()
                            self.nonce = nonce
                            request.requestedScopes = [.email, .fullName]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                loginWithApple(authorization)
                            case .failure(let error):
                                authModel.messageState = MessageState.error(error.localizedDescription)
                            }
                        }
                        .frame(width: 55, height: 55)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .fill(Color.black)
                                .allowsHitTesting(false)
                        )
                        .overlay(
                            Image(systemName: "applelogo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .allowsHitTesting(false)
                        )
                        .disabled(authModel.isLoading)
                        
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack {
                                Image("google")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width:25, height: 25)
                                    .foregroundColor(Color("AppSecondary"))
                                
                            }
                          
                            .padding()
                            .background(Color("Accent").opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundColor(Color("AppSecondary"))
                        }
                        .disabled(authModel.isLoading)
                    }
                    .padding(.horizontal, 32)
                    
                   
                    
         
                }.padding()
                
                
            }.ignoresSafeArea()
        }
        .navigationBarHidden(true)
        .loadingOverlay(isLoading: authModel.isLoading)
        
        .ignoresSafeArea()
        .onChange(of: authModel.errorMessage) { _, newValue in
            isError = newValue != nil
        }
        .onChange(of: authModel.successMessage) { _, newValue in
            if newValue != nil {
                isError = true
                logStatus = true
            }
        }
        .sheet(isPresented: $isError) {
            MessageSheetView(
                errorMessage: authModel.errorMessage,
                successMessage: authModel.successMessage,
                onDismiss: { isError = false }
            )
            .padding(.horizontal, 32)
            .presentationDetents([.height(UIScreen.main.bounds.height * 0.4)])
            .presentationDragIndicator(.visible)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white)
        }
      
          
    }
    
    private func login() {
        authModel.login(email: email, password: password)
        // Observe successMessage to update logStatus
        if authModel.successMessage != nil {
            logStatus = true
        }
    }
    
    private func signInWithGoogle() {
        authModel.signInWithGoogle()
        // Observe successMessage to update logStatus
        if authModel.successMessage != nil {
            logStatus = true
        }
    }
    

    private func loginWithApple(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authModel.messageState = MessageState.error("Apple Sign-In credential is not available.")
            return
        }
        
        guard self.nonce != nil else {
            authModel.messageState = MessageState.error("Nonce is missing.")
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            authModel.messageState = MessageState.error("Unable to get ID token from Apple credential.")
            return
        }
        
        guard let authorizationCode = appleIDCredential.authorizationCode,
              let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
            authModel.messageState = MessageState.error("Unable to get authorization code from Apple credential.")
            return
        }
        
        let userIdentifier = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        let appleOAuthDto = AppleOAuthDto(
            identityToken: idTokenString,
            authorizationCode: authCodeString,
            email: email,
            fullName: PersonNameComponentsDto(
                givenName: fullName?.givenName,
                familyName: fullName?.familyName
            ),
            userIdentifier: userIdentifier
        )
        
        authModel.signInWithApple(appleOAuthDto: appleOAuthDto) { result in
            switch result {
            case .success:
                logStatus = true
                dismiss()
            case .failure(let error):
                authModel.messageState = MessageState.error(error.localizedDescription)
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthModel())
}

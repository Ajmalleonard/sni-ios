//
//  ProfileView.swift
//  SNI Rentals
//
//  Created by Jesus on 1/22/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditProfile = false
    @State private var showingChangePassword = false
    @State private var showingDeleteAccount = false
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing:0, ){
                        HStack(alignment:.center,spacing: 16) {
                        // Profile Picture
                        AsyncImage(url: URL(string: authModel.currentUser?.profilePicture ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                    .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    Text(authModel.currentUser?.displayName.prefix(1).uppercased() ?? "U")
                                        .font(.title)
                                        .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                )
                        }
                            .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                            // Name and Email Section
                            VStack( spacing: 1) {
                                VStack(alignment: .leading) {
                            Text(authModel.currentUser?.displayName ?? "User")
                                .font(.title2)
                                .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(authModel.currentUser?.email ?? "useremail@sni.com")
                                }
                            }
                            Spacer()
                            
                            
                        
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color("Primary"))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .padding(.horizontal, 20)
                
                // MARK : Badge zone
                    
                 
                    
                    // Main Content
                    VStack(spacing: 15) {
                        // Main Menu Items
                        Badge()
                        VStack(spacing: 0) {
                            ProfileMainMenuItem(
                                icon: "person.circle",
                                title: "Personal info",
                                subtitle: "User details and profile information",
                                destination: PersonalInfoView()
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMainMenuItem(
                                icon: "shield.checkered",
                                title: "Safety",
                                subtitle: "Trusted contacts, family, emergency info",
                                destination: SafetyView()
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMainMenuItem(
                                icon: "key.horizontal",
                                title: "Login & Security",
                                subtitle: "Password, two-factor authentication",
                                destination: LoginSecurityView()
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMainMenuItem(
                                icon: "eye.slash",
                                title: "Privacy",
                                subtitle: "Data privacy and location settings",
                                destination: PrivacyView()
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMainMenuItem(
                                icon: "globe",
                                title: "Language",
                                subtitle: "App language preferences",
                                destination: LanguageView()
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMainMenuItem(
                                icon: "calendar",
                                title: "Calendars",
                                subtitle: "Sync external calendars",
                                destination: CalendarsView()
                            )
                        }
                        .background(Color("Primary"))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        
                        // Account Actions Section
                        VStack(spacing: 0) {
                            Button {
                                print("🚪 Logout button tapped!")
                                authModel.logout()
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Log out")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 25)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 60)
                            
                        Button {
                                print("🗑️ Delete account button tapped!")
                                showingDeleteAccount = true
                        } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "trash")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Delete account")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 25)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color("Primary"))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .padding(.top, 25)
                    .padding(.horizontal, 25)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .onAppear {
                print("👤 ProfileView appeared!")
            }
            .onDisappear {
                print("👤 ProfileView disappeared!")
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet(
                    name: $name,
                    phoneNumber: $phoneNumber,
                    isLoading: authModel.isLoading,
                    errorMessage: authModel.errorMessage,
                    successMessage: authModel.successMessage,
                    onSave: {
                        authModel.updateProfile(name: name, phoneNumber: phoneNumber)
                    },
                    onCancel: {
                        showingEditProfile = false
                    }
                )
                .onAppear {
                    name = authModel.currentUser?.name ?? ""
                    phoneNumber = authModel.currentUser?.phoneNumber ?? ""
                }
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordSheet(
                    currentPassword: $currentPassword,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    isLoading: authModel.isLoading,
                    errorMessage: authModel.errorMessage,
                    successMessage: authModel.successMessage,
                    onSave: {
                        if newPassword == confirmPassword {
                            authModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                        }
                    },
                    onCancel: {
                        showingChangePassword = false
                        currentPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                    }
                )
            }
            .alert("Delete Account", isPresented: $showingDeleteAccount) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Handle account deletion
                }
            } message: {
                Text("Are you sure you want to permanently delete your account? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Profile Section Container
struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 25)
            }
            
            VStack(spacing: 0) {
                content
            }
            .background(Color("Primary"))
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
}

// MARK: - Profile Menu Item
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    var textColor: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color("Secondary"))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
            Text(title)
                        .font(.body)
                .fontWeight(.medium)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.leading)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
            Spacer()
                
                if textColor == .primary {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @Binding var name: String
    @Binding var phoneNumber: String
    let isLoading: Bool
    let errorMessage: String?
    let successMessage: String?
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Edit Profile")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 25)
                
                VStack(spacing: 16) {
                    FastTextField(
                        text: $name,
                        placeholder: "Full Name",
                        autocapitalization: .words
                    )
                    
                    FastTextField(
                        text: $phoneNumber,
                        placeholder: "Phone Number",
                        keyboardType: .phonePad
                    )
                }
                .padding(.horizontal, 25)
                
                // Messages
                VStack(spacing: 8) {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    if let successMessage = successMessage {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, 25)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        onSave()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(isLoading || name.isEmpty)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 25)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Change Password Sheet
struct ChangePasswordSheet: View {
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    let isLoading: Bool
    let errorMessage: String?
    let successMessage: String?
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Change Password")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 25)
                
                VStack(spacing: 16) {
                    FastTextField(
                        text: $currentPassword,
                        placeholder: "Current Password",
                        isSecure: true
                    )
                    
                    FastTextField(
                        text: $newPassword,
                        placeholder: "New Password",
                        isSecure: true
                    )
                    
                    FastTextField(
                        text: $confirmPassword,
                        placeholder: "Confirm New Password",
                        isSecure: true
                    )
                }
                .padding(.horizontal, 25)
                
                // Password validation
                if !newPassword.isEmpty && !confirmPassword.isEmpty {
                    HStack {
                        Image(systemName: newPassword == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(newPassword == confirmPassword ? .green : .red)
                        Text(newPassword == confirmPassword ? "Passwords match" : "Passwords don't match")
                            .font(.caption)
                            .foregroundColor(newPassword == confirmPassword ? .green : .red)
                    }
                    .padding(.horizontal, 25)
                }
                
                // Messages
                VStack(spacing: 8) {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    if let successMessage = successMessage {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, 25)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        onSave()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Change Password")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 25)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Profile Main Menu Item (with Navigation)
struct ProfileMainMenuItem<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color("Secondary"))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Detail Views

struct PersonalInfoView: View {
    @EnvironmentObject var authModel: AuthModel
    @State private var showingEditProfile = false
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(spacing: 0) {
                    ProfileMenuItem(
                        icon: "person.circle",
                        title: "User details",
                        subtitle: "Update your personal information",
                        action: { showingEditProfile = true }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "phone.circle",
                        title: "Contact information",
                        subtitle: "Phone number and email",
                        action: { /* Handle contact info */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "doc.text.circle",
                        title: "Personal documents",
                        subtitle: "ID, license, and other documents",
                        action: { /* Handle documents */ }
                    )
                }
                .background(Color("Primary"))
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .padding(15)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Personal info")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingEditProfile) {
            EditProfileSheet(
                name: $name,
                phoneNumber: $phoneNumber,
                isLoading: authModel.isLoading,
                errorMessage: authModel.errorMessage,
                successMessage: authModel.successMessage,
                onSave: {
                    authModel.updateProfile(name: name, phoneNumber: phoneNumber)
                },
                onCancel: {
                    showingEditProfile = false
                }
            )
            .onAppear {
                name = authModel.currentUser?.name ?? ""
                phoneNumber = authModel.currentUser?.phoneNumber ?? ""
            }
        }
    }
}

struct SafetyView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(spacing: 0) {
                    ProfileMenuItem(
                        icon: "person.2.circle",
                        title: "Trusted Contacts",
                        subtitle: "Add emergency contacts",
                        action: { /* Handle trusted contacts */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "house.circle",
                        title: "Family Members",
                        subtitle: "Manage family access",
                        action: { /* Handle family members */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "location.circle",
                        title: "Home city location",
                        subtitle: "Set emergency location",
                        action: { /* Handle home location */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "exclamationmark.triangle.fill",
                        title: "Emergency settings",
                        subtitle: "Configure emergency protocols",
                        action: { /* Handle emergency settings */ }
                    )
                }
                .background(Color("Primary"))
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .padding(15)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Safety")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct LoginSecurityView: View {
    @EnvironmentObject var authModel: AuthModel
    @State private var showingChangePassword = false
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(spacing: 0) {
                    ProfileMenuItem(
                        icon: "key.horizontal",
                        title: "Password",
                        subtitle: "Change your password",
                        action: { showingChangePassword = true }
                    )
                    
                    if authModel.currentUser?.authProvider == .email || authModel.currentUser?.authProvider == nil {
                        Divider()
                            .padding(.leading, 60)
                        
                        ProfileMenuItem(
                            icon: "shield.checkered",
                            title: "Two-factor authentication",
                            subtitle: "Add extra security",
                            action: { /* Handle 2FA */ }
                        )
                    }
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "iphone.and.arrow.forward",
                        title: "Trusted devices",
                        subtitle: "Manage your trusted devices",
                        action: { /* Handle trusted devices */ }
                    )
            }
            .background(Color("Primary"))
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .padding(15)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Login & Security")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordSheet(
                currentPassword: $currentPassword,
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isLoading: authModel.isLoading,
                errorMessage: authModel.errorMessage,
                successMessage: authModel.successMessage,
                onSave: {
                    if newPassword == confirmPassword {
                        authModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                    }
                },
                onCancel: {
                    showingChangePassword = false
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }
            )
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(spacing: 0) {
                    ProfileMenuItem(
                        icon: "eye.slash",
                        title: "Data privacy",
                        subtitle: "Control your data sharing",
                        action: { /* Handle privacy */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "location.slash",
                        title: "Location services",
                        subtitle: "Manage location access",
                        action: { /* Handle location privacy */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "bell.slash",
                        title: "Notification settings",
                        subtitle: "Control push notifications",
                        action: { /* Handle notifications */ }
                    )
                }
                .background(Color("Primary"))
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .padding(15)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct LanguageView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(spacing: 0) {
                    ProfileMenuItem(
                        icon: "globe",
                        title: "App language",
                        subtitle: "English",
                        action: { /* Handle language */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "textformat",
                        title: "Text size",
                        subtitle: "Adjust font size",
                        action: { /* Handle text size */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "accessibility",
                        title: "Accessibility",
                        subtitle: "Voice and display options",
                        action: { /* Handle accessibility */ }
                    )
                }
                .background(Color("Primary"))
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .padding(15)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CalendarsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 0) {
                    ProfileMenuItem(
                        icon: "calendar",
                        title: "Sync calendars",
                        subtitle: "Connect external calendars",
                        action: { /* Handle calendars */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "calendar.badge.plus",
                        title: "Add calendar",
                        subtitle: "Google, Outlook, or iCloud",
                        action: { /* Handle add calendar */ }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    ProfileMenuItem(
                        icon: "bell.badge",
                        title: "Event reminders",
                        subtitle: "Notification preferences",
                        action: { /* Handle reminders */ }
                    )
                }
                .background(Color("Primary"))
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .padding(15)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Calendars")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthModel())
} 

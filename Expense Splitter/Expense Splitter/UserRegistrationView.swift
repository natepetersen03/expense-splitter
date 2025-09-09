//
//  UserRegistrationView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI

struct UserRegistrationView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var username = ""
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isCreatingProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Create Your Profile")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Set up your account to start splitting expenses with friends")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.headline)
                            TextField("Choose a username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            if !username.isEmpty && !userService.isValidUsername(username) {
                                Text("Username must be 3-20 characters, letters, numbers, and underscores only")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Full Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.headline)
                            TextField("Enter your full name", text: $fullName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Phone Number Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                            TextField("+1 (555) 123-4567", text: $phoneNumber)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                            
                            if !phoneNumber.isEmpty && !userService.isValidPhoneNumber(phoneNumber) {
                                Text("Please enter a valid phone number")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Email Field (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email (Optional)")
                                .font(.headline)
                            TextField("your.email@example.com", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            if !email.isEmpty && !userService.isValidEmail(email) {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Create Profile Button
                    Button(action: createProfile) {
                        HStack {
                            if isCreatingProfile {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isCreatingProfile ? "Creating Profile..." : "Create Profile")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isCreatingProfile)
                    .padding(.horizontal)
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By creating an account, you agree to our")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Button("Terms of Service") {
                                // TODO: Show terms
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Text("and")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Privacy Policy") {
                                // TODO: Show privacy policy
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        return !username.isEmpty &&
               !fullName.isEmpty &&
               !phoneNumber.isEmpty &&
               userService.isValidUsername(username) &&
               userService.isValidPhoneNumber(phoneNumber) &&
               (email.isEmpty || userService.isValidEmail(email))
    }
    
    private func createProfile() {
        isCreatingProfile = true
        
        let emailValue = email.isEmpty ? nil : email
        
        let success = userService.createUserProfile(
            username: username,
            name: fullName,
            phoneNumber: phoneNumber,
            email: emailValue,
            context: viewContext
        )
        
        isCreatingProfile = false
        
        if success {
            // Profile created successfully
            // The app will automatically navigate to the main view
        } else {
            alertMessage = "Username already exists. Please choose a different username."
            showingAlert = true
        }
    }
}

#Preview {
    UserRegistrationView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

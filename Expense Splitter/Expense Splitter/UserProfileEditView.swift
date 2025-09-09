//
//  UserProfileEditView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI

struct UserProfileEditView: View {
    @StateObject private var userService = UserService.shared
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Edit Profile")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding(.top)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.headline)
                            TextField("Username", text: $username)
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
                            TextField("Full Name", text: $fullName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Phone Number Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                            TextField("Phone Number", text: $phoneNumber)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)
                            
                            if !phoneNumber.isEmpty && !userService.isValidPhoneNumber(phoneNumber) {
                                Text("Please enter a valid phone number")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                            TextField("Email", text: $email)
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
                    
                    // Save Button
                    Button(action: saveProfile) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isSaving ? "Saving..." : "Save Changes")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isSaving)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
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
    
    private func loadCurrentProfile() {
        // Try Firebase user first, then fall back to Core Data user
        if let firebaseUser = firebaseService.currentUser {
            username = firebaseUser.username
            fullName = firebaseUser.name
            phoneNumber = firebaseUser.phoneNumber ?? ""
            email = firebaseUser.email ?? ""
        } else if let user = userService.currentUser {
            username = user.username ?? ""
            fullName = user.name ?? ""
            phoneNumber = user.phoneNumber ?? ""
            email = user.email ?? ""
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        let emailValue = email.isEmpty ? nil : email
        
        // If using Firebase, update Firebase user profile
        if firebaseService.currentUser != nil {
            Task {
                do {
                    // Update Firebase user profile
                    try await firebaseService.updateUserProfile(
                        username: username,
                        name: fullName,
                        phoneNumber: phoneNumber,
                        email: emailValue
                    )
                    
                    await MainActor.run {
                        isSaving = false
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        isSaving = false
                        alertMessage = "Failed to update profile: \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
        } else {
            // Fall back to Core Data
            let success = userService.updateUserProfile(
                username: username,
                name: fullName,
                phoneNumber: phoneNumber,
                email: emailValue,
                context: viewContext
            )
            
            isSaving = false
            
            if success {
                dismiss()
            } else {
                alertMessage = "Username already exists. Please choose a different username."
                showingAlert = true
            }
        }
    }
}

#Preview {
    UserProfileEditView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

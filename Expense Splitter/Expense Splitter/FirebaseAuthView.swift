//
//  FirebaseAuthView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import FirebaseAuth

struct FirebaseAuthView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var loginIdentifier = "" // For email or username login
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Expense Splitter")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Auth Form
                VStack(spacing: 16) {
                    if isSignUp {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username *")
                                .font(.headline)
                            
                            TextField("Choose a username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name *")
                                .font(.headline)
                            
                            TextField("Enter your full name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Phone Number Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                            
                            TextField("Enter your phone number", text: $phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                    }
                    
                    // Email/Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isSignUp ? "Email *" : "Email or Username *")
                            .font(.headline)
                        
                        TextField(isSignUp ? "Enter your email" : "Enter your email or username", text: isSignUp ? $email : $loginIdentifier)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(isSignUp ? .emailAddress : .default)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password *")
                            .font(.headline)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.oneTimeCode)
                        
                        if isSignUp {
                            Text("Password must be at least 8 characters long")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isSignUp {
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password *")
                                .font(.headline)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.oneTimeCode)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Auth Button
                Button(action: isSignUp ? signUp : signIn) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal, 20)
                
                // Toggle Auth Mode
                Button(action: { 
                    isSignUp.toggle()
                    clearForm()
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   !confirmPassword.isEmpty &&
                   !username.isEmpty &&
                   !name.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 8 &&
                   isValidEmail(email)
        } else {
            return !loginIdentifier.isEmpty && !password.isEmpty
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func clearForm() {
        email = ""
        password = ""
        username = ""
        name = ""
        phoneNumber = ""
        confirmPassword = ""
        loginIdentifier = ""
    }
    
    private func signIn() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                try await firebaseService.signInWithIdentifier(loginIdentifier, password: password)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Sign in error: \(error)")
                    alertMessage = "Sign in failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func signUp() {
        guard isFormValid else {
            if password.count < 8 {
                alertMessage = "Password must be at least 8 characters long"
            } else if password != confirmPassword {
                alertMessage = "Passwords do not match"
            } else if !isValidEmail(email) {
                alertMessage = "Please enter a valid email address"
            } else {
                alertMessage = "Please fill in all required fields"
            }
            showingAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await firebaseService.signUp(
                    email: email,
                    password: password,
                    username: username,
                    name: name,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                )
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Sign up error: \(error)")
                    print("Error type: \(type(of: error))")
                    print("Error code: \((error as NSError).code)")
                    print("Error domain: \((error as NSError).domain)")
                    print("Error userInfo: \((error as NSError).userInfo)")
                    alertMessage = "Sign up failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    FirebaseAuthView()
}

//
//  LoginView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var userService: UserService
    @State private var username = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Title
                VStack(spacing: 8) {
                    Text("Expense Splitter")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Split expenses with friends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                        
                        TextField("Enter your username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                            .autocorrectionDisabled()
                    }
                    
                    Button("Sign In") {
                        signIn()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(username.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    
                    Button("Sign Up") {
                        showingSignUp = true
                    }
                    .foregroundColor(.blue)
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .alert("Login Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func signIn() {
        guard !username.isEmpty && !password.isEmpty else {
            alertMessage = "Please enter both username and password"
            showingAlert = true
            return
        }
        
        if userService.signIn(username: username, password: password) {
            // Success - userService will handle setting currentUser
        } else {
            alertMessage = "Invalid username or password"
            showingAlert = true
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserService.shared)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

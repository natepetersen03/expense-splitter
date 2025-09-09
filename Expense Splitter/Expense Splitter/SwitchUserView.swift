//
//  SwitchUserView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import CoreData

struct SwitchUserView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var allUsers: [Person] = []
    @State private var isSearching = false
    
    var filteredUsers: [Person] {
        if searchText.isEmpty {
            return allUsers
        } else {
            return allUsers.filter { user in
                user.name?.localizedCaseInsensitiveContains(searchText) == true ||
                user.username?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                
                if allUsers.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Users Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("No other users have been created yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Users List
                    List(filteredUsers, id: \.id) { user in
                        UserRowView(user: user) {
                            switchToUser(user)
                        }
                    }
                }
            }
            .navigationTitle("Switch User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAllUsers()
            }
        }
    }
    
    private func loadAllUsers() {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Person.name, ascending: true)]
        
        do {
            allUsers = try viewContext.fetch(request)
            print("📋 Loaded \(allUsers.count) users for switching")
        } catch {
            print("Error loading users: \(error)")
        }
    }
    
    private func switchToUser(_ user: Person) {
        // Sign out current user
        userService.signOut()
        
        // Sign in as the selected user
        let success = userService.signIn(username: user.username ?? "", password: user.password ?? "")
        
        if success {
            print("✅ Successfully switched to user: \(user.name ?? "Unknown")")
            dismiss()
        } else {
            print("❌ Failed to switch to user: \(user.name ?? "Unknown")")
        }
    }
}

struct UserRowView: View {
    let user: Person
    let onSwitch: () -> Void
    
    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.name?.prefix(1) ?? "?").uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name ?? "Unknown")
                    .font(.headline)
                
                if let username = user.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let phoneNumber = user.phoneNumber {
                    Text(phoneNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Switch Button
            Button("Switch") {
                onSwitch()
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SwitchUserView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

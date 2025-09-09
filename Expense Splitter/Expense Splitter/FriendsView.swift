//
//  FriendsView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import CoreData

struct FriendsView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddFriend = false
    @State private var searchText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var filteredFriends: [Person] {
        if searchText.isEmpty {
            return userService.friends
        } else {
            return userService.friends.filter { friend in
                friend.name?.localizedCaseInsensitiveContains(searchText) == true ||
                friend.username?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                if userService.friends.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Friends Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add friends to start splitting expenses together")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Your First Friend") {
                            showingAddFriend = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Friends List
                    List {
                        ForEach(filteredFriends, id: \.id) { friend in
                            FriendRowView(friend: friend)
                        }
                        .onDelete(perform: deleteFriends)
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddFriend = true
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func deleteFriends(at offsets: IndexSet) {
        for index in offsets {
            let friend = filteredFriends[index]
            userService.removeFriend(friend)
        }
    }
}

struct FriendRowView: View {
    let friend: Person
    
    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(friend.name?.prefix(1) ?? "?").uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            // Friend Info
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name ?? "Unknown")
                    .font(.headline)
                
                if let username = friend.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let phoneNumber = friend.phoneNumber {
                    Text(phoneNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddFriendView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [Person] = []
    @State private var isSearching = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Instructions
                VStack(spacing: 8) {
                    Text("Add a Friend")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Search by username or phone number")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Search Bar
                HStack {
                    TextField("Username or phone number", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            searchForUser()
                        }
                    
                    Button("Search") {
                        searchForUser()
                    }
                    .disabled(searchText.isEmpty || isSearching)
                }
                .padding(.horizontal)
                
                // Search Results
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !searchResults.isEmpty {
                    List(searchResults, id: \.id) { user in
                        SearchResultRowView(user: user) {
                            addFriend(user)
                        }
                    }
                } else if !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No users found")
                            .font(.headline)
                        
                        Text("Make sure the username or phone number is correct")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func searchForUser() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchResults = []
        
        // Search by username first
        if let user = userService.findUser(by: searchText, context: viewContext) {
            searchResults = [user]
        } else {
            // Search by phone number
            if let user = userService.findUserByPhone(searchText, context: viewContext) {
                searchResults = [user]
            }
        }
        
        isSearching = false
    }
    
    private func addFriend(_ user: Person) {
        guard let currentUser = userService.currentUser else { 
            alertMessage = "Please sign in to add friends"
            showingAlert = true
            return 
        }
        
        // Don't add yourself as a friend
        if user.id == currentUser.id {
            alertMessage = "You can't add yourself as a friend"
            showingAlert = true
            return
        }
        
        // Check if already friends
        if userService.friends.contains(where: { $0.id == user.id }) {
            alertMessage = "This user is already your friend"
            showingAlert = true
            return
        }
        
        // Check if there's already a pending request
        let hasPendingRequest = userService.pendingFriendRequests.contains { request in
            (request.sender?.id == currentUser.id && request.receiver?.id == user.id) ||
            (request.sender?.id == user.id && request.receiver?.id == currentUser.id)
        }
        
        if hasPendingRequest {
            alertMessage = "You already have a pending friend request with this user"
            showingAlert = true
            return
        }
        
        // Send friend request
        let success = userService.sendFriendRequest(to: user, context: viewContext)
        if success {
            alertMessage = "Friend request sent successfully!"
            showingAlert = true
        } else {
            alertMessage = "Failed to send friend request. Please try again."
            showingAlert = true
        }
    }
}

struct SearchResultRowView: View {
    let user: Person
    let onAddFriend: () -> Void
    
    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color.green)
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
            
            // Add Button
            Button("Add") {
                onAddFriend()
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search friends...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    FriendsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

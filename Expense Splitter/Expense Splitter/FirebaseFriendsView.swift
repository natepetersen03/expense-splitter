//
//  FirebaseFriendsView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import FirebaseFirestore

struct FirebaseFriendsView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [FirebaseUser] = []
    @State private var isSearching = false
    @State private var showingAlert = false
    @State private var alertTitle = "Error"
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                FirebaseSearchBar(text: $searchText, onSearchButtonClicked: searchUsers)
                    .padding(.horizontal)
                
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Users Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Try searching with a different username")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Search for Friends")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Enter a username to find and add friends")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults) { user in
                        FirebaseSearchResultRowView(user: user)
                    }
                }
            }
            .navigationTitle("Add Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        
        // Use a more flexible search - get all users and filter client-side
        // This is better for small user bases and allows for partial matches
        print("🔍 Starting Firestore query for all users...")
        Firestore.firestore().collection("users")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isSearching = false
                    
                    if let error = error {
                        print("❌ Firestore query error: \(error)")
                        alertTitle = "Error"
                        alertMessage = "Failed to search users: \(error.localizedDescription)"
                        showingAlert = true
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("❌ No documents found in snapshot")
                        searchResults = []
                        return
                    }
                    
                    print("📄 Firestore returned \(documents.count) documents")
                    
                    do {
                        let allUsers = documents.compactMap { doc in
                            let data = doc.data()
                            
                            // Debug: Print what's actually in the document
                            print("Document ID: \(doc.documentID)")
                            print("Document data: \(data)")
                            
                            var user = FirebaseUser(
                                username: data["username"] as? String ?? "",
                                name: data["name"] as? String ?? "",
                                email: data["email"] as? String,
                                phoneNumber: data["phoneNumber"] as? String
                            )
                            user.id = doc.documentID
                            return user
                        }
                        
                        print("Found \(allUsers.count) total users in database")
                        print("Current user ID: \(firebaseService.currentUser?.id ?? "nil")")
                        print("Current user username: \(firebaseService.currentUser?.username ?? "nil")")
                        print("Searching for: '\(searchText)'")
                        
                        // Filter by search text and exclude current user
                        searchResults = allUsers.filter { user in
                            let matchesSearch = user.username.lowercased().contains(searchText.lowercased())
                            let isNotCurrentUser = user.id != firebaseService.currentUser?.id
                            let shouldInclude = matchesSearch && isNotCurrentUser
                            
                            print("User \(user.username) (ID: \(user.id ?? "nil")) - matchesSearch: \(matchesSearch), isNotCurrentUser: \(isNotCurrentUser), shouldInclude: \(shouldInclude)")
                            return shouldInclude
                        }
                        
                        print("Final filtered results: \(searchResults.count) users")
                    } catch {
                        alertTitle = "Error"
                        alertMessage = "Failed to parse user data: \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
    }
}

struct FirebaseSearchResultRowView: View {
    let user: FirebaseUser
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var isSendingRequest = false
    @State private var showingAlert = false
    @State private var alertTitle = "Error"
    @State private var alertMessage = ""
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSendingRequest {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button("Add Friend") {
                    sendFriendRequest()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSendingRequest)
            }
        }
        .padding(.vertical, 4)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func sendFriendRequest() {
        guard let currentUser = firebaseService.currentUser else {
            alertTitle = "Error"
            alertMessage = "Please sign in to add friends"
            showingAlert = true
            return
        }
        
        // Don't add yourself as a friend
        if user.id == currentUser.id {
            alertTitle = "Error"
            alertMessage = "You can't add yourself as a friend"
            showingAlert = true
            return
        }
        
        // Check if already friends
        if firebaseService.friends.contains(where: { $0.id == user.id }) {
            alertTitle = "Error"
            alertMessage = "This user is already your friend"
            showingAlert = true
            return
        }
        
        isSendingRequest = true
        
        Task {
            do {
                try await firebaseService.sendFriendRequest(to: user.username)
                await MainActor.run {
                    isSendingRequest = false
                    alertTitle = "Success"
                    alertMessage = "Friend request sent to \(user.name)"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isSendingRequest = false
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct FirebaseSearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search by username", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("Search", action: onSearchButtonClicked)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    FirebaseFriendsView()
}

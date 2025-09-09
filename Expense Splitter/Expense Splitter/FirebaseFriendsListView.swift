//
//  FirebaseFriendsListView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI

struct FirebaseFriendsListView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingAddFriend = false
    
    var filteredFriends: [FirebaseUser] {
        if searchText.isEmpty {
            return firebaseService.friends
        } else {
            return firebaseService.friends.filter { friend in
                friend.name.localizedCaseInsensitiveContains(searchText) ||
                friend.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                FirebaseSearchBar(text: $searchText, onSearchButtonClicked: {})
                    .padding(.horizontal)
                
                if firebaseService.friends.isEmpty {
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
                            FirebaseFriendRowView(friend: friend)
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Friend") {
                        showingAddFriend = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            FirebaseFriendsView()
        }
    }
}

struct FirebaseFriendRowView: View {
    let friend: FirebaseUser
    
    var body: some View {
        HStack {
            // Profile Picture Placeholder
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.name.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("@\(friend.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    FirebaseFriendsListView()
}

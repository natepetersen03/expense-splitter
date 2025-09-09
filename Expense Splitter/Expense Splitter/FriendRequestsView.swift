//
//  FriendRequestsView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import CoreData

struct FriendRequestsView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if userService.pendingFriendRequests.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Friend Requests")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("You don't have any pending friend requests")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Friend Requests List
                    List {
                        ForEach(userService.pendingFriendRequests, id: \.id) { request in
                            FriendRequestRowView(request: request)
                        }
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        userService.refreshFriendRequests(context: viewContext)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FriendRequestRowView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    let request: FriendRequest
    
    var body: some View {
        HStack {
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(request.sender?.name ?? "Unknown User")
                    .font(.headline)
                
                if let username = request.sender?.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("wants to be your friend")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Decline") {
                    userService.respondToFriendRequest(request, accept: false, context: viewContext)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Button("Accept") {
                    userService.respondToFriendRequest(request, accept: true, context: viewContext)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    FriendRequestsView()
        .environmentObject(UserService.shared)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

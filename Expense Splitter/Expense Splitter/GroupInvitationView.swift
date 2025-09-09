//
//  GroupInvitationView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import CoreData

struct GroupInvitationView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingInviteFriends = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if userService.pendingInvitations.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Invitations")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("You don't have any pending group invitations")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Invitations List
                    List(userService.pendingInvitations, id: \.id) { invitation in
                        InvitationRowView(invitation: invitation)
                    }
                }
            }
            .navigationTitle("Invitations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
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
}

struct InvitationRowView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    let invitation: GroupInvitation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.group?.name ?? "Unknown Group")
                        .font(.headline)
                    
                    Text("Invited by \(invitation.inviter?.name ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(invitation.created ?? Date(), style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Group Info
            if let group = invitation.group {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                    
                    Text("\(group.members?.count ?? 0) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Decline") {
                    respondToInvitation(accept: false)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Button("Accept") {
                    respondToInvitation(accept: true)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func respondToInvitation(accept: Bool) {
        userService.respondToInvitation(invitation, accept: accept, context: viewContext)
    }
}

struct InviteFriendsToGroupView: View {
    @StateObject private var userService = UserService.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let group: Group
    
    @State private var selectedFriends: Set<Person> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSendingInvitations = false
    
    var availableFriends: [Person] {
        // Filter out friends who are already in the group or already invited
        return userService.friends.filter { friend in
            // Not already in the group (check many-to-many relationship)
            let isNotInGroup = !(friend.groups?.contains(group) ?? false)
            
            // Not already invited
            let isNotInvited = !hasPendingInvitation(for: friend)
            
            return isNotInGroup && isNotInvited
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if availableFriends.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Friends to Invite")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("All your friends are already in this group or have pending invitations")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    // Friends List
                    List(availableFriends, id: \.id) { friend in
                        FriendSelectionRowView(
                            friend: friend,
                            isSelected: selectedFriends.contains(friend)
                        ) {
                            toggleFriendSelection(friend)
                        }
                    }
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendInvitations()
                    }
                    .disabled(selectedFriends.isEmpty || isSendingInvitations)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func toggleFriendSelection(_ friend: Person) {
        if selectedFriends.contains(friend) {
            selectedFriends.remove(friend)
        } else {
            selectedFriends.insert(friend)
        }
    }
    
    private func hasPendingInvitation(for friend: Person) -> Bool {
        guard let invitations = group.invitations?.allObjects as? [GroupInvitation] else {
            return false
        }
        
        return invitations.contains { invitation in
            invitation.invitee?.id == friend.id && invitation.status == "pending"
        }
    }
    
    private func sendInvitations() {
        isSendingInvitations = true
        
        var successCount = 0
        var failureCount = 0
        
        for friend in selectedFriends {
            let success = userService.sendGroupInvitation(to: friend, group: group, context: viewContext)
            if success {
                successCount += 1
            } else {
                failureCount += 1
            }
        }
        
        isSendingInvitations = false
        
        if failureCount > 0 {
            alertMessage = "Sent \(successCount) invitations. \(failureCount) failed to send."
            showingAlert = true
        } else {
            dismiss()
        }
    }
}

struct FriendSelectionRowView: View {
    let friend: Person
    let isSelected: Bool
    let onToggle: () -> Void
    
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
            }
            
            Spacer()
            
            // Selection Indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title2)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GroupInvitationView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

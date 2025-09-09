//
//  GroupListView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import CoreData

struct GroupListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var userService: UserService
    @EnvironmentObject private var firebaseService: FirebaseService
    // Use Firebase groups instead of Core Data groups
    private var groups: [FirebaseGroup] {
        return firebaseService.groups
    }
    
    @State private var showingAddGroup = false
    @State private var showingProfileEdit = false
    @State private var showingFriends = false
    @State private var showingInvitations = false
    @State private var showingFriendRequests = false
    @State private var showingSwitchUser = false
    @State private var newGroupName = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(groups) { group in
                    NavigationLink(destination: FirebaseGroupDetailView(group: group)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(group.name)
                                        .font(.headline)
                                    
                                    if isGroupCreator(group) {
                                        Text("CREATOR")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Text("\(group.memberIds.count) members")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .onDelete(perform: deleteGroups)
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showingProfileEdit = true }) {
                            Label("Edit Profile", systemImage: "person.circle")
                        }
                        
                        Button(action: { showingFriends = true }) {
                            Label("Friends", systemImage: "person.2")
                        }
                        
                        Button(action: { showingInvitations = true }) {
                            Label("Invitations", systemImage: "envelope")
                            if !userService.pendingInvitations.isEmpty {
                                Text("(\(userService.pendingInvitations.count))")
                            }
                        }
                        
                        Button(action: { 
                            showingFriendRequests = true 
                        }) {
                            Label("Friend Requests", systemImage: "person.badge.plus")
                            if !firebaseService.pendingFriendRequests.isEmpty {
                                Text("(\(firebaseService.pendingFriendRequests.count))")
                            }
                        }
                        
                        Divider()
                        
                        Button(action: { showingSwitchUser = true }) {
                            Label("Switch User (Test)", systemImage: "person.2.circle")
                        }
                        
                        Button(action: { 
                            do {
                                try firebaseService.signOut()
                            } catch {
                                print("Error signing out: \(error)")
                            }
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        newGroupName = ""
                        showingAddGroup = true 
                    }) { 
                        Label("Add Group", systemImage: "plus") 
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGroup) {
            AddGroupSheet(newGroupName: $newGroupName)
        }
        .sheet(isPresented: $showingProfileEdit) {
            UserProfileEditView()
        }
        .sheet(isPresented: $showingFriends) {
            FirebaseFriendsListView()
        }
        .sheet(isPresented: $showingInvitations) {
            GroupInvitationView()
        }
        .sheet(isPresented: $showingFriendRequests) {
            FirebaseFriendRequestsView()
        }
        .sheet(isPresented: $showingSwitchUser) {
            SwitchUserView()
        }
    }

    private func addGroup() {
        let newGroup = Group(context: viewContext)
        newGroup.id = UUID()
        newGroup.name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        newGroup.created = Date()
        try? viewContext.save()
    }

    private func isGroupCreator(_ group: FirebaseGroup) -> Bool {
        return group.creatorId == firebaseService.currentUser?.id
    }
    
    private func deleteGroups(at offsets: IndexSet) {
        let groupsToDelete = offsets.map { groups[$0] }
        
        Task {
            for group in groupsToDelete {
                guard let groupId = group.id else { continue }
                do {
                    try await firebaseService.deleteGroup(groupId: groupId)
                } catch {
                    print("Error deleting group: \(error)")
                }
            }
        }
    }
    
}

struct AddGroupSheet: View {
    @Binding var newGroupName: String
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userService: UserService
    @EnvironmentObject private var firebaseService: FirebaseService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Group Name", text: $newGroupName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createGroup() {
        let groupName = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await firebaseService.createGroup(name: groupName)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("Error creating group: \(error)")
                }
            }
        }
    }
}

struct GroupListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupListView()
            .environment(\.managedObjectContext,
                         PersistenceController.shared.container.viewContext)
            .environmentObject(UserService.shared)
    }
}


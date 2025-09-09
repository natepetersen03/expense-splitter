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
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Group.name, ascending: true)],
        animation: .default)
    private var allGroups: FetchedResults<Group>
    
    private var groups: [Group] {
        guard let currentUser = userService.currentUser else { return [] }
        return allGroups.filter { group in
            group.members?.contains(currentUser) == true
        }
    }
    
    @State private var showingAddGroup = false
    @State private var showingProfileEdit = false
    @State private var showingFriends = false
    @State private var showingInvitations = false
    @State private var newGroupName = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(group.name ?? "Unnamed")
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
                                
                                Text("\(group.members?.count ?? 0) members")
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
            FriendsView()
        }
        .sheet(isPresented: $showingInvitations) {
            GroupInvitationView()
        }
    }

    private func addGroup() {
        let newGroup = Group(context: viewContext)
        newGroup.id = UUID()
        newGroup.name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        newGroup.created = Date()
        try? viewContext.save()
    }

    private func isGroupCreator(_ group: Group) -> Bool {
        return group.creator?.id == userService.currentUser?.id
    }
    
    private func deleteGroups(at offsets: IndexSet) {
        offsets.map { groups[$0] }.forEach(viewContext.delete)
        try? viewContext.save()
    }
}

struct AddGroupSheet: View {
    @Binding var newGroupName: String
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userService: UserService
    
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
        let newGroup = Group(context: viewContext)
        newGroup.id = UUID()
        newGroup.name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        newGroup.created = Date()
        
        // Set the current user as the creator and add them to the group
        if let currentUser = userService.currentUser {
            newGroup.creator = currentUser
            currentUser.addToGroups(newGroup)
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error creating group: \(error)")
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


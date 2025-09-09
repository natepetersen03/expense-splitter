//
//  GroupDetailView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import CoreData

struct GroupDetailView: View {
    @ObservedObject var group: Group
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userService: UserService
    
    @State private var showingEditGroup = false
    @State private var showingInviteFriends = false
    @State private var editedGroupName = ""
    @State private var showingLeaveGroupAlert = false
    @State private var showingDeleteGroupAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Group Info Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name ?? "Unnamed Group")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("\(group.members?.count ?? 0) members")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            editedGroupName = group.name ?? ""
                            showingEditGroup = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let created = group.created {
                        Text("Created \(created, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Members Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Members")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Invite Friends") {
                            showingInviteFriends = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let members = group.members?.allObjects as? [Person], !members.isEmpty {
                        ForEach(members, id: \.id) { member in
                            HStack {
                                Circle()
                                    .fill(isCurrentUser(member) ? Color.green : Color.blue)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(member.name?.prefix(1) ?? "?").uppercased())
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name ?? "Unknown")
                                        .font(.body)
                                    
                                    if isCurrentUser(member) {
                                        Text("You")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .fontWeight(.medium)
                                    }
                                }
                                
                                Spacer()
                                
                                if !isCurrentUser(member) {
                                    Button("Remove") {
                                        removeMember(member)
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("No members yet")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding()
                
                Divider()
                
                // Expenses Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Expenses")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Add Expense") {
                            // TODO: Navigate to expense creation
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let expenses = group.expenses?.array as? [Expense], !expenses.isEmpty {
                        ForEach(expenses.prefix(5), id: \.id) { expense in
                            ExpenseRowView(expense: expense)
                        }
                        
                        if expenses.count > 5 {
                            Button("View All Expenses") {
                                // TODO: Navigate to full expense list
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    } else {
                        Text("No expenses yet")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Group Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        if isGroupCreator() {
                            Button("Delete Group", role: .destructive) {
                                showingDeleteGroupAlert = true
                            }
                        } else {
                            Button("Leave Group", role: .destructive) {
                                showingLeaveGroupAlert = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditGroup) {
            EditGroupSheet(group: group, editedGroupName: $editedGroupName)
        }
        .sheet(isPresented: $showingInviteFriends) {
            InviteFriendsToGroupView(group: group)
        }
        .alert("Leave Group", isPresented: $showingLeaveGroupAlert) {
            Button("Leave", role: .destructive) {
                leaveGroup()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to leave this group? You will no longer have access to its expenses.")
        }
        .alert("Delete Group", isPresented: $showingDeleteGroupAlert) {
            Button("Delete", role: .destructive) {
                deleteGroup()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this group? This action cannot be undone and will remove all expenses and members.")
        }
    }
    
    private func isCurrentUser(_ member: Person) -> Bool {
        return member.id == userService.currentUser?.id
    }
    
    private func isGroupCreator() -> Bool {
        return group.creator?.id == userService.currentUser?.id
    }
    
    private func removeMember(_ member: Person) {
        group.removeFromMembers(member)
        viewContext.delete(member)
        
        do {
            try viewContext.save()
        } catch {
            print("Error removing member: \(error)")
        }
    }
    
    private func leaveGroup() {
        guard let currentUser = userService.currentUser else { return }
        
        // Remove current user from the group
        currentUser.removeFromGroups(group)
        
        do {
            try viewContext.save()
            dismiss() // Go back to group list
        } catch {
            print("Error leaving group: \(error)")
        }
    }
    
    private func deleteGroup() {
        // Delete the entire group (this will cascade delete expenses, invitations, etc.)
        viewContext.delete(group)
        
        do {
            try viewContext.save()
            dismiss() // Go back to group list
        } catch {
            print("Error deleting group: \(error)")
        }
    }
}

struct ExpenseRowView: View {
    @ObservedObject var expense: Expense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.note ?? "No description")
                    .font(.body)
                
                if let date = expense.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(totalAmount, specifier: "%.2f")")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Paid by \(expense.payer?.name ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var totalAmount: Double {
        let itemsTotal = (expense.items?.allObjects as? [LineItem])?.reduce(0) { $0 + ($1.amount?.doubleValue ?? 0) } ?? 0
        let tip = expense.tip?.doubleValue ?? 0
        let tax = expense.tax?.doubleValue ?? 0
        return itemsTotal + tip + tax
    }
}


struct EditGroupSheet: View {
    @ObservedObject var group: Group
    @Binding var editedGroupName: String
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Group Name", text: $editedGroupName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGroupName()
                    }
                    .disabled(editedGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveGroupName() {
        group.name = editedGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving group name: \(error)")
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let group = Group(context: context)
    group.id = UUID()
    group.name = "Sample Group"
    group.created = Date()
    
    return GroupDetailView(group: group)
        .environment(\.managedObjectContext, context)
        .environmentObject(UserService.shared)
}

//
//  UserService.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import CoreData
import Foundation

class UserService: ObservableObject {
    static let shared = UserService()
    
    @Published var currentUser: Person?
    @Published var friends: [Person] = []
    @Published var pendingInvitations: [GroupInvitation] = []
    
    private let userDefaults = UserDefaults.standard
    private let currentUserIdKey = "currentUserId"
    private var managedObjectContext: NSManagedObjectContext?
    
    private init() {
        // Don't load data during init - wait for context to be available
    }
    
    // MARK: - Initialization
    
    func initialize(context: NSManagedObjectContext) {
        self.managedObjectContext = context
        loadCurrentUser(context: context)
        loadFriends(context: context)
        loadPendingInvitations(context: context)
    }
    
    // MARK: - Authentication
    
    func signIn(username: String, password: String) -> Bool {
        guard let context = getContext() else { return false }
        
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)
        
        do {
            let users = try context.fetch(request)
            if let user = users.first, user.password == password {
                // Set as current user
                user.isCurrentUser = true
                currentUser = user
                
                // Save user ID to UserDefaults
                userDefaults.set(user.id?.uuidString, forKey: currentUserIdKey)
                
                try context.save()
                return true
            }
        } catch {
            print("Error signing in: \(error)")
        }
        
        return false
    }
    
    func createAccount(username: String, name: String, email: String?, phoneNumber: String?, password: String) -> Bool {
        guard let context = getContext() else { return false }
        
        // Check if username already exists
        if userExists(username: username, context: context) {
            return false
        }
        
        let newUser = Person(context: context)
        newUser.id = UUID()
        newUser.username = username
        newUser.name = name
        newUser.email = email
        newUser.phoneNumber = phoneNumber
        newUser.password = password
        newUser.isCurrentUser = true
        
        currentUser = newUser
        
        // Save user ID to UserDefaults
        userDefaults.set(newUser.id?.uuidString, forKey: currentUserIdKey)
        
        do {
            try context.save()
            return true
        } catch {
            print("Error creating account: \(error)")
            return false
        }
    }
    
    func signOut() {
        // Clear current user
        currentUser?.isCurrentUser = false
        currentUser = nil
        
        // Clear stored user ID
        userDefaults.removeObject(forKey: currentUserIdKey)
        
        // Save changes
        if let context = getContext() {
            do {
                try context.save()
            } catch {
                print("Error signing out: \(error)")
            }
        }
    }
    
    // MARK: - User Profile Management
    
    func createUserProfile(username: String, name: String, phoneNumber: String, email: String?, context: NSManagedObjectContext) -> Bool {
        // Check if username already exists
        if userExists(username: username, context: context) {
            return false
        }
        
        let newUser = Person(context: context)
        newUser.id = UUID()
        newUser.username = username
        newUser.name = name
        newUser.phoneNumber = phoneNumber
        newUser.email = email
        newUser.isCurrentUser = true
        
        currentUser = newUser
        
        // Save user ID to UserDefaults
        userDefaults.set(newUser.id?.uuidString, forKey: currentUserIdKey)
        
        do {
            try context.save()
            return true
        } catch {
            print("Error creating user profile: \(error)")
            return false
        }
    }
    
    func updateUserProfile(username: String?, name: String?, phoneNumber: String?, email: String?, context: NSManagedObjectContext) -> Bool {
        guard let user = currentUser else { return false }
        
        // Check if new username conflicts with existing users
        if let newUsername = username, newUsername != user.username {
            if userExists(username: newUsername, context: context) {
                return false
            }
        }
        
        if let username = username { user.username = username }
        if let name = name { user.name = name }
        if let phoneNumber = phoneNumber { user.phoneNumber = phoneNumber }
        if let email = email { user.email = email }
        
        do {
            try context.save()
            return true
        } catch {
            print("Error updating user profile: \(error)")
            return false
        }
    }
    
    func loadCurrentUser(context: NSManagedObjectContext) {
        guard let userIdString = userDefaults.string(forKey: currentUserIdKey),
              let userId = UUID(uuidString: userIdString) else {
            return
        }
        
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        
        do {
            let users = try context.fetch(request)
            if let user = users.first {
                currentUser = user
            } else {
                userDefaults.removeObject(forKey: currentUserIdKey)
            }
        } catch {
            print("Error loading current user: \(error)")
        }
    }
    
    // MARK: - User Search and Validation
    
    func findUser(by username: String, context: NSManagedObjectContext) -> Person? {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("Error finding user: \(error)")
            return nil
        }
    }
    
    func findUserByPhone(_ phoneNumber: String, context: NSManagedObjectContext) -> Person? {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.predicate = NSPredicate(format: "phoneNumber == %@", phoneNumber)
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("Error finding user by phone: \(error)")
            return nil
        }
    }
    
    private func userExists(username: String, context: NSManagedObjectContext) -> Bool {
        return findUser(by: username, context: context) != nil
    }
    
    // MARK: - Friends Management
    
    func addFriend(_ person: Person, context: NSManagedObjectContext) {
        // For now, we'll implement a simple friends system
        // In a real app, this would involve server-side friend requests
        if !friends.contains(where: { $0.id == person.id }) {
            friends.append(person)
            saveFriends()
        }
    }
    
    func removeFriend(_ person: Person) {
        friends.removeAll { $0.id == person.id }
        saveFriends()
    }
    
    private func loadFriends(context: NSManagedObjectContext) {
        // Load friends from UserDefaults (in real app, this would be from server)
        if let data = userDefaults.data(forKey: "friends"),
           let friendIds = try? JSONDecoder().decode([String].self, from: data) {
            
            for friendIdString in friendIds {
                if let friendId = UUID(uuidString: friendIdString) {
                    let request: NSFetchRequest<Person> = Person.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", friendId as CVarArg)
                    
                    do {
                        let users = try context.fetch(request)
                        if let friend = users.first {
                            friends.append(friend)
                        }
                    } catch {
                        print("Error loading friend: \(error)")
                    }
                }
            }
        }
    }
    
    private func saveFriends() {
        let friendIds = friends.compactMap { $0.id?.uuidString }
        if let data = try? JSONEncoder().encode(friendIds) {
            userDefaults.set(data, forKey: "friends")
        }
    }
    
    // MARK: - Group Invitations
    
    func sendGroupInvitation(to person: Person, group: Group, context: NSManagedObjectContext) -> Bool {
        guard let currentUser = currentUser else { return false }
        
        // Check if invitation already exists
        let existingInvitation = findExistingInvitation(inviter: currentUser, invitee: person, group: group, context: context)
        if existingInvitation != nil {
            return false // Invitation already exists
        }
        
        let invitation = GroupInvitation(context: context)
        invitation.id = UUID()
        invitation.created = Date()
        invitation.status = "pending"
        invitation.inviter = currentUser
        invitation.invitee = person
        invitation.group = group
        
        do {
            try context.save()
            return true
        } catch {
            print("Error sending invitation: \(error)")
            return false
        }
    }
    
    func respondToInvitation(_ invitation: GroupInvitation, accept: Bool, context: NSManagedObjectContext) {
        if accept {
            // Add user to group (many-to-many relationship)
            if let invitee = invitation.invitee, let group = invitation.group {
                invitee.addToGroups(group)
            }
            invitation.status = "accepted"
        } else {
            invitation.status = "declined"
        }
        
        do {
            try context.save()
            loadPendingInvitations(context: context)
        } catch {
            print("Error responding to invitation: \(error)")
        }
    }
    
    private func findExistingInvitation(inviter: Person, invitee: Person, group: Group, context: NSManagedObjectContext) -> GroupInvitation? {
        let request: NSFetchRequest<GroupInvitation> = GroupInvitation.fetchRequest()
        request.predicate = NSPredicate(format: "inviter == %@ AND invitee == %@ AND group == %@ AND status == 'pending'", inviter, invitee, group)
        
        do {
            let invitations = try context.fetch(request)
            return invitations.first
        } catch {
            print("Error finding existing invitation: \(error)")
            return nil
        }
    }
    
    private func loadPendingInvitations(context: NSManagedObjectContext) {
        guard let currentUser = currentUser else { return }
        
        let request: NSFetchRequest<GroupInvitation> = GroupInvitation.fetchRequest()
        request.predicate = NSPredicate(format: "invitee == %@ AND status == 'pending'", currentUser)
        
        do {
            pendingInvitations = try context.fetch(request)
        } catch {
            print("Error loading pending invitations: \(error)")
        }
    }
    
    // MARK: - Validation Helpers
    
    func isValidUsername(_ username: String) -> Bool {
        return username.count >= 3 && username.count <= 20 && username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
    
    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^\\+?[1-9]\\d{1,14}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phoneNumber)
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func getContext() -> NSManagedObjectContext? {
        return managedObjectContext
    }
}

// MARK: - Invitation Status Enum

enum InvitationStatus: String, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        }
    }
}

//
//  UserManager.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import CoreData

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var currentUser: Person?
    @Published var isUserProfileSetup = false
    
    private let userDefaults = UserDefaults.standard
    private let currentUserIdKey = "currentUserId"
    
    private init() {
        loadCurrentUser()
    }
    
    // MARK: - User Profile Management
    
    func setupUserProfile(name: String, context: NSManagedObjectContext) {
        // Check if user already exists
        if let existingUser = currentUser {
            existingUser.name = name
        } else {
            // Create new user
            let newUser = Person(context: context)
            newUser.id = UUID()
            newUser.name = name
            currentUser = newUser
        }
        
        // Save user ID to UserDefaults
        if let userId = currentUser?.id {
            userDefaults.set(userId.uuidString, forKey: currentUserIdKey)
        }
        
        // Save to Core Data
        do {
            try context.save()
            isUserProfileSetup = true
        } catch {
            print("Error saving user profile: \(error)")
        }
    }
    
    func loadCurrentUser() {
        guard let userIdString = userDefaults.string(forKey: currentUserIdKey),
              let userId = UUID(uuidString: userIdString) else {
            isUserProfileSetup = false
            return
        }
        
        // Load user from Core Data
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        
        do {
            let users = try context.fetch(request)
            if let user = users.first {
                currentUser = user
                isUserProfileSetup = true
            } else {
                // User not found, clear the stored ID
                userDefaults.removeObject(forKey: currentUserIdKey)
                isUserProfileSetup = false
            }
        } catch {
            print("Error loading current user: \(error)")
            isUserProfileSetup = false
        }
    }
    
    func updateUserProfile(name: String, context: NSManagedObjectContext) {
        guard let user = currentUser else { return }
        
        user.name = name
        
        do {
            try context.save()
        } catch {
            print("Error updating user profile: \(error)")
        }
    }
    
    func addCurrentUserToGroup(_ group: Group, context: NSManagedObjectContext) {
        guard let user = currentUser else { return }
        
        // Check if user is already in the group
        if let members = group.members?.allObjects as? [Person],
           members.contains(where: { $0.id == user.id }) {
            return // User already in group
        }
        
        user.addToGroups(group)
        
        do {
            try context.save()
        } catch {
            print("Error adding current user to group: \(error)")
        }
    }
    
    func removeCurrentUserFromGroup(_ group: Group, context: NSManagedObjectContext) {
        guard let user = currentUser else { return }
        
        if user.groups?.contains(group) == true {
            user.removeFromGroups(group)
            
            do {
                try context.save()
            } catch {
                print("Error removing current user from group: \(error)")
            }
        }
    }
    
    func isCurrentUserInGroup(_ group: Group) -> Bool {
        guard let user = currentUser else { return false }
        return user.groups?.contains(group) == true
    }
    
    func resetUserProfile() {
        currentUser = nil
        isUserProfileSetup = false
        userDefaults.removeObject(forKey: currentUserIdKey)
    }
}

// MARK: - User Profile Setup View

struct UserProfileSetupView: View {
    @StateObject private var userManager = UserManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var userName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to Expense Splitter!")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's set up your profile to get started")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    TextField("Your Name", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                    
                    Button("Create Profile") {
                        createProfile()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func createProfile() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter your name"
            showingAlert = true
            return
        }
        
        userManager.setupUserProfile(name: trimmedName, context: viewContext)
    }
}


#Preview {
    UserProfileSetupView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

//
//  FirebaseService.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - User Model for Firebase
struct FirebaseUser: Codable, Identifiable {
    var id: String?
    var username: String
    var name: String
    var email: String?
    var phoneNumber: String?
    var createdAt: Date
    var lastSeen: Date
    
    init(username: String, name: String, email: String? = nil, phoneNumber: String? = nil, id: String? = nil) {
        self.id = id
        self.username = username
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.createdAt = Date()
        self.lastSeen = Date()
    }
}

// MARK: - Friend Request Model for Firebase
struct FirebaseFriendRequest: Codable, Identifiable {
    var id: String?
    var senderId: String
    var receiverId: String
    var status: String // "pending", "accepted", "declined"
    var createdAt: Date
    
    init(senderId: String, receiverId: String) {
        self.id = nil
        self.senderId = senderId
        self.receiverId = receiverId
        self.status = "pending"
        self.createdAt = Date()
    }
}

// MARK: - Group Model for Firebase
struct FirebaseGroup: Codable, Identifiable {
    var id: String?
    var name: String
    var creatorId: String
    var memberIds: [String]
    var createdAt: Date
    
    init(name: String, creatorId: String, memberIds: [String] = []) {
        self.id = nil
        self.name = name
        self.creatorId = creatorId
        self.memberIds = memberIds
        self.createdAt = Date()
    }
}

// MARK: - Firebase Service
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var currentUser: FirebaseUser?
    @Published var friends: [FirebaseUser] = []
    @Published var pendingFriendRequests: [FirebaseFriendRequest] = []
    @Published var groups: [FirebaseGroup] = []
    
    private let db = Firestore.firestore()
    private var friendRequestsListener: ListenerRegistration?
    private var friendsListener: ListenerRegistration?
    private var groupsListener: ListenerRegistration?
    
    private init() {
        // Listen for auth state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadUserData(uid: user.uid)
            } else {
                self?.currentUser = nil
                self?.friends = []
                self?.pendingFriendRequests = []
                self?.groups = []
            }
        }
    }
    
    deinit {
        friendRequestsListener?.remove()
        friendsListener?.remove()
        groupsListener?.remove()
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, username: String, name: String, phoneNumber: String?) async throws {
        // Create Firebase Auth user
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Create user document in Firestore
        let firebaseUser = FirebaseUser(
            username: username,
            name: name,
            email: email,
            phoneNumber: phoneNumber
        )
        
        try await db.collection("users").document(authResult.user.uid).setData([
            "username": firebaseUser.username,
            "name": firebaseUser.name,
            "email": firebaseUser.email as Any,
            "phoneNumber": firebaseUser.phoneNumber as Any,
            "createdAt": firebaseUser.createdAt,
            "lastSeen": firebaseUser.lastSeen
        ])
        
        // Update display name
        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
    }
    
    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signInWithIdentifier(_ identifier: String, password: String) async throws {
        // Check if identifier is an email or username
        if identifier.contains("@") {
            // It's an email, use regular sign in
            _ = try await Auth.auth().signIn(withEmail: identifier, password: password)
        } else {
            // It's a username, find the email first
            let userQuery = db.collection("users").whereField("username", isEqualTo: identifier)
            let userSnapshot = try await userQuery.getDocuments()
            
            print("Username search for '\(identifier)' found \(userSnapshot.documents.count) documents")
            
            guard let userDoc = userSnapshot.documents.first,
                  let email = userDoc.data()["email"] as? String else {
                print("No user found with username: \(identifier)")
                throw NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "User not found"])
            }
            
            print("Found email for username '\(identifier)': \(email)")
            
            // Sign in with the found email
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - User Data Management
    
    private func loadUserData(uid: String) {
        loadUserProfile(uid: uid)
        loadFriends(uid: uid)
        loadPendingFriendRequests(uid: uid)
        loadGroups(uid: uid)
    }
    
    private func loadUserProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let document = document, document.exists, let data = document.data() {
                let user = FirebaseUser(
                    username: data["username"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String,
                    phoneNumber: data["phoneNumber"] as? String,
                    id: document.documentID
                )
                self?.currentUser = user
            }
        }
    }
    
    private func loadFriends(uid: String) {
        // Remove existing listeners
        friendsListener?.remove()
        
        // Use a single listener that gets all friend requests where user is involved
        // We'll use a compound query approach
        friendsListener = db.collection("friendRequests")
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                // Filter documents where user is either sender or receiver
                let userFriendRequests = documents.filter { doc in
                    let data = doc.data()
                    let senderId = data["senderId"] as? String
                    let receiverId = data["receiverId"] as? String
                    return senderId == uid || receiverId == uid
                }
                
                // Extract friend IDs
                let friendIds = userFriendRequests.compactMap { doc in
                    let data = doc.data()
                    let senderId = data["senderId"] as? String
                    let receiverId = data["receiverId"] as? String
                    
                    // Return the ID of the other user (not the current user)
                    if senderId == uid {
                        return receiverId
                    } else if receiverId == uid {
                        return senderId
                    }
                    return nil
                }
                
                // Remove duplicates
                let uniqueFriendIds = Array(Set(friendIds))
                
                // Load friend details
                self?.loadUsersByIds(uniqueFriendIds) { users in
                    self?.friends = users
                }
            }
    }
    
    private func loadPendingFriendRequests(uid: String) {
        friendRequestsListener?.remove()
        
        friendRequestsListener = db.collection("friendRequests")
            .whereField("receiverId", isEqualTo: uid)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self?.pendingFriendRequests = documents.compactMap { doc in
                    let data = doc.data()
                    var request = FirebaseFriendRequest(
                        senderId: data["senderId"] as? String ?? "",
                        receiverId: data["receiverId"] as? String ?? ""
                    )
                    request.id = doc.documentID
                    request.status = data["status"] as? String ?? "pending"
                    return request
                }
            }
    }
    
    private func loadGroups(uid: String) {
        groupsListener?.remove()
        
        groupsListener = db.collection("groups")
            .whereField("memberIds", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self?.groups = documents.compactMap { doc in
                    let data = doc.data()
                    var group = FirebaseGroup(
                        name: data["name"] as? String ?? "",
                        creatorId: data["creatorId"] as? String ?? "",
                        memberIds: data["memberIds"] as? [String] ?? []
                    )
                    group.id = doc.documentID
                    return group
                }
            }
    }
    
    private func loadUsersByIds(_ ids: [String], completion: @escaping ([FirebaseUser]) -> Void) {
        guard !ids.isEmpty else {
            completion([])
            return
        }
        
        db.collection("users").whereField(FieldPath.documentID(), in: ids).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            let users = documents.compactMap { doc in
                let data = doc.data()
                return FirebaseUser(
                    username: data["username"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String,
                    phoneNumber: data["phoneNumber"] as? String,
                    id: doc.documentID
                )
            }
            completion(users)
        }
    }
    
    // MARK: - Friend Requests
    
    func sendFriendRequest(to username: String) async throws {
        guard let currentUserId = currentUser?.id else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Find user by username
        let userQuery = db.collection("users").whereField("username", isEqualTo: username)
        let userSnapshot = try await userQuery.getDocuments()
        
        guard let userDoc = userSnapshot.documents.first else {
            throw NSError(domain: "FirebaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        let receiverId = userDoc.documentID
        
        // Check if request already exists
        let existingRequestQuery = db.collection("friendRequests")
            .whereField("senderId", isEqualTo: currentUserId)
            .whereField("receiverId", isEqualTo: receiverId)
        
        let existingSnapshot = try await existingRequestQuery.getDocuments()
        
        if !existingSnapshot.documents.isEmpty {
            throw NSError(domain: "FirebaseService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent"])
        }
        
        // Create friend request
        let friendRequest = FirebaseFriendRequest(senderId: currentUserId, receiverId: receiverId)
        try await db.collection("friendRequests").addDocument(data: [
            "senderId": friendRequest.senderId,
            "receiverId": friendRequest.receiverId,
            "status": friendRequest.status,
            "createdAt": friendRequest.createdAt
        ])
    }
    
    func respondToFriendRequest(_ request: FirebaseFriendRequest, accept: Bool) async throws {
        guard let requestId = request.id else { return }
        
        let status = accept ? "accepted" : "declined"
        try await db.collection("friendRequests").document(requestId).updateData(["status": status])
    }
    
    // MARK: - Groups
    
    func createGroup(name: String) async throws {
        guard let currentUserId = currentUser?.id else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        let group = FirebaseGroup(name: name, creatorId: currentUserId, memberIds: [currentUserId])
        try await db.collection("groups").addDocument(data: [
            "name": group.name,
            "creatorId": group.creatorId,
            "memberIds": group.memberIds,
            "createdAt": group.createdAt
        ])
    }
    
    func addMemberToGroup(groupId: String, userId: String) async throws {
        try await db.collection("groups").document(groupId).updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
    }
    
    func deleteGroup(groupId: String) async throws {
        try await db.collection("groups").document(groupId).delete()
    }
    
    func removeMemberFromGroup(groupId: String, userId: String) async throws {
        try await db.collection("groups").document(groupId).updateData([
            "memberIds": FieldValue.arrayRemove([userId])
        ])
    }
    
    func updateUserProfile(username: String, name: String, phoneNumber: String, email: String?) async throws {
        guard let currentUserId = currentUser?.id else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        var updateData: [String: Any] = [
            "username": username,
            "name": name,
            "phoneNumber": phoneNumber,
            "lastSeen": Date()
        ]
        
        if let email = email {
            updateData["email"] = email
        }
        
        try await db.collection("users").document(currentUserId).updateData(updateData)
    }
}

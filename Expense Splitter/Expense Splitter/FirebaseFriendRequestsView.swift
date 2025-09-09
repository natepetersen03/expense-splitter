//
//  FirebaseFriendRequestsView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import FirebaseFirestore

struct FirebaseFriendRequestsView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if firebaseService.pendingFriendRequests.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Friend Requests")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("When someone sends you a friend request, it will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(firebaseService.pendingFriendRequests) { request in
                            FirebaseFriendRequestRowView(request: request)
                        }
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FirebaseFriendRequestRowView: View {
    let request: FirebaseFriendRequest
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var sender: FirebaseUser?
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let sender = sender {
                    Text(sender.name)
                        .font(.headline)
                    
                    Text("@\(sender.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                HStack(spacing: 12) {
                    Button("Decline") {
                        respondToRequest(accept: false)
                    }
                    .foregroundColor(.red)
                    .buttonStyle(.bordered)
                    
                    Button("Accept") {
                        respondToRequest(accept: true)
                    }
                    .foregroundColor(.white)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadSender()
        }
    }
    
    private func loadSender() {
        let senderId = request.senderId
        
        Firestore.firestore().collection("users").document(senderId).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                sender = FirebaseUser(
                    username: data["username"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String,
                    phoneNumber: data["phoneNumber"] as? String,
                    id: document.documentID
                )
            }
        }
    }
    
    private func respondToRequest(accept: Bool) {
        isLoading = true
        
        Task {
            do {
                try await firebaseService.respondToFriendRequest(request, accept: accept)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Error responding to friend request: \(error)")
                }
            }
        }
    }
}

#Preview {
    FirebaseFriendRequestsView()
}

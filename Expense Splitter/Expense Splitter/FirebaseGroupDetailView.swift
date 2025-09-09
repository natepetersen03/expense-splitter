//
//  FirebaseGroupDetailView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI

struct FirebaseGroupDetailView: View {
    let group: FirebaseGroup
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Group: \(group.name)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Created by: \(group.creatorId)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Members: \(group.memberIds.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    FirebaseGroupDetailView(group: FirebaseGroup(name: "Test Group", creatorId: "test", memberIds: ["test"]))
}

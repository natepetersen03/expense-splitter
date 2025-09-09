//
//  ContentView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userService: UserService
    @EnvironmentObject private var firebaseService: FirebaseService
    
    var body: some View {
        if firebaseService.currentUser != nil {
            GroupListView()
        } else {
            FirebaseAuthView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserService.shared)
        .environmentObject(FirebaseService.shared)
}

//
//  ContentView.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userService: UserService
    
    var body: some View {
        if userService.currentUser != nil {
            GroupListView()
        } else {
            UserRegistrationView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserService.shared)
}

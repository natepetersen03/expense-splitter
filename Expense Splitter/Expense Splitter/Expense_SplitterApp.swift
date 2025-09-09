//
//  Expense_SplitterApp.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI

@main
struct Expense_SplitterApp: App {
    let persistence = PersistenceController.shared
    @StateObject private var userService = UserService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                             persistence.container.viewContext)
                .environmentObject(userService)
                .onAppear {
                    userService.initialize(context: persistence.container.viewContext)
                }
        }
    }
}

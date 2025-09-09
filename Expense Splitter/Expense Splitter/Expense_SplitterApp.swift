//
//  Expense_SplitterApp.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct Expense_SplitterApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let persistence = PersistenceController.shared
    @StateObject private var userService = UserService.shared
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                             persistence.container.viewContext)
                .environmentObject(userService)
                .environmentObject(firebaseService)
                .onAppear {
                    userService.initialize(context: persistence.container.viewContext)
                }
        }
    }
}

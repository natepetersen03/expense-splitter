//
//  Persistence.swift
//  Expense Splitter
//
//  Created by Nate Petersen on 5/8/25.
//

import CoreData

struct PersistenceController {
  static let shared = PersistenceController()

  let container: NSPersistentContainer

  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "ExpenseSplitter")
      // ← match your .xcdatamodeld filename
    if inMemory {
      container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }
    
    // Try to load the persistent store
    var loadError: NSError?
    container.loadPersistentStores { desc, error in
      loadError = error as NSError?
    }
    
    // If there's a Core Data error, try to delete the existing store and recreate
    if let error = loadError {
      if error.code == 134110 || error.code == 134030 { // Model validation or migration error
        print("Core Data model changed, deleting existing store...")
        deletePersistentStore()
        
        // Try loading again
        container.loadPersistentStores { desc, error in
          if let error = error as NSError? {
            fatalError("Unresolved Core Data error after reset: \(error), \(error.userInfo)")
          }
        }
      } else {
        fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
      }
    }
    
    container.viewContext.automaticallyMergesChangesFromParent = true
  }
  
  private func deletePersistentStore() {
    guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
    
    do {
      // Delete the existing store files
      let fileManager = FileManager.default
      let storeDirectory = storeURL.deletingLastPathComponent()
      
      // Find all files related to this store
      let files = try fileManager.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil)
      for file in files {
        if file.lastPathComponent.hasPrefix(storeURL.lastPathComponent) {
          try fileManager.removeItem(at: file)
          print("Deleted store file: \(file.lastPathComponent)")
        }
      }
    } catch {
      print("Error deleting persistent store: \(error)")
    }
  }
}


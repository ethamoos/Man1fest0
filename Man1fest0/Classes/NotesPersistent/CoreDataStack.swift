//
//  CoreDataStack.swift
//  Man1fest0
//
//  Created by Amos Deane on 14/07/2025.
//
//

import Foundation
import CoreData

class CoreDataStack: ObservableObject {
    private let persistentContainer: NSPersistentContainer
    var managedObjectContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    init(modelName: String) {
        print("Init \(modelName)")
        persistentContainer = {
            let container = NSPersistentContainer(name: modelName)
            container.loadPersistentStores { description, error in
                if let error = error {
                    print(error)
                }
            }
            return container
        }()
    }

    func save () {
        print("Saving note")
        guard managedObjectContext.hasChanges else { return }
        do {
            try managedObjectContext.save()
        } catch {
            print(error)
        }
    }
    
    func insertNote(mainBody: String, reference: String, additionalNotes: String) {
        let note = Note(context: managedObjectContext)
        note.mainBody = mainBody
        note.reference = reference
        note.additionalNotes = additionalNotes
    }
}

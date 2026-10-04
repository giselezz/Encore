//
//  Persistence.swift
//  Encore
//
//  Created by Yufan on 26/9/2026.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController(
        migrateExistingStore: true
    )

    @MainActor
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer
    let startupError: Error?

    enum SetupError: LocalizedError {
        case missingStoreLocation
        case openEncoreFirst

        var errorDescription: String? {
            switch self {
            case .missingStoreLocation:
                return "Encore couldn’t locate its concert database."
            case .openEncoreFirst:
                return "Open Encore once to prepare your concert library, then share your photo again."
            }
        }
    }

    init(
        inMemory: Bool = false,
        migrateExistingStore: Bool = false
    ) {
        let container = NSPersistentContainer(name: "Encore")
        self.container = container

        do {
            let description: NSPersistentStoreDescription

            if inMemory {
                description = NSPersistentStoreDescription()
                description.type = NSInMemoryStoreType
            } else {
                guard let originalURL =
                    container.persistentStoreDescriptions.first?.url
                else {
                    throw SetupError.missingStoreLocation
                }

                let sharedURL = try EncoreSharedStorage.databaseURL()
                let files = FileManager.default

                if !files.fileExists(atPath: sharedURL.path) {
                    guard migrateExistingStore else {
                        throw SetupError.openEncoreFirst
                    }

                    if files.fileExists(atPath: originalURL.path) {
                        try container.persistentStoreCoordinator
                            .replacePersistentStore(
                                at: sharedURL,
                                destinationOptions: nil,
                                withPersistentStoreFrom: originalURL,
                                sourceOptions: nil,
                                ofType: NSSQLiteStoreType
                            )
                    }
                }

                description = NSPersistentStoreDescription(
                    url: sharedURL
                )

                description.setOption(
                    true as NSNumber,
                    forKey: NSPersistentHistoryTrackingKey
                )

                description.setOption(
                    true as NSNumber,
                    forKey:
                        NSPersistentStoreRemoteChangeNotificationPostOptionKey
                )
            }

            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            description.shouldAddStoreAsynchronously = false

            container.persistentStoreDescriptions = [description]

            var loadingError: Error?

            container.loadPersistentStores { _, error in
                loadingError = error
            }

            if let loadingError {
                throw loadingError
            }

            container.viewContext.automaticallyMergesChangesFromParent = true

            if !inMemory && migrateExistingStore {
                try EncoreSharedStorage.migrateExistingPhotos()
            }

            startupError = nil
        } catch {
            startupError = error
            print("Encore storage setup failed: \(error)")
        }
    }
}

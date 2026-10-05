//
//  CoreDataFeaturedConcertMemoryRepository.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//

import Foundation
import CoreData

final class CoreDataFeaturedConcertMemoryRepository:
    FeaturedConcertMemoryRepository {

    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer) {
        context = container.newBackgroundContext()
    }

    enum StorageError: LocalizedError {
        case incompleteMemory

        var errorDescription: String? {
            "This concert memory has missing details. Open Encore to check your saved memories."
        }
    }

    func fetchLatestMemory() throws -> FeaturedConcertMemory? {
        try context.performAndWait {
            let request = NSFetchRequest<ConcertMemory>(
                entityName: "ConcertMemory"
            )

            request.sortDescriptors = [
                NSSortDescriptor(
                    key: "createdAt",
                    ascending: false
                ),
                NSSortDescriptor(
                    key: "id",
                    ascending: true
                )
            ]
            request.fetchLimit = 1

            guard let memory = try context.fetch(request).first else {
                return nil
            }

            guard
                let memoryID = memory.id,
                let concert = memory.concert,
                let concertID = concert.id,
                let artistName = concert.artistName,
                let venueName = concert.venueName,
                let concertDate = concert.concertDate
            else {
                throw StorageError.incompleteMemory
            }

            return FeaturedConcertMemory(
                id: memoryID,
                concertID: concertID,
                artistName: artistName,
                venueName: venueName,
                concertDate: concertDate,
                caption: memory.caption,
                photoFilename: memory.photoFilename
            )
        }
    }
}

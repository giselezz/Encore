//
//  CoreDataConcertMemoryRepository.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import Foundation
import CoreData

final class CoreDataConcertMemoryRepository: ConcertMemoryRepository {
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer) {
        context = container.newBackgroundContext()
    }

    enum StorageError: LocalizedError {
        case concertNotFound
        case incompleteMemory

        var errorDescription: String? {
            switch self {
            case .concertNotFound:
                return "This concert is no longer available. Return to your concert library and select a concert."
            case .incompleteMemory:
                return "A concert memory has missing details and couldn’t be opened. Return to the concert and try again."
            }
        }
    }

    func saveMemory(_ memory: ConcertMoment) throws {
        try context.performAndWait {
            do {
                let concertRequest = NSFetchRequest<ConcertEntry>(
                    entityName: "ConcertEntry"
                )
                concertRequest.predicate = NSPredicate(
                    format: "id == %@",
                    memory.concertID as NSUUID
                )
                concertRequest.fetchLimit = 1

                guard let concert = try context.fetch(
                    concertRequest
                ).first else {
                    throw StorageError.concertNotFound
                }

                let memoryRequest = NSFetchRequest<ConcertMemory>(
                    entityName: "ConcertMemory"
                )
                memoryRequest.predicate = NSPredicate(
                    format: "id == %@",
                    memory.id as NSUUID
                )
                memoryRequest.fetchLimit = 1

                let entry = try context.fetch(memoryRequest).first
                    ?? ConcertMemory(context: context)

                entry.id = memory.id
                entry.caption = memory.caption
                entry.photoFilename = memory.photoFilename
                entry.createdAt = memory.createdAt
                entry.concert = concert

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func fetchMemories(
        for concertID: UUID
    ) throws -> [ConcertMoment] {
        try context.performAndWait {
            let request = NSFetchRequest<ConcertMemory>(
                entityName: "ConcertMemory"
            )
            request.predicate = NSPredicate(
                format: "concert.id == %@",
                concertID as NSUUID
            )
            request.sortDescriptors = [
                NSSortDescriptor(
                    key: "createdAt",
                    ascending: false
                )
            ]

            return try context.fetch(request).map { entry in
                try makeMemory(from: entry)
            }
        }
    }
    
    func deleteMemory(id: UUID, concertID: UUID) throws {
        try context.performAndWait {
            do {
                let request = NSFetchRequest<ConcertMemory>(
                    entityName: "ConcertMemory"
                )

                request.predicate = NSPredicate(
                    format: "id == %@ AND concert.id == %@",
                    id as NSUUID,
                    concertID as NSUUID
                )
                request.fetchLimit = 1

                guard let entry = try context.fetch(request).first else {
                    return
                }

                context.delete(entry)
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    private func makeMemory(
        from entry: ConcertMemory
    ) throws -> ConcertMoment {
        guard
            let id = entry.id,
            let concertID = entry.concert?.id,
            let createdAt = entry.createdAt
        else {
            throw StorageError.incompleteMemory
        }

        return ConcertMoment(
            id: id,
            concertID: concertID,
            caption: entry.caption,
            photoFilename: entry.photoFilename,
            createdAt: createdAt
        )
    }
}

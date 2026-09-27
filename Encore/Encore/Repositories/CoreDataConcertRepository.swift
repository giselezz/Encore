//
//  CoreDataConcertRepository.swift
//  Encore
//
//  Created by Yufan on 27/9/2026.
//

import Foundation
import CoreData

final class CoreDataConcertRepository: ConcertRepository {
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer) {
        context = container.newBackgroundContext()
    }

    enum StorageError: LocalizedError {
        case incompleteConcert

        var errorDescription: String? {
            "A saved concert has missing details and couldn’t be opened."
        }
    }

    func saveConcert(_ concert: Concert) throws {
        try context.performAndWait {
            do {
                let request = NSFetchRequest<ConcertEntry>(
                    entityName: "ConcertEntry"
                )
                request.predicate = NSPredicate(
                    format: "id == %@",
                    concert.id as NSUUID
                )
                request.fetchLimit = 1

                let entry = try context.fetch(request).first
                    ?? ConcertEntry(context: context)

                entry.id = concert.id
                entry.artistName = concert.artistName
                entry.venueName = concert.venueName
                entry.concertDate = concert.concertDate
                entry.createdAt = concert.createdAt

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func fetchConcerts() throws -> [Concert] {
        try fetchConcerts(matching: nil)
    }

    func fetchConcerts(
        from startDate: Date,
        to endDate: Date
    ) throws -> [Concert] {
        let predicate = NSPredicate(
            format: "concertDate >= %@ AND concertDate < %@",
            startDate as NSDate,
            endDate as NSDate
        )

        return try fetchConcerts(matching: predicate)
    }

    private func fetchConcerts(
        matching predicate: NSPredicate?
    ) throws -> [Concert] {
        try context.performAndWait {
            let request = NSFetchRequest<ConcertEntry>(
                entityName: "ConcertEntry"
            )
            request.predicate = predicate
            request.sortDescriptors = [
                NSSortDescriptor(
                    key: "concertDate",
                    ascending: false
                )
            ]

            return try context.fetch(request).map { entry in
                try makeConcert(from: entry)
            }
        }
    }

    private func makeConcert(
        from entry: ConcertEntry
    ) throws -> Concert {
        guard
            let id = entry.id,
            let artistName = entry.artistName,
            let venueName = entry.venueName,
            let concertDate = entry.concertDate,
            let createdAt = entry.createdAt
        else {
            throw StorageError.incompleteConcert
        }

        return Concert(
            id: id,
            artistName: artistName,
            venueName: venueName,
            concertDate: concertDate,
            createdAt: createdAt
        )
    }
}

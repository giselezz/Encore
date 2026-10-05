//
//  DeleteConcertMemory.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//

import Foundation

struct DeleteConcertMemory {
    let repository: any ConcertMemoryRepository
    let photoStorage: any ConcertPhotoStorage

    enum DeletionError: LocalizedError, Equatable {
        case concertMismatch
        case deletionFailed
        case photoCleanupFailed

        var errorDescription: String? {
            switch self {
            case .concertMismatch:
                return """
                This memory belongs to another concert. \
                Return to your concert library and open its concert.
                """

            case .deletionFailed:
                return """
                Your memory couldn’t be deleted. \
                It hasn’t been removed. Please try again.
                """

            case .photoCleanupFailed:
                return """
                The memory was removed, but its saved photo file \
                couldn’t be cleared. Retry to finish removing the file.
                """
            }
        }
    }

    func execute(
        memory: ConcertMoment,
        concertID: UUID
    ) throws {
        guard memory.concertID == concertID else {
            throw DeletionError.concertMismatch
        }

        do {
            try repository.deleteMemory(
                id: memory.id,
                concertID: concertID
            )
        } catch {
            throw DeletionError.deletionFailed
        }

        if let filename = memory.photoFilename {
            do {
                try photoStorage.deletePhoto(named: filename)
            } catch {
                throw DeletionError.photoCleanupFailed
            }
        }
    }
}

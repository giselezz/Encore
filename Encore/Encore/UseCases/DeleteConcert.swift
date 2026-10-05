//
//  DeleteConcert.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//

import Foundation

struct DeleteConcert {
    let repository: any ConcertRepository
    let photoStorage: any ConcertPhotoStorage

    enum DeletionError: LocalizedError, Equatable {
        case confirmationRequired
        case deletionFailed

        var errorDescription: String? {
            switch self {
            case .confirmationRequired:
                return """
                Confirm that you want to delete this concert \
                and all its memories before continuing.
                """

            case .deletionFailed:
                return """
                This concert couldn’t be deleted. \
                Your concert and memories are still saved. \
                Please try again.
                """
            }
        }
    }

    enum Outcome: Equatable {
        case deleted
        case photoCleanupRequired([String])
    }

    func execute(
        concertID: UUID,
        confirmed: Bool
    ) throws -> Outcome {
        guard confirmed else {
            throw DeletionError.confirmationRequired
        }

        let photoFilenames: [String]

        do {
            photoFilenames = try repository.deleteConcert(
                id: concertID
            )
        } catch {
            throw DeletionError.deletionFailed
        }

        return retryPhotoCleanup(filenames: photoFilenames)
    }

    func retryPhotoCleanup(filenames: [String]) -> Outcome {
        var remainingFilenames: [String] = []

        for filename in Set(filenames).sorted() {
            do {
                try photoStorage.deletePhoto(named: filename)
            } catch {
                remainingFilenames.append(filename)
            }
        }

        if remainingFilenames.isEmpty {
            return .deleted
        }

        return .photoCleanupRequired(remainingFilenames)
    }
}

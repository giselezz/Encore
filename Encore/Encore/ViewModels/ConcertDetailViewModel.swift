//
//  ConcertDetailViewModel.swift
//  Encore
//
//  Created by Yufan on 2/10/2026.
//

import Foundation
import Combine
import UIKit

@MainActor
final class ConcertDetailViewModel: ObservableObject {
    @Published private(set) var memories: [ConcertMoment] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var photos: [UUID: UIImage] = [:]
    @Published private(set) var photoErrors: [UUID: String] = [:]
    @Published private(set) var concert: Concert
    @Published private(set) var deletionErrorMessage: String?
    @Published private(set) var pendingDeletion: ConcertMoment?
    @Published private(set) var concertDeletionErrorMessage: String?
    @Published private(set) var hasDeletedConcert = false

    private let revisitMemories: RevisitConcertMemories
    private let deleteMemory: DeleteConcertMemory
    private let deleteConcert: DeleteConcert
    private var remainingPhotoFilenames: [String] = []

    init(
        concert: Concert,
        revisitMemories: RevisitConcertMemories,
        deleteMemory: DeleteConcertMemory,
        deleteConcert: DeleteConcert
    ) {
        self.concert = concert
        self.revisitMemories = revisitMemories
        self.deleteMemory = deleteMemory
        self.deleteConcert = deleteConcert
    }
    
    func updateConcert(_ updatedConcert: Concert) {
        guard updatedConcert.id == concert.id else { return }
        concert = updatedConcert
    }
    
    func removeMemory(_ memory: ConcertMoment) {
        // Keep any failed deletion available for retry.
        guard pendingDeletion == nil
                || pendingDeletion?.id == memory.id else {
            return
        }

        deletionErrorMessage = nil

        do {
            try deleteMemory.execute(
                memory: memory,
                concertID: concert.id
            )

            pendingDeletion = nil
        } catch let error as DeleteConcertMemory.DeletionError {
            pendingDeletion = memory
            deletionErrorMessage = error.errorDescription
        } catch {
            pendingDeletion = memory
            deletionErrorMessage =
                "The memory couldn’t be fully removed. Tap Retry to try again."
        }

        // Refresh even when only photo cleanup failed:
        // the database record may already have been deleted.
        loadMemories()
    }

    func retryMemoryDeletion() {
        guard let memory = pendingDeletion else { return }
        removeMemory(memory)
    }

    func loadMemories() {
        guard !hasDeletedConcert else { return }
        errorMessage = nil
        photos = [:]
        photoErrors = [:]

        do {
            memories = try revisitMemories.execute(
                concertID: concert.id
            )
        } catch let error as RevisitConcertMemories.MemoryHistoryError {
            memories = []
            errorMessage = error.errorDescription
            return
        } catch {
            memories = []
            errorMessage =
                "Your concert memories couldn’t be loaded. Please try again."
            return
        }

        for memory in memories {
            do {
                guard let data = try revisitMemories.loadPhoto(
                    for: memory
                ) else {
                    continue
                }

                guard let image = UIImage(data: data) else {
                    throw RevisitConcertMemories
                        .MemoryHistoryError.photoLoadingFailed
                }

                photos[memory.id] = image
            } catch {
                photoErrors[memory.id] =
                    "This concert photo couldn’t be opened. Tap Try Again to reload it."
            }
        }
    }
    
    func removeConcert() -> Bool {
        guard !hasDeletedConcert else { return false }

        guard pendingDeletion == nil else {
            concertDeletionErrorMessage =
                "Finish retrying the memory removal above before deleting this concert."
            return false
        }

        concertDeletionErrorMessage = nil

        do {
            let outcome = try deleteConcert.execute(
                concertID: concert.id,
                confirmed: true
            )

            hasDeletedConcert = true
            memories = []
            photos = [:]
            photoErrors = [:]
            errorMessage = nil

            return handleConcertDeletionOutcome(outcome)
        } catch let error as DeleteConcert.DeletionError {
            concertDeletionErrorMessage = error.errorDescription
            return false
        } catch {
            concertDeletionErrorMessage =
                "This concert couldn’t be deleted. Please try again."
            return false
        }
    }

    func retryConcertPhotoCleanup() -> Bool {
        guard hasDeletedConcert else { return false }

        let outcome = deleteConcert.retryPhotoCleanup(
            filenames: remainingPhotoFilenames
        )

        return handleConcertDeletionOutcome(outcome)
    }

    private func handleConcertDeletionOutcome(
        _ outcome: DeleteConcert.Outcome
    ) -> Bool {
        switch outcome {
        case .deleted:
            remainingPhotoFilenames = []
            concertDeletionErrorMessage = nil
            return true

        case .photoCleanupRequired(let filenames):
            remainingPhotoFilenames = filenames
            concertDeletionErrorMessage = """
            The concert and its memories were deleted, but some photo \
            files couldn’t be cleared. Tap Retry Photo Cleanup.
            """
            return false
        }
    }
}

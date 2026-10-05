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

    private let revisitMemories: RevisitConcertMemories
    private let deleteMemory: DeleteConcertMemory

    init(
        concert: Concert,
        revisitMemories: RevisitConcertMemories,
        deleteMemory: DeleteConcertMemory
    ) {
        self.concert = concert
        self.revisitMemories = revisitMemories
        self.deleteMemory = deleteMemory
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
}

//
//  RevisitConcertMemories.swift
//  Encore
//
//  Created by Yufan on 2/10/2026.
//

import Foundation

struct RevisitConcertMemories {
    let repository: any ConcertMemoryRepository
    let photoStorage: any ConcertPhotoStorage

    enum MemoryHistoryError: LocalizedError, Equatable {
        case loadingFailed
        case concertMismatch
        case photoLoadingFailed

        var errorDescription: String? {
            switch self {
            case .loadingFailed:
                return "Your concert memories couldn’t be loaded. Please try again."
            case .concertMismatch:
                return "These memories couldn’t be matched to this concert. Return to your library and reopen the concert."
            case .photoLoadingFailed:
                return "This concert photo couldn’t be opened. Tap Try Again to reload it."
            }
        }
    }

    func execute(
        concertID: UUID
    ) throws -> [ConcertMoment] {
        let memories: [ConcertMoment]

        do {
            memories = try repository.fetchMemories(
                for: concertID
            )
        } catch {
            throw MemoryHistoryError.loadingFailed
        }

        guard memories.allSatisfy({
            $0.concertID == concertID
        }) else {
            throw MemoryHistoryError.concertMismatch
        }

        return memories.sorted {
            $0.createdAt > $1.createdAt
        }
    }
    
    func loadPhoto(for memory: ConcertMoment) throws -> Data? {
        guard let filename = memory.photoFilename else {
            return nil
        }

        do {
            return try photoStorage.loadPhoto(named: filename)
        } catch {
            throw MemoryHistoryError.photoLoadingFailed
        }
    }
}

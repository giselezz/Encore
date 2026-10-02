//
//  RevisitConcertMemories.swift
//  Encore
//
//  Created by Yufan on 2/10/2026.
//

import Foundation

struct RevisitConcertMemories {
    let repository: any ConcertMemoryRepository

    enum MemoryHistoryError: LocalizedError, Equatable {
        case loadingFailed
        case concertMismatch

        var errorDescription: String? {
            switch self {
            case .loadingFailed:
                return "Your concert memories couldn’t be loaded. Please try again."
            case .concertMismatch:
                return "These memories couldn’t be matched to this concert. Return to your library and reopen the concert."
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
}

//
//  Untitled.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import Foundation

struct AddConcertMemory {
    let repository: any ConcertMemoryRepository

    enum MemoryError: LocalizedError, Equatable {
        case emptyMemory
        case savingFailed

        var errorDescription: String? {
            switch self {
            case .emptyMemory:
                return "Add a photo or write something about this concert before saving."
            case .savingFailed:
                return "Your concert memory couldn’t be saved. Please try again."
            }
        }
    }

    func execute(
        concertID: UUID,
        caption: String,
        photoFilename: String? = nil,
        now: Date = Date()
    ) throws -> ConcertMoment {
        let text = caption.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let filename = photoFilename?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let savedPhoto = filename.flatMap {
            $0.isEmpty ? nil : $0
        }

        guard !text.isEmpty || savedPhoto != nil else {
            throw MemoryError.emptyMemory
        }

        let memory = ConcertMoment(
            id: UUID(),
            concertID: concertID,
            caption: text.isEmpty ? nil : text,
            photoFilename: savedPhoto,
            createdAt: now
        )

        do {
            try repository.saveMemory(memory)
        } catch {
            throw MemoryError.savingFailed
        }

        return memory
    }
}

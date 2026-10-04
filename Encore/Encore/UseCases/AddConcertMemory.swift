import Foundation
import OSLog

struct AddConcertMemory {
    let repository: any ConcertMemoryRepository
    let photoStorage: any ConcertPhotoStorage

    enum MemoryError: LocalizedError, Equatable {
        case emptyMemory
        case photoSavingFailed
        case savingFailed

        var errorDescription: String? {
            switch self {
            case .emptyMemory:
                return "Add a photo or write something about this concert before saving."
            case .photoSavingFailed:
                return "Your photo couldn’t be saved. Try again or choose another photo."
            case .savingFailed:
                return "Your concert memory couldn’t be saved. Please try again."
            }
        }
    }

    func execute(
        concertID: UUID,
        caption: String,
        photoData: Data? = nil,
        now: Date = Date()
    ) throws -> ConcertMoment {
        let text = caption.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !text.isEmpty || photoData != nil else {
            throw MemoryError.emptyMemory
        }

        var photoFilename: String?

        if let photoData {
            do {
                photoFilename = try photoStorage.savePhoto(photoData)
            } catch {
                throw MemoryError.photoSavingFailed
            }
        }

        let memory = ConcertMoment(
            id: UUID(),
            concertID: concertID,
            caption: text.isEmpty ? nil : text,
            photoFilename: photoFilename,
            createdAt: now
        )

        do {
            try repository.saveMemory(memory)
        } catch {
            if let photoFilename {
                do {
                    try photoStorage.deletePhoto(named: photoFilename)
                } catch {
                    Logger(
                        subsystem: "com.yufan.Encore",
                        category: "PhotoStorage"
                    ).error(
                        "Could not remove unused photo: \(error.localizedDescription, privacy: .private)"
                    )
                }
            }

            throw MemoryError.savingFailed
        }

        return memory
    }
}

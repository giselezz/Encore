//
//  MockConcertRepository.swift
//  EncoreTests
//
//  Created by Yufan on 26/9/2026.
//

import Foundation
@testable import Encore

enum MockStorageError: Error {
    case simulatedFailure
}

final class MockConcertRepository: ConcertRepository {
    var concerts: [Concert] = []
    var shouldFailSave = false
    var shouldFailDelete = false
    var photoFilenamesByConcert: [UUID: [String]] = [:]

    func saveConcert(_ concert: Concert) throws {
        if shouldFailSave {
            throw MockStorageError.simulatedFailure
        }
        if let index = concerts.firstIndex(where: { $0.id == concert.id }) {
            concerts[index] = concert
        } else {
            concerts.append(concert)
        }
    }

    func fetchConcerts() throws -> [Concert] {
        concerts.sorted { $0.concertDate > $1.concertDate }
    }

    func fetchConcerts(
        from startDate: Date,
        to endDate: Date
    ) throws -> [Concert] {
        try fetchConcerts().filter {
            $0.concertDate >= startDate && $0.concertDate < endDate
        }
    }
    
    func deleteConcert(id: UUID) throws -> [String] {
        if shouldFailDelete {
            throw MockStorageError.simulatedFailure
        }

        guard concerts.contains(where: { $0.id == id }) else {
            return []
        }

        concerts.removeAll { $0.id == id }

        return photoFilenamesByConcert.removeValue(forKey: id) ?? []
    }
}

final class MockConcertMemoryRepository: ConcertMemoryRepository {
    var memories: [ConcertMoment] = []
    var shouldFailSave = false
    var shouldFailDelete = false

    func saveMemory(_ memory: ConcertMoment) throws {
        if shouldFailSave {
            throw MockStorageError.simulatedFailure
        }
        if let index = memories.firstIndex(where: {
            $0.id == memory.id
        }) {
            memories[index] = memory
        } else {
            memories.append(memory)
        }
    }

    func fetchMemories(
        for concertID: UUID
    ) throws -> [ConcertMoment] {
        memories
            .filter { $0.concertID == concertID }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteMemory(id: UUID, concertID: UUID) throws {
        if shouldFailDelete {
            throw MockStorageError.simulatedFailure
        }

        memories.removeAll {
            $0.id == id && $0.concertID == concertID
        }
    }
}

final class MockConcertPhotoStorage: ConcertPhotoStorage {
    var photos: [String: Data] = [:]
    var shouldFailSave = false
    var deletedPhotoFilenames: [String] = []
    var shouldFailDelete = false

    func savePhoto(_ data: Data) throws -> String {
        if shouldFailSave {
            throw MockStorageError.simulatedFailure
        }
        let filename = UUID().uuidString + ".jpg"
        photos[filename] = data
        return filename
    }

    func loadPhoto(named filename: String) throws -> Data {
        guard let data = photos[filename] else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        return data
    }

    func deletePhoto(named filename: String) throws {
        if shouldFailDelete {
            throw MockStorageError.simulatedFailure
        }

        deletedPhotoFilenames.append(filename)
        photos.removeValue(forKey: filename)
    }
}

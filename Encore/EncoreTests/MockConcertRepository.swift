//
//  MockConcertRepository.swift
//  EncoreTests
//
//  Created by Yufan on 26/9/2026.
//

import Foundation
@testable import Encore

final class MockConcertRepository: ConcertRepository {
    var concerts: [Concert] = []

    func saveConcert(_ concert: Concert) throws {
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
}

final class MockConcertMemoryRepository: ConcertMemoryRepository {
    var memories: [ConcertMoment] = []

    func saveMemory(_ memory: ConcertMoment) throws {
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
}

final class MockConcertPhotoStorage: ConcertPhotoStorage {
    var photos: [String: Data] = [:]

    func savePhoto(_ data: Data) throws -> String {
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
        photos.removeValue(forKey: filename)
    }
}

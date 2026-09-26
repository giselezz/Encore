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

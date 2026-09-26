//
//  ConcertRepository.swift
//  Encore
//
//  Created by Yufan on 26/9/2026.
//

import Foundation

protocol ConcertRepository {
    func saveConcert(_ concert: Concert) throws

    func fetchConcerts() throws -> [Concert]

    func fetchConcerts(
        from startDate: Date,
        to endDate: Date
    ) throws -> [Concert]
}

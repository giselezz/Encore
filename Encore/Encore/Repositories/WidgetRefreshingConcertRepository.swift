//
//  WidgetRefreshingConcertRepository.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//

import Foundation
import WidgetKit

struct WidgetRefreshingConcertRepository: ConcertRepository {
    private let repository: any ConcertRepository
    private let reloadWidget: () -> Void

    init(
        repository: any ConcertRepository,
        reloadWidget: @escaping () -> Void = {
            WidgetCenter.shared.reloadTimelines(
                ofKind: "EncoreWidget"
            )
        }
    ) {
        self.repository = repository
        self.reloadWidget = reloadWidget
    }

    func saveConcert(_ concert: Concert) throws {
        try repository.saveConcert(concert)
        reloadWidget()
    }

    func fetchConcerts() throws -> [Concert] {
        try repository.fetchConcerts()
    }

    func fetchConcerts(
        from startDate: Date,
        to endDate: Date
    ) throws -> [Concert] {
        try repository.fetchConcerts(
            from: startDate,
            to: endDate
        )
    }
}

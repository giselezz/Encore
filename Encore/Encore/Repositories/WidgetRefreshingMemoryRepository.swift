//
//  WidgetRefreshingMemoryRepository.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//

import Foundation
import WidgetKit

struct WidgetRefreshingMemoryRepository: ConcertMemoryRepository {
    private let repository: any ConcertMemoryRepository
    private let reloadWidget: () -> Void

    init(
        repository: any ConcertMemoryRepository,
        reloadWidget: @escaping () -> Void = {
            WidgetCenter.shared.reloadTimelines(
                ofKind: "EncoreWidget"
            )
        }
    ) {
        self.repository = repository
        self.reloadWidget = reloadWidget
    }

    func saveMemory(_ memory: ConcertMoment) throws {
        try repository.saveMemory(memory)
        reloadWidget()
    }

    func fetchMemories(
        for concertID: UUID
    ) throws -> [ConcertMoment] {
        try repository.fetchMemories(for: concertID)
    }
    
    func deleteMemory(id: UUID, concertID: UUID) throws {
        try repository.deleteMemory(
            id: id,
            concertID: concertID
        )

        reloadWidget()
    }
}

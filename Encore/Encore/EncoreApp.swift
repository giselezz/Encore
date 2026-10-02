//
//  EncoreApp.swift
//  Encore
//
//  Created by Yufan on 26/9/2026.
//

import SwiftUI

@main
struct EncoreApp: App {
    private let concertRepository = CoreDataConcertRepository(
        container: PersistenceController.shared.container
    )

    private let memoryRepository = CoreDataConcertMemoryRepository(
        container: PersistenceController.shared.container
    )

    var body: some Scene {
        WindowGroup {
            ConcertLibraryView(
                browseHistory: BrowseConcertHistory(
                    repository: concertRepository
                ),
                recordConcert: RecordAttendedConcert(
                    repository: concertRepository
                ),
                revisitMemories: RevisitConcertMemories(
                    repository: memoryRepository
                ),
                addMemory: AddConcertMemory(
                    repository: memoryRepository
                )
            )
        }
    }
}

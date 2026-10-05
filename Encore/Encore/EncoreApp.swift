//
//  EncoreApp.swift
//  Encore
//
//  Created by Yufan on 26/9/2026.
//

import SwiftUI

@main
struct EncoreApp: App {
    private let concertRepository = WidgetRefreshingConcertRepository(
        repository: CoreDataConcertRepository(
            container: PersistenceController.shared.container
        )
    )

    private let memoryRepository = WidgetRefreshingMemoryRepository(
        repository: CoreDataConcertMemoryRepository(
            container: PersistenceController.shared.container
        )
    )

    var body: some Scene {
        WindowGroup {
            if PersistenceController.shared.startupError != nil {
                ContentUnavailableView(
                    "Concert library unavailable",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text(
                        "Your journal couldn’t be opened. Close Encore and try again."
                    )
                )
            } else {
                ConcertLibraryView(
                    browseHistory: BrowseConcertHistory(
                        repository: concertRepository
                    ),
                    recordConcert: RecordAttendedConcert(
                        repository: concertRepository
                    ),
                    revisitMemories: RevisitConcertMemories(
                        repository: memoryRepository,
                        photoStorage: LocalConcertPhotoStorage()
                    ),
                    addMemory: AddConcertMemory(
                        repository: memoryRepository,
                        photoStorage: LocalConcertPhotoStorage()
                    ),
                    editConcert: EditConcert(
                        repository: concertRepository
                    )
                )
            }
        }
    }
}

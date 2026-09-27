//
//  EncoreApp.swift
//  Encore
//
//  Created by Yufan on 26/9/2026.
//

import SwiftUI

@main
struct EncoreApp: App {
    private let repository = CoreDataConcertRepository(
        container: PersistenceController.shared.container
    )

    var body: some Scene {
        WindowGroup {
            ConcertLibraryView(
                browseHistory: BrowseConcertHistory(
                    repository: repository
                ),
                recordConcert: RecordAttendedConcert(
                    repository: repository
                )
            )
        }
    }
}

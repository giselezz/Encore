//
//  ConcertLibraryViewModel.swift
//  Encore
//
//  Created by Yufan on 27/9/2026.
//

import Foundation
import Combine

@MainActor
final class ConcertLibraryViewModel: ObservableObject {
    @Published private(set) var concerts: [Concert] = []
    @Published var selectedYear: Int?
    @Published private(set) var errorMessage: String?

    private let browseHistory: BrowseConcertHistory

    init(browseHistory: BrowseConcertHistory) {
        self.browseHistory = browseHistory
    }

    func loadConcerts() {
        errorMessage = nil

        do {
            concerts = try browseHistory.execute(
                year: selectedYear
            )
        } catch let error as BrowseConcertHistory.HistoryError {
            concerts = []
            errorMessage = error.errorDescription
        } catch {
            concerts = []
            errorMessage =
                "Your concert history couldn’t be loaded. Please try again."
        }
    }
}

//
//  AddConcertViewModel.swift
//  Encore
//
//  Created by Yufan on 27/9/2026.
//

import Foundation
import Combine

@MainActor
final class AddConcertViewModel: ObservableObject {
    @Published var artistName = ""
    @Published var venueName = ""
    @Published var concertDate = Date()
    @Published var errorMessage: String?

    private let recordConcert: RecordAttendedConcert

    init(recordConcert: RecordAttendedConcert) {
        self.recordConcert = recordConcert
    }

    func saveConcert() -> Bool {
        errorMessage = nil

        do {
            _ = try recordConcert.execute(
                artistName: artistName,
                venueName: venueName,
                concertDate: concertDate
            )

            return true
        } catch let error as RecordAttendedConcert.RecordingError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage =
                "Your concert couldn’t be saved. Please try saving it again."
            return false
        }
    }
}

//
//  EditConcertViewModel.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//

import Foundation
import Combine

@MainActor
final class EditConcertViewModel: ObservableObject {
    @Published var artistName: String
    @Published var venueName: String
    @Published var concertDate: Date
    @Published var errorMessage: String?

    private let concert: Concert
    private let editConcert: EditConcert

    init(
        concert: Concert,
        editConcert: EditConcert
    ) {
        self.concert = concert
        self.editConcert = editConcert

        artistName = concert.artistName
        venueName = concert.venueName
        concertDate = concert.concertDate
    }

    func saveChanges() -> Concert? {
        errorMessage = nil

        do {
            return try editConcert.execute(
                concert: concert,
                artistName: artistName,
                venueName: venueName,
                concertDate: concertDate
            )
        } catch let error as EditConcert.EditingError {
            errorMessage = error.errorDescription
            return nil
        } catch {
            errorMessage =
                "Your changes couldn’t be saved. Please try again."
            return nil
        }
    }
}

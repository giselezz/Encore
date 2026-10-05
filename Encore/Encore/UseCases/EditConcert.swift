//
//  EditConcert.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//

import Foundation

struct EditConcert {
    let repository: any ConcertRepository

    enum EditingError: LocalizedError, Equatable {
        case missingArtist
        case missingVenue
        case futureConcertDate
        case savingFailed

        var errorDescription: String? {
            switch self {
            case .missingArtist:
                return "Enter the artist before saving."

            case .missingVenue:
                return "Enter the venue before saving."

            case .futureConcertDate:
                return "Choose today or an earlier concert date."

            case .savingFailed:
                return "Your changes couldn’t be saved. Please try again."
            }
        }
    }

    func execute(
        concert: Concert,
        artistName: String,
        venueName: String,
        concertDate: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> Concert {
        let artist = artistName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let venue = venueName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !artist.isEmpty else {
            throw EditingError.missingArtist
        }

        guard !venue.isEmpty else {
            throw EditingError.missingVenue
        }

        guard calendar.startOfDay(for: concertDate)
                <= calendar.startOfDay(for: now) else {
            throw EditingError.futureConcertDate
        }

        var updatedConcert = concert
        updatedConcert.artistName = artist
        updatedConcert.venueName = venue
        updatedConcert.concertDate = concertDate

        do {
            try repository.saveConcert(updatedConcert)
        } catch {
            throw EditingError.savingFailed
        }

        return updatedConcert
    }
}

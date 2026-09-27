//
//  RecordAttendedConcert.swift
//  Encore
//
//  Created by Yufan on 26/9/2026.
//

import Foundation

struct RecordAttendedConcert {
    let repository: any ConcertRepository

    enum RecordingError: LocalizedError, Equatable {
        case missingArtist
        case missingVenue
        case futureConcertDate
        case savingFailed

        var errorDescription: String? {
            switch self {
            case .missingArtist:
                return "Enter the artist you saw before saving this concert."
            case .missingVenue:
                return "Enter where the concert took place before saving."
            case .futureConcertDate:
                return "This journal records attended concerts. Choose today or an earlier date."
            case .savingFailed:
                return "Your concert couldn’t be saved. Please try saving it again."
            }
        }
    }

    func execute(
        artistName: String,
        venueName: String,
        concertDate: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> Concert {
        let artist = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        let venue = venueName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !artist.isEmpty else {
            throw RecordingError.missingArtist
        }

        guard !venue.isEmpty else {
            throw RecordingError.missingVenue
        }

        guard calendar.startOfDay(for: concertDate)
                <= calendar.startOfDay(for: now) else {
            throw RecordingError.futureConcertDate
        }

        let concert = Concert(
            id: UUID(),
            artistName: artist,
            venueName: venue,
            concertDate: concertDate,
            createdAt: now
        )

        do {
            try repository.saveConcert(concert)
        } catch {
            throw RecordingError.savingFailed
        }

        return concert
    }
}

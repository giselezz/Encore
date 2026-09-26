//
//  EncoreTests.swift
//  EncoreTests
//
//  Created by Yufan on 26/9/2026.
//

import XCTest
@testable import Encore

final class EncoreTests: XCTestCase {

    func testRecordingAnAttendedConcertSavesItsDetails() throws {
        let repository = MockConcertRepository()
        let useCase = RecordAttendedConcert(repository: repository)
        let concertDate = Date(timeIntervalSince1970: 1_700_000_000)
        let now = concertDate.addingTimeInterval(86_400)

        let concert = try useCase.execute(
            artistName: "  Taylor Swift  ",
            venueName: "  Accor Stadium  ",
            concertDate: concertDate,
            now: now
        )

        XCTAssertEqual(concert.artistName, "Taylor Swift")
        XCTAssertEqual(concert.venueName, "Accor Stadium")
        XCTAssertEqual(concert.concertDate, concertDate)
        XCTAssertEqual(concert.createdAt, now)
        XCTAssertEqual(repository.concerts, [concert])
    }
    
    func testRecordingConcertWithoutArtistIsRejected() {
        let repository = MockConcertRepository()
        let useCase = RecordAttendedConcert(repository: repository)
        let today = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertThrowsError(
            try useCase.execute(
                artistName: "   ",
                venueName: "Accor Stadium",
                concertDate: today,
                now: today
            )
        ) { error in
            XCTAssertEqual(
                error as? RecordAttendedConcert.RecordingError,
                .missingArtist
            )
        }

        XCTAssertTrue(repository.concerts.isEmpty)
    }

    func testRecordingConcertWithoutVenueIsRejected() {
        let repository = MockConcertRepository()
        let useCase = RecordAttendedConcert(repository: repository)
        let today = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertThrowsError(
            try useCase.execute(
                artistName: "Taylor Swift",
                venueName: "   ",
                concertDate: today,
                now: today
            )
        ) { error in
            XCTAssertEqual(
                error as? RecordAttendedConcert.RecordingError,
                .missingVenue
            )
        }

        XCTAssertTrue(repository.concerts.isEmpty)
    }

    func testRecordingTomorrowsConcertIsRejected() throws {
        let repository = MockConcertRepository()
        let useCase = RecordAttendedConcert(repository: repository)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        let today = calendar.startOfDay(
            for: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let tomorrow = try XCTUnwrap(
            calendar.date(byAdding: .day, value: 1, to: today)
        )

        XCTAssertThrowsError(
            try useCase.execute(
                artistName: "Taylor Swift",
                venueName: "Accor Stadium",
                concertDate: tomorrow,
                now: today,
                calendar: calendar
            )
        ) { error in
            XCTAssertEqual(
                error as? RecordAttendedConcert.RecordingError,
                .futureConcertDate
            )
        }

        XCTAssertTrue(repository.concerts.isEmpty)
    }

    func testRecordingConcertOnTodaysDateIsAllowed() throws {
        let repository = MockConcertRepository()
        let useCase = RecordAttendedConcert(repository: repository)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        let today = calendar.startOfDay(
            for: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let concert = try useCase.execute(
            artistName: "Taylor Swift",
            venueName: "Accor Stadium",
            concertDate: today,
            now: today,
            calendar: calendar
        )

        XCTAssertEqual(repository.concerts, [concert])
    }
}

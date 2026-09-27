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
    
    func testBrowsingYearIncludesOnlyConcertsWithinThatYear() throws {
        let repository = MockConcertRepository()
        let useCase = BrowseConcertHistory(repository: repository)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        let startOf2024 = try XCTUnwrap(
            calendar.date(
                from: DateComponents(year: 2024, month: 1, day: 1)
            )
        )
        let startOf2025 = try XCTUnwrap(
            calendar.date(
                from: DateComponents(year: 2025, month: 1, day: 1)
            )
        )

        func concert(on date: Date) -> Concert {
            Concert(
                id: UUID(),
                artistName: "Test Artist",
                venueName: "Test Venue",
                concertDate: date,
                createdAt: startOf2025
            )
        }

        let previousYear = concert(
            on: startOf2024.addingTimeInterval(-1)
        )
        let firstOfYear = concert(on: startOf2024)
        let lastOfYear = concert(
            on: startOf2025.addingTimeInterval(-1)
        )
        let followingYear = concert(on: startOf2025)

        repository.concerts = [
            previousYear,
            firstOfYear,
            lastOfYear,
            followingYear
        ]

        let results = try useCase.execute(
            year: 2024,
            now: startOf2025,
            calendar: calendar
        )

        XCTAssertEqual(results, [lastOfYear, firstOfYear])
    }
    
    func testBrowsingFutureConcertYearIsRejected() throws {
        let repository = MockConcertRepository()
        let useCase = BrowseConcertHistory(repository: repository)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        let now = try XCTUnwrap(
            calendar.date(
                from: DateComponents(year: 2025, month: 6, day: 1)
            )
        )

        XCTAssertThrowsError(
            try useCase.execute(
                year: 2026,
                now: now,
                calendar: calendar
            )
        ) { error in
            XCTAssertEqual(
                error as? BrowseConcertHistory.HistoryError,
                .futureYear
            )
        }
    }

    func testBrowsingInvalidConcertYearIsRejected() {
        let repository = MockConcertRepository()
        let useCase = BrowseConcertHistory(repository: repository)

        XCTAssertThrowsError(
            try useCase.execute(year: 0)
        ) { error in
            XCTAssertEqual(
                error as? BrowseConcertHistory.HistoryError,
                .invalidYear
            )
        }
    }
}

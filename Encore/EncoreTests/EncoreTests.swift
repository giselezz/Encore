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
    
    func testAddingWrittenMemorySavesItToItsConcert() throws {
        let repository = MockConcertMemoryRepository()
        let useCase = AddConcertMemory(repository: repository, photoStorage: MockConcertPhotoStorage())
        let concertID = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let memory = try useCase.execute(
            concertID: concertID,
            caption: "  Everyone sang the final chorus together.  ",
            now: now
        )

        XCTAssertEqual(memory.concertID, concertID)
        XCTAssertEqual(
            memory.caption,
            "Everyone sang the final chorus together."
        )
        XCTAssertNil(memory.photoFilename)
        XCTAssertEqual(memory.createdAt, now)
        XCTAssertEqual(repository.memories, [memory])
    }

    func testAddingMemoryWithoutTextOrPhotoIsRejected() {
        let repository = MockConcertMemoryRepository()
        let useCase = AddConcertMemory(repository: repository, photoStorage: MockConcertPhotoStorage())

        XCTAssertThrowsError(
            try useCase.execute(
                concertID: UUID(),
                caption: " \n ",
                photoData: nil
            )
        ) { error in
            XCTAssertEqual(
                error as? AddConcertMemory.MemoryError,
                .emptyMemory
            )
        }

        XCTAssertTrue(repository.memories.isEmpty)
    }
    
    func testAddingPhotoOnlyMemoryStoresPhotoAndItsFilename() throws {
        let repository = MockConcertMemoryRepository()
        let photoStorage = MockConcertPhotoStorage()
        let useCase = AddConcertMemory(
            repository: repository,
            photoStorage: photoStorage
        )
        let concertID = UUID()
        let photoData = Data([1, 2, 3])

        let memory = try useCase.execute(
            concertID: concertID,
            caption: "",
            photoData: photoData
        )

        let filename = try XCTUnwrap(memory.photoFilename)

        XCTAssertNil(memory.caption)
        XCTAssertEqual(memory.concertID, concertID)
        XCTAssertEqual(photoStorage.photos[filename], photoData)
        XCTAssertEqual(repository.memories, [memory])
    }
    
    func testFailedMemorySaveRemovesItsNewPhoto() {
        let repository = MockConcertMemoryRepository()
        repository.shouldFailSave = true

        let photoStorage = MockConcertPhotoStorage()
        let useCase = AddConcertMemory(
            repository: repository,
            photoStorage: photoStorage
        )

        XCTAssertThrowsError(
            try useCase.execute(
                concertID: UUID(),
                caption: "The encore",
                photoData: Data([1, 2, 3])
            )
        ) { error in
            XCTAssertEqual(
                error as? AddConcertMemory.MemoryError,
                .savingFailed
            )
        }

        XCTAssertTrue(repository.memories.isEmpty)
        XCTAssertTrue(photoStorage.photos.isEmpty)
        XCTAssertEqual(photoStorage.deletedPhotoFilenames.count, 1)
    }

    func testFailedPhotoSaveDoesNotCreateMemory() {
        let repository = MockConcertMemoryRepository()
        let photoStorage = MockConcertPhotoStorage()
        photoStorage.shouldFailSave = true

        let useCase = AddConcertMemory(
            repository: repository,
            photoStorage: photoStorage
        )

        XCTAssertThrowsError(
            try useCase.execute(
                concertID: UUID(),
                caption: "My favourite song",
                photoData: Data([1, 2, 3])
            )
        ) { error in
            XCTAssertEqual(
                error as? AddConcertMemory.MemoryError,
                .photoSavingFailed
            )
        }

        XCTAssertTrue(repository.memories.isEmpty)
        XCTAssertTrue(photoStorage.photos.isEmpty)
        XCTAssertTrue(photoStorage.deletedPhotoFilenames.isEmpty)
    }

    func testRevisitingConcertShowsOnlyItsMemoriesNewestFirst() throws {
        let repository = MockConcertMemoryRepository()
        let concertID = UUID()
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let earlier = ConcertMoment(
            id: UUID(),
            concertID: concertID,
            caption: "Opening song",
            photoFilename: nil,
            createdAt: date
        )

        let later = ConcertMoment(
            id: UUID(),
            concertID: concertID,
            caption: "Final encore",
            photoFilename: nil,
            createdAt: date.addingTimeInterval(60)
        )

        let anotherConcert = ConcertMoment(
            id: UUID(),
            concertID: UUID(),
            caption: "A different show",
            photoFilename: nil,
            createdAt: date
        )

        repository.memories = [earlier, anotherConcert, later]

        let useCase = RevisitConcertMemories(
            repository: repository,
            photoStorage: MockConcertPhotoStorage()
        )

        let results = try useCase.execute(concertID: concertID)

        XCTAssertEqual(results, [later, earlier])
    }
    
    func testSavingMemoryRefreshesWidgetAfterSaving() throws {
        let repository = MockConcertMemoryRepository()
        var refreshCount = 0

        let memory = ConcertMoment(
            id: UUID(),
            concertID: UUID(),
            caption: "An unforgettable concert",
            photoFilename: nil,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let refreshingRepository = WidgetRefreshingMemoryRepository(
            repository: repository,
            reloadWidget: {
                // The memory must already be saved before refreshing.
                XCTAssertEqual(repository.memories, [memory])
                refreshCount += 1
            }
        )

        try refreshingRepository.saveMemory(memory)

        XCTAssertEqual(repository.memories, [memory])
        XCTAssertEqual(refreshCount, 1)
    }

    func testFailedMemorySaveDoesNotRefreshWidget() {
        let repository = MockConcertMemoryRepository()
        repository.shouldFailSave = true
        var refreshCount = 0

        let refreshingRepository = WidgetRefreshingMemoryRepository(
            repository: repository,
            reloadWidget: {
                refreshCount += 1
            }
        )

        let memory = ConcertMoment(
            id: UUID(),
            concertID: UUID(),
            caption: "An unforgettable concert",
            photoFilename: nil,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertThrowsError(
            try refreshingRepository.saveMemory(memory)
        ) { error in
            guard case MockStorageError.simulatedFailure = error else {
                XCTFail("Expected the original storage error, got \(error)")
                return
            }
        }

        XCTAssertTrue(repository.memories.isEmpty)
        XCTAssertEqual(refreshCount, 0)
    }
    
    func testEditingConcertUpdatesDetailsWithoutCreatingDuplicate() throws {
        let repository = MockConcertRepository()
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let original = Concert(
            id: UUID(),
            artistName: "Original artist",
            venueName: "Original venue",
            concertDate: date,
            createdAt: date
        )

        repository.concerts = [original]

        let useCase = EditConcert(repository: repository)
        let correctedDate = date.addingTimeInterval(-86_400)

        let updated = try useCase.execute(
            concert: original,
            artistName: "  Bad Bunny  ",
            venueName: "  Engie Stadium  ",
            concertDate: correctedDate,
            now: date
        )

        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.createdAt, original.createdAt)
        XCTAssertEqual(updated.artistName, "Bad Bunny")
        XCTAssertEqual(updated.venueName, "Engie Stadium")
        XCTAssertEqual(updated.concertDate, correctedDate)

        // Exactly one concert remains, containing the updated details.
        XCTAssertEqual(repository.concerts, [updated])
    }

    func testEditingConcertRejectsInvalidDetails() {
        let repository = MockConcertRepository()
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let original = Concert(
            id: UUID(),
            artistName: "Bad Bunny",
            venueName: "Engie Stadium",
            concertDate: date,
            createdAt: date
        )

        repository.concerts = [original]
        let useCase = EditConcert(repository: repository)

        let invalidChanges: [
            (
                artist: String,
                venue: String,
                date: Date,
                expectedError: EditConcert.EditingError
            )
        ] = [
            (
                artist: " \n ",
                venue: "Engie Stadium",
                date: date,
                expectedError: .missingArtist
            ),
            (
                artist: "Bad Bunny",
                venue: " \n ",
                date: date,
                expectedError: .missingVenue
            ),
            (
                artist: "Bad Bunny",
                venue: "Engie Stadium",
                date: date.addingTimeInterval(86_400),
                expectedError: .futureConcertDate
            )
        ]

        for change in invalidChanges {
            XCTAssertThrowsError(
                try useCase.execute(
                    concert: original,
                    artistName: change.artist,
                    venueName: change.venue,
                    concertDate: change.date,
                    now: date
                )
            ) { error in
                XCTAssertEqual(
                    error as? EditConcert.EditingError,
                    change.expectedError
                )
            }

            // Invalid input must leave the saved concert unchanged.
            XCTAssertEqual(repository.concerts, [original])
        }
    }

    func testEditingConcertReportsSaveFailure() {
        let repository = MockConcertRepository()
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let original = Concert(
            id: UUID(),
            artistName: "Bad Bunny",
            venueName: "Original venue",
            concertDate: date,
            createdAt: date
        )

        repository.concerts = [original]
        repository.shouldFailSave = true

        let useCase = EditConcert(repository: repository)

        XCTAssertThrowsError(
            try useCase.execute(
                concert: original,
                artistName: "Bad Bunny",
                venueName: "Corrected venue",
                concertDate: date,
                now: date
            )
        ) { error in
            XCTAssertEqual(
                error as? EditConcert.EditingError,
                .savingFailed
            )
        }

        XCTAssertEqual(repository.concerts, [original])
    }
}


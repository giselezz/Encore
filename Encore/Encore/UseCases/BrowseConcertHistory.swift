//
//  BrowseConcertHistory.swift
//  Encore
//
//  Created by Yufan on 27/9/2026.
//

import Foundation

struct BrowseConcertHistory {
    let repository: any ConcertRepository

    enum HistoryError: LocalizedError, Equatable {
        case invalidYear
        case futureYear
        case loadingFailed

        var errorDescription: String? {
            switch self {
            case .invalidYear:
                return "Enter a valid year to find your past concerts."
            case .futureYear:
                return "Your concert history contains attended shows. Choose this year or an earlier year."
            case .loadingFailed:
                return "Your concert history couldn’t be loaded. Please try again."
            }
        }
    }

    func execute(
        year: Int? = nil,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> [Concert] {
        guard let year else {
            do {
                return try repository.fetchConcerts()
            } catch {
                throw HistoryError.loadingFailed
            }
        }

        guard year > 0 else {
            throw HistoryError.invalidYear
        }

        guard year <= calendar.component(.year, from: now) else {
            throw HistoryError.futureYear
        }

        guard
            let startDate = calendar.date(
                from: DateComponents(year: year, month: 1, day: 1)
            ),
            let endDate = calendar.date(
                byAdding: .year,
                value: 1,
                to: startDate
            )
        else {
            throw HistoryError.invalidYear
        }

        do {
            return try repository.fetchConcerts(
                from: startDate,
                to: endDate
            )
        } catch {
            throw HistoryError.loadingFailed
        }
    }
}

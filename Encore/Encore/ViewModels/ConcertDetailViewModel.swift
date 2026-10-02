//
//  ConcertDetailViewModel.swift
//  Encore
//
//  Created by Yufan on 2/10/2026.
//

import Foundation
import Combine

@MainActor
final class ConcertDetailViewModel: ObservableObject {
    @Published private(set) var memories: [ConcertMoment] = []
    @Published private(set) var errorMessage: String?

    let concert: Concert

    private let revisitMemories: RevisitConcertMemories

    init(
        concert: Concert,
        revisitMemories: RevisitConcertMemories
    ) {
        self.concert = concert
        self.revisitMemories = revisitMemories
    }

    func loadMemories() {
        errorMessage = nil

        do {
            memories = try revisitMemories.execute(
                concertID: concert.id
            )
        } catch let error as RevisitConcertMemories.MemoryHistoryError {
            memories = []
            errorMessage = error.errorDescription
        } catch {
            memories = []
            errorMessage =
                "Your concert memories couldn’t be loaded. Please try again."
        }
    }
}

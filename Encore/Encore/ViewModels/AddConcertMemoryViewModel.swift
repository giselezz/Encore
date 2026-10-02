//
//  AddConcertMemoryViewModel.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import Foundation
import Combine

@MainActor
final class AddConcertMemoryViewModel: ObservableObject {
    @Published var caption = ""
    @Published private(set) var errorMessage: String?

    private let concertID: UUID
    private let addMemory: AddConcertMemory

    init(
        concertID: UUID,
        addMemory: AddConcertMemory
    ) {
        self.concertID = concertID
        self.addMemory = addMemory
    }

    func saveMemory() -> Bool {
        errorMessage = nil

        do {
            _ = try addMemory.execute(
                concertID: concertID,
                caption: caption
            )

            return true
        } catch let error as AddConcertMemory.MemoryError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage =
                "Your concert memory couldn’t be saved. Please try again."
            return false
        }
    }
}

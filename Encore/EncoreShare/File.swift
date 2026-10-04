//
//  File.swift
//  EncoreShare
//
//  Created by Yufan on 4/10/2026.
//

import Foundation
import Combine
import UIKit

@MainActor
final class ShareConcertViewModel: ObservableObject {
    @Published private(set) var concerts: [Concert] = []
    @Published var selectedConcertID: UUID?
    @Published var caption = ""
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSaving = false
    @Published private(set) var hasSaved = false

    let photoPreview: UIImage

    private let photoData: Data
    private let browseHistory: BrowseConcertHistory
    private let addMemory: AddConcertMemory

    init(
        photoData: Data,
        photoPreview: UIImage,
        browseHistory: BrowseConcertHistory,
        addMemory: AddConcertMemory
    ) {
        self.photoData = photoData
        self.photoPreview = photoPreview
        self.browseHistory = browseHistory
        self.addMemory = addMemory
    }

    var canSave: Bool {
        selectedConcertID != nil && !isSaving && !hasSaved
    }

    func loadConcerts() {
        errorMessage = nil

        do {
            concerts = try browseHistory.execute()

            if let selectedConcertID,
               concerts.contains(where: {
                   $0.id == selectedConcertID
               }) {
                return
            }

            selectedConcertID = concerts.count == 1
                ? concerts.first?.id
                : nil
        } catch {
            concerts = []
            selectedConcertID = nil
            errorMessage =
                "Your concert list couldn’t be loaded. Try again, or open Encore to check your library."
        }
    }

    func saveMemory() -> Bool {
        guard !isSaving, !hasSaved else {
            return false
        }

        guard let concertID = selectedConcertID,
              concerts.contains(where: { $0.id == concertID })
        else {
            errorMessage = "Choose the concert this photo belongs to."
            return false
        }

        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        do {
            _ = try addMemory.execute(
                concertID: concertID,
                caption: caption,
                photoData: photoData
            )

            hasSaved = true
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

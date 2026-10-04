//
//  AddConcertMemoryViewModel.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import Foundation
import Combine
import SwiftUI
import PhotosUI
import UIKit

@MainActor
final class AddConcertMemoryViewModel: ObservableObject {
    @Published var caption = ""
    @Published private(set) var errorMessage: String?
    @Published private(set) var photoPreview: UIImage?
    @Published private(set) var isLoadingPhoto = false

    private var photoData: Data?

    private let concertID: UUID
    private let addMemory: AddConcertMemory

    init(
        concertID: UUID,
        addMemory: AddConcertMemory
    ) {
        self.concertID = concertID
        self.addMemory = addMemory
    }

    func loadPhoto(from selection: PhotosPickerItem?) async {
        guard !Task.isCancelled else { return }

        errorMessage = nil
        photoData = nil
        photoPreview = nil

        guard let selection else {
            isLoadingPhoto = false
            return
        }

        isLoadingPhoto = true

        defer {
            if !Task.isCancelled {
                isLoadingPhoto = false
            }
        }

        do {
            let data = try await selection.loadTransferable(
                type: Data.self
            )

            guard !Task.isCancelled else { return }

            guard
                let data,
                let image = UIImage(data: data)
            else {
                errorMessage =
                    "This photo couldn’t be opened. Please choose another."
                return
            }

            photoData = data
            photoPreview = image
        } catch {
            guard !Task.isCancelled else { return }

            errorMessage =
                "This photo couldn’t be loaded. Check your connection and select it again."
        }
    }

    func saveMemory() -> Bool {
        guard !isLoadingPhoto else {
            errorMessage = "Please wait for your photo to finish loading."
            return false
        }

        errorMessage = nil

        do {
            _ = try addMemory.execute(
                concertID: concertID,
                caption: caption,
                photoData: photoData
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

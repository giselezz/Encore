//
//  ConcertDetailViewModel.swift
//  Encore
//
//  Created by Yufan on 2/10/2026.
//

import Foundation
import Combine
import UIKit

@MainActor
final class ConcertDetailViewModel: ObservableObject {
    @Published private(set) var memories: [ConcertMoment] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var photos: [UUID: UIImage] = [:]
    @Published private(set) var photoErrors: [UUID: String] = [:]

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
        photos = [:]
        photoErrors = [:]

        do {
            memories = try revisitMemories.execute(
                concertID: concert.id
            )
        } catch let error as RevisitConcertMemories.MemoryHistoryError {
            memories = []
            errorMessage = error.errorDescription
            return
        } catch {
            memories = []
            errorMessage =
                "Your concert memories couldn’t be loaded. Please try again."
            return
        }

        for memory in memories {
            do {
                guard let data = try revisitMemories.loadPhoto(
                    for: memory
                ) else {
                    continue
                }

                guard let image = UIImage(data: data) else {
                    throw RevisitConcertMemories
                        .MemoryHistoryError.photoLoadingFailed
                }

                photos[memory.id] = image
            } catch {
                photoErrors[memory.id] =
                    "This concert photo couldn’t be opened. Tap Try Again to reload it."
            }
        }
    }
}

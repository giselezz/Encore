//
//  FeaturedConcertMemory.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//

import Foundation

struct FeaturedConcertMemory: Identifiable, Equatable {
    let id: UUID
    let concertID: UUID
    let artistName: String
    let venueName: String
    let concertDate: Date
    let caption: String?
    let photoFilename: String?
}

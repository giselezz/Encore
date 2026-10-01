//
//  ConcertMoment.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import Foundation

struct ConcertMoment: Identifiable, Equatable {
    let id: UUID
    let concertID: UUID
    var caption: String?
    var photoFilename: String?
    let createdAt: Date
}

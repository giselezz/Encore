//
//  SharedConcertPhoto.swift
//  Encore
//
//  Created by Yufan on 4/10/2026.
//

import Foundation

struct SharedConcertPhoto: Identifiable, Codable, Equatable {
    let id: UUID
    let receivedAt: Date
}

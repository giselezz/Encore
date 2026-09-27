//
//  Concert.swift
//  Encore
//
//  Created by Yufan on 26/9/2026.
//

import Foundation

struct Concert: Identifiable, Equatable {
    let id: UUID
    var artistName: String
    var venueName: String
    var concertDate: Date
    let createdAt: Date
}

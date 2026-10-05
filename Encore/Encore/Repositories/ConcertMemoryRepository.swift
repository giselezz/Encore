//
//  ConcertMemoryRepository.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import Foundation

protocol ConcertMemoryRepository {
    func saveMemory(_ memory: ConcertMoment) throws

    func fetchMemories(
        for concertID: UUID
    ) throws -> [ConcertMoment]
    
    func deleteMemory(id: UUID, concertID: UUID) throws
}

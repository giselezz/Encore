//
//  FeaturedConcertMemoryRepository.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//

protocol FeaturedConcertMemoryRepository {
    func fetchLatestMemory() throws -> FeaturedConcertMemory?
}

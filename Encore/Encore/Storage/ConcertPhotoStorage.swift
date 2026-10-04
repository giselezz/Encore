//
//  ConcertPhotoStorage.swift
//  Encore
//
//  Created by Yufan on 2/10/2026.
//

import Foundation

protocol ConcertPhotoStorage {
    func savePhoto(_ data: Data) throws -> String
    func loadPhoto(named filename: String) throws -> Data
    func deletePhoto(named filename: String) throws
}

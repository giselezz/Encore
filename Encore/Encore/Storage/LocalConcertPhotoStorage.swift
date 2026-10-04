//
//  LocalConcertPhotoStorage.swift
//  Encore
//
//  Created by Yufan on 2/10/2026.
//

import Foundation
import UIKit

struct LocalConcertPhotoStorage: ConcertPhotoStorage {
    private let customDirectory: URL?

    init(directory: URL? = nil) {
        customDirectory = directory
    }

    enum PhotoError: LocalizedError {
        case unreadablePhoto
        case invalidFilename

        var errorDescription: String? {
            switch self {
            case .unreadablePhoto:
                return "This photo couldn’t be opened. Please choose another photo."
            case .invalidFilename:
                return "This saved photo couldn’t be located. Please add the photo again."
            }
        }
    }

    func savePhoto(_ data: Data) throws -> String {
        guard
            let image = UIImage(data: data),
            let jpegData = image.jpegData(compressionQuality: 0.8)
        else {
            throw PhotoError.unreadablePhoto
        }

        let filename = UUID().uuidString + ".jpg"
        let destination = try photoURL(named: filename)

        try jpegData.write(
            to: destination,
            options: .atomic
        )

        return filename
    }

    func loadPhoto(named filename: String) throws -> Data {
        let url = try photoURL(named: filename)
        return try Data(contentsOf: url)
    }

    func deletePhoto(named filename: String) throws {
        let url = try photoURL(named: filename)
        try FileManager.default.removeItem(at: url)
    }

    private func photoURL(named filename: String) throws -> URL {
        guard
            filename.hasSuffix(".jpg"),
            UUID(
                uuidString: String(filename.dropLast(4))
            ) != nil
        else {
            throw PhotoError.invalidFilename
        }

        let directory: URL

        if let customDirectory {
            directory = customDirectory

            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } else {
            directory = try EncoreSharedStorage.photoDirectoryURL()
        }

        return directory.appendingPathComponent(filename)
    }
}

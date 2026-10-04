//
//  EncoreSharedStorage.swift
//  Encore
//
//  Created by Yufan on 4/10/2026.
//

import Foundation

enum EncoreSharedStorage {
    static let appGroupIdentifier = "group.com.yufan.Encore"

    enum StorageError: LocalizedError {
        case sharedContainerUnavailable

        var errorDescription: String? {
            "Encore’s shared storage is unavailable. Check that Encore and EncoreShare use the same App Group."
        }
    }

    static func databaseURL() throws -> URL {
        let directory = try sharedDirectory(named: "Database")

        return directory.appendingPathComponent("Encore.sqlite")
    }

    static func photoDirectoryURL() throws -> URL {
        try sharedDirectory(named: "ConcertPhotos")
    }

    private static func sharedDirectory(named name: String) throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier:
                appGroupIdentifier
        ) else {
            throw StorageError.sharedContainerUnavailable
        }

        let directory = container.appendingPathComponent(
            name,
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }
    
    static func migrateExistingPhotos() throws {
        let destination = try photoDirectoryURL()
        let marker = destination.appendingPathComponent(
            ".legacyPhotosCopied"
        )

        let files = FileManager.default

        guard !files.fileExists(atPath: marker.path) else {
            return
        }

        let original = URL.applicationSupportDirectory
            .appendingPathComponent(
                "ConcertPhotos",
                isDirectory: true
            )

        if files.fileExists(atPath: original.path) {
            let photos = try files.contentsOfDirectory(
                at: original,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

            for photo in photos where photo.pathExtension == "jpg" {
                let sharedPhoto = destination.appendingPathComponent(
                    photo.lastPathComponent
                )

                if !files.fileExists(atPath: sharedPhoto.path) {
                    let data = try Data(contentsOf: photo)

                    try data.write(
                        to: sharedPhoto,
                        options: .atomic
                    )
                }
            }
        }

        try Data().write(to: marker, options: .atomic)
    }
}

//
//  SharedPhotoInbox.swift
//  Encore
//
//  Created by Yufan on 4/10/2026.
//

import Foundation

struct SharedPhotoInbox {
    static let appGroupIdentifier = "group.com.yufan.Encore"

    enum InboxError: LocalizedError {
        case sharedStorageUnavailable
        case emptyPhoto
        case damagedItem

        var errorDescription: String? {
            switch self {
            case .sharedStorageUnavailable:
                return "Encore’s shared inbox is unavailable. Open Encore and try sharing again."
            case .emptyPhoto:
                return "This photo couldn’t be received. Please choose it again."
            case .damagedItem:
                return "A shared photo couldn’t be opened. Please share the original photo again."
            }
        }
    }

    func savePhoto(_ data: Data) throws -> SharedConcertPhoto {
        guard !data.isEmpty else {
            throw InboxError.emptyPhoto
        }

        let inbox = try inboxURL()
        let photo = SharedConcertPhoto(
            id: UUID(),
            receivedAt: Date()
        )

        let stagingFolder = inbox.appendingPathComponent(
            ".pending-\(photo.id.uuidString)",
            isDirectory: true
        )

        let destination = inbox.appendingPathComponent(
            photo.id.uuidString,
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: stagingFolder,
            withIntermediateDirectories: true
        )

        defer {
            // Remove temporary files if the operation did not finish.
            // After a successful move, this folder no longer exists.
            try? FileManager.default.removeItem(at: stagingFolder)
        }

        try data.write(
            to: stagingFolder.appendingPathComponent("photo.data"),
            options: .atomic
        )

        let metadata = try JSONEncoder().encode(photo)

        try metadata.write(
            to: stagingFolder.appendingPathComponent("metadata.json"),
            options: .atomic
        )

        try FileManager.default.moveItem(
            at: stagingFolder,
            to: destination
        )

        return photo
    }

    func fetchPhotos() throws -> [SharedConcertPhoto] {
        let folders = try FileManager.default.contentsOfDirectory(
            at: inboxURL(),
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )

        let photos = try folders.compactMap {
            folder -> SharedConcertPhoto? in

            guard let folderID = UUID(
                uuidString: folder.lastPathComponent
            ) else {
                return nil
            }

            let metadata = try Data(
                contentsOf: folder.appendingPathComponent("metadata.json")
            )

            let photo = try JSONDecoder().decode(
                SharedConcertPhoto.self,
                from: metadata
            )

            guard photo.id == folderID else {
                throw InboxError.damagedItem
            }

            return photo
        }

        return photos.sorted {
            $0.receivedAt > $1.receivedAt
        }
    }

    func loadPhoto(id: UUID) throws -> Data {
        let folder = try photoFolder(id: id)

        return try Data(
            contentsOf: folder.appendingPathComponent("photo.data")
        )
    }

    func removePhoto(id: UUID) throws {
        let folder = try photoFolder(id: id)
        try FileManager.default.removeItem(at: folder)
    }

    private func photoFolder(id: UUID) throws -> URL {
        try inboxURL().appendingPathComponent(
            id.uuidString,
            isDirectory: true
        )
    }

    private func inboxURL() throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier:
                Self.appGroupIdentifier
        ) else {
            throw InboxError.sharedStorageUnavailable
        }

        let inbox = container.appendingPathComponent(
            "SharedPhotoInbox",
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: inbox,
            withIntermediateDirectories: true
        )

        return inbox
    }
}

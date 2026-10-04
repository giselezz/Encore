//
//  ShareViewController.swift
//  EncoreShare
//
//  Created by Yufan on 4/10/2026.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers
import ImageIO

@MainActor
final class ShareViewController: UIViewController {
    private let messageLabel = UILabel()
    private let loadingStack = UIStackView()

    private var loadingProgress: Progress?
    private var persistence: PersistenceController?
    private var hasFinished = false

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        showLoadingScreen()
        loadSharedPhoto()
    }

    private func showLoadingScreen() {
        messageLabel.text = "Loading your concert photo…"
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = .preferredFont(forTextStyle: .body)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(
            self,
            action: #selector(cancelSharing),
            for: .touchUpInside
        )

        loadingStack.axis = .vertical
        loadingStack.spacing = 20
        loadingStack.translatesAutoresizingMaskIntoConstraints = false
        loadingStack.addArrangedSubview(messageLabel)
        loadingStack.addArrangedSubview(cancelButton)

        view.addSubview(loadingStack)

        NSLayoutConstraint.activate([
            loadingStack.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),
            loadingStack.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            ),
            loadingStack.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
            )
        ])
    }

    private func loadSharedPhoto() {
        let items = extensionContext?.inputItems
            as? [NSExtensionItem] ?? []

        let images = items
            .flatMap { $0.attachments ?? [] }
            .filter {
                $0.hasItemConformingToTypeIdentifier(
                    UTType.image.identifier
                )
            }

        guard images.count == 1, let provider = images.first else {
            messageLabel.text =
                "Please cancel and share one photo at a time."
            return
        }

        guard let typeIdentifier =
            provider.registeredTypeIdentifiers.first(where: {
                UTType($0)?.conforms(to: .image) == true
            }) else {
            messageLabel.text =
                "This photo format isn’t supported. Cancel and choose another photo."
            return
        }

        loadingProgress = provider.loadDataRepresentation(
            forTypeIdentifier: typeIdentifier
        ) { [weak self] data, error in
            Task { @MainActor [weak self] in
                guard let self, !self.hasFinished else { return }

                guard error == nil, let data, !data.isEmpty else {
                    self.messageLabel.text =
                        "The photo couldn’t be loaded. Cancel, check your connection, and share it again."
                    return
                }

                self.prepareComposer(from: data)
            }
        }
    }

    private func prepareComposer(from data: Data) {
        // Resize before displaying to limit extension memory use.
        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            sourceOptions
        ) else {
            messageLabel.text =
                "This photo couldn’t be opened. Cancel and choose another photo."
            return
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1600,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions
        ) else {
            messageLabel.text =
                "This photo couldn’t be prepared. Cancel and choose another photo."
            return
        }

        let image = UIImage(cgImage: thumbnail)

        guard let preparedData = image.jpegData(
            compressionQuality: 0.9
        ) else {
            messageLabel.text =
                "This photo couldn’t be prepared. Cancel and choose another photo."
            return
        }

        // Only the main app migrates old data.
        let persistence = PersistenceController(
            migrateExistingStore: false
        )
        self.persistence = persistence

        if let error = persistence.startupError {
            print("Share extension storage failed: \(error)")
            messageLabel.text =
                "Your concert library couldn’t be opened. Cancel, open Encore once, then share your photo again."
            return
        }

        let concertRepository = CoreDataConcertRepository(
            container: persistence.container
        )

        let memoryRepository = CoreDataConcertMemoryRepository(
            container: persistence.container
        )

        let viewModel = ShareConcertViewModel(
            photoData: preparedData,
            photoPreview: image,
            browseHistory: BrowseConcertHistory(
                repository: concertRepository
            ),
            addMemory: AddConcertMemory(
                repository: memoryRepository,
                photoStorage: LocalConcertPhotoStorage()
            )
        )

        let screen = ShareConcertView(
            viewModel: viewModel,
            onSaved: { [weak self] in
                self?.finishSharing()
            },
            onCancel: { [weak self] in
                self?.cancelSharing()
            }
        )

        let hostingController = UIHostingController(
            rootView: screen
        )

        addChild(hostingController)
        loadingStack.removeFromSuperview()

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            hostingController.view.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            hostingController.view.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            hostingController.view.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])

        hostingController.didMove(toParent: self)
    }

    private func finishSharing() {
        guard !hasFinished else { return }

        hasFinished = true
        extensionContext?.completeRequest(
            returningItems: [],
            completionHandler: nil
        )
    }

    @objc private func cancelSharing() {
        guard !hasFinished else { return }

        hasFinished = true
        loadingProgress?.cancel()

        extensionContext?.cancelRequest(
            withError: NSError(
                domain: NSCocoaErrorDomain,
                code: NSUserCancelledError
            )
        )
    }
}

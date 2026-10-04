//
//  AddConcertMemoryView.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import SwiftUI
import PhotosUI

struct AddConcertMemoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddConcertMemoryViewModel
    @State private var selectedPhoto: PhotosPickerItem?

    private let artistName: String
    private let onSaved: () -> Void

    init(
        concert: Concert,
        addMemory: AddConcertMemory,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: AddConcertMemoryViewModel(
                concertID: concert.id,
                addMemory: addMemory
            )
        )
        artistName = concert.artistName
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    if let image = viewModel.photoPreview {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .accessibilityLabel("Selected concert photo")
                    }

                    if viewModel.isLoadingPhoto {
                        ProgressView("Loading photo…")
                    }

                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        Label(
                            viewModel.photoPreview == nil
                                ? "Add Photo"
                                : "Change Photo",
                            systemImage: "photo"
                        )
                    }

                    if selectedPhoto != nil {
                        Button("Remove Photo", role: .destructive) {
                            selectedPhoto = nil
                        }
                    }
                }
                
                Section {
                    TextEditor(text: $viewModel.caption)
                        .frame(minHeight: 160)
                        .accessibilityLabel("Concert memory")
                } header: {
                    Text("Your memory of \(artistName)")
                } footer: {
                    Text(
                        "What stood out? A favourite song, a surprise, or who you went with."
                    )
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .task(id: selectedPhoto) {
                await viewModel.loadPhoto(from: selectedPhoto)
            }
            .navigationTitle("Add Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.saveMemory() {
                            onSaved()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isLoadingPhoto)
                }
            }
        }
    }
}

#Preview {
    let persistence = PersistenceController(inMemory: true)

    let concertRepository = CoreDataConcertRepository(
        container: persistence.container
    )
    let memoryRepository = CoreDataConcertMemoryRepository(
        container: persistence.container
    )

    let concert = Concert(
        id: UUID(),
        artistName: "Bad Bunny",
        venueName: "Engie Stadium",
        concertDate: Date(),
        createdAt: Date()
    )

    if let previewError = {
        do {
            try concertRepository.saveConcert(concert)
            return nil as String?
        } catch {
            return error.localizedDescription
        }
    }() {
        Text("Preview setup failed: \(previewError)")
    } else {
        AddConcertMemoryView(
            concert: concert,
            addMemory: AddConcertMemory(
                repository: memoryRepository, 
                photoStorage: LocalConcertPhotoStorage()
            ),
            onSaved: {}
        )
    }
}

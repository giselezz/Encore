//
//  AddConcertMemoryView.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import SwiftUI

struct AddConcertMemoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddConcertMemoryViewModel

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

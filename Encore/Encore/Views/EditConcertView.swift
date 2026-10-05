//
//  EditConcertView.swift
//  Encore
//
//  Created by Yufan on 5/10/2026.
//


import SwiftUI

struct EditConcertView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditConcertViewModel

    private let onSaved: (Concert) -> Void

    init(
        concert: Concert,
        editConcert: EditConcert,
        onSaved: @escaping (Concert) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: EditConcertViewModel(
                concert: concert,
                editConcert: editConcert
            )
        )

        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Concert details") {
                    TextField(
                        "Artist or band",
                        text: $viewModel.artistName
                    )

                    TextField(
                        "Venue",
                        text: $viewModel.venueName
                    )

                    DatePicker(
                        "Concert date",
                        selection: $viewModel.concertDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Concert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let updatedConcert = viewModel.saveChanges() {
                            onSaved(updatedConcert)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
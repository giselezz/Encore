//
//  AddConcertView.swift
//  Encore
//
//  Created by Yufan on 27/9/2026.
//

import SwiftUI

struct AddConcertView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddConcertViewModel

    private let onSaved: () -> Void

    init(
        recordConcert: RecordAttendedConcert,
        onSaved: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: AddConcertViewModel(
                recordConcert: recordConcert
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
            .navigationTitle("Add Concert")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.saveConcert() {
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
    AddConcertView(
        recordConcert: RecordAttendedConcert(
            repository: CoreDataConcertRepository(
                container: PersistenceController.preview.container
            )
        ),
        onSaved: {}
    )
}

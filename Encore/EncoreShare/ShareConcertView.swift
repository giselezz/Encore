//
//  SwiftUIView.swift
//  EncoreShare
//
//  Created by Yufan on 4/10/2026.
//

import SwiftUI

struct ShareConcertView: View {
    @ObservedObject var viewModel: ShareConcertViewModel

    let onSaved: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image(uiImage: viewModel.photoPreview)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 260)
                        .accessibilityLabel("Photo to save")
                }

                Section("Concert") {
                    if viewModel.concerts.isEmpty {
                        if viewModel.errorMessage == nil {
                            Text(
                                "Create a concert in Encore first, then share this photo again."
                            )
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        Picker(
                            "Choose Concert",
                            selection: $viewModel.selectedConcertID
                        ) {
                            Text("Select a concert")
                                .tag(UUID?.none)

                            ForEach(viewModel.concerts) { concert in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(concert.artistName)

                                    Text(
                                        "\(concert.venueName) · \(concert.concertDate.formatted(date: .abbreviated, time: .omitted))"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .tag(Optional(concert.id))
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }

                Section("Caption · Optional") {
                    TextField(
                        "What do you want to remember?",
                        text: $viewModel.caption,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)

                        if viewModel.concerts.isEmpty {
                            Button("Reload Concerts") {
                                viewModel.loadConcerts()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Save to Encore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(viewModel.isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.saveMemory() {
                            onSaved()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear {
                viewModel.loadConcerts()
            }
        }
    }
}

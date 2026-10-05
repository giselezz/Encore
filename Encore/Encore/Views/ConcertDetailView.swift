//
//  SwiftUIView.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import SwiftUI

struct ConcertDetailView: View {
    @StateObject private var viewModel: ConcertDetailViewModel
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddMemory = false
    @State private var showingEditConcert = false
    @State private var showingDeleteConcertConfirmation = false
    @State private var deleteConcertAfterSheetCloses = false

    private let editConcert: EditConcert
    private let addMemory: AddConcertMemory
    private let onDeleted: () -> Void

    init(
        concert: Concert,
        revisitMemories: RevisitConcertMemories,
        addMemory: AddConcertMemory,
        editConcert: EditConcert,
        deleteMemory: DeleteConcertMemory,
        deleteConcert: DeleteConcert,
        onDeleted: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: ConcertDetailViewModel(
                concert: concert,
                revisitMemories: revisitMemories,
                deleteMemory: deleteMemory,
                deleteConcert: deleteConcert
            )
        )

        self.addMemory = addMemory
        self.editConcert = editConcert
        self.onDeleted = onDeleted
    }

    var body: some View {
        Form {
            if !viewModel.hasDeletedConcert {
                Section("Concert details") {
                    LabeledContent(
                        "Artist",
                        value: viewModel.concert.artistName
                    )

                    LabeledContent(
                        "Venue",
                        value: viewModel.concert.venueName
                    )

                    LabeledContent("Date") {
                        Text(
                            viewModel.concert.concertDate,
                            format: .dateTime.day().month().year()
                        )
                    }
                }

                if let message = viewModel.deletionErrorMessage {
                    Section("Memory removal") {
                        Text(message)
                            .foregroundStyle(.red)

                        Button("Retry") {
                            viewModel.retryMemoryDeletion()
                        }
                    }
                }

                Section("Memories") {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)

                        Button("Try Again") {
                            viewModel.loadMemories()
                        }
                    } else if viewModel.memories.isEmpty {
                        Text("Save a moment you want to remember.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.memories) { memory in
                            VStack(alignment: .leading, spacing: 8) {
                                if let image = viewModel.photos[memory.id] {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 280)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 12)
                                        )
                                        .accessibilityLabel(
                                            "Concert memory photo"
                                        )
                                } else if let photoError =
                                    viewModel.photoErrors[memory.id] {
                                    Text(photoError)
                                        .foregroundStyle(.secondary)

                                    Button("Try Again") {
                                        viewModel.loadMemories()
                                    }
                                }

                                if let caption = memory.caption {
                                    Text(caption)
                                }

                                Text(
                                    memory.createdAt,
                                    format: .dateTime.day().month().year()
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .swipeActions(
                                edge: .trailing,
                                allowsFullSwipe: false
                            ) {
                                Button(role: .destructive) {
                                    viewModel.removeMemory(memory)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .disabled(viewModel.pendingDeletion != nil)
                            }
                        }
                    }

                    Button {
                        showingAddMemory = true
                    } label: {
                        Label("Add Memory", systemImage: "plus")
                    }
                }
            }

            Section {
                if let message = viewModel.concertDeletionErrorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                }

                if viewModel.hasDeletedConcert {
                    Button("Retry Photo Cleanup") {
                        if viewModel.retryConcertPhotoCleanup() {
                            dismiss()
                        }
                    }
                } else {
                    Button(role: .destructive) {
                        showingDeleteConcertConfirmation = true
                    } label: {
                        Label("Delete Concert", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(viewModel.concert.artistName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(
            isPresented: $showingDeleteConcertConfirmation,
            onDismiss: {
                guard deleteConcertAfterSheetCloses else { return }
                deleteConcertAfterSheetCloses = false

                if viewModel.removeConcert() {
                    dismiss()
                }
            }
        ) {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "trash")
                        .font(.system(size: 32))
                        .foregroundStyle(.red)
                        .padding(.top, 12)

                    Text("Delete this concert?")
                        .font(.title2.bold())

                    Text(
                        "This will permanently delete this concert and all its memories and saved photos. This cannot be undone."
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        Button(role: .destructive) {
                            deleteConcertAfterSheetCloses = true
                            showingDeleteConcertConfirmation = false
                        } label: {
                            Text("Delete")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Button {
                            deleteConcertAfterSheetCloses = false
                            showingDeleteConcertConfirmation = false
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                    }
                    .padding(.top, 4)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onDisappear {
            if viewModel.hasDeletedConcert {
                onDeleted()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditConcert = true
                }
                .disabled(viewModel.hasDeletedConcert)
            }
        }
        .sheet(isPresented: $showingEditConcert) {
            EditConcertView(
                concert: viewModel.concert,
                editConcert: editConcert
            ) { updatedConcert in
                viewModel.updateConcert(updatedConcert)
            }
        }
        .sheet(isPresented: $showingAddMemory) {
            AddConcertMemoryView(
                concert: viewModel.concert,
                addMemory: addMemory
            ) {
                viewModel.loadMemories()
            }
        }
        .onAppear {
            viewModel.loadMemories()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.loadMemories()
            }
        }
    }
}

#Preview {
    let repository = CoreDataConcertMemoryRepository(
        container: PersistenceController.preview.container
    )

    NavigationStack {
        ConcertDetailView(
            concert: Concert(
                id: UUID(),
                artistName: "Taylor Swift",
                venueName: "Accor Stadium",
                concertDate: Date(),
                createdAt: Date()
            ),
            revisitMemories: RevisitConcertMemories(
                repository: repository, 
                photoStorage: LocalConcertPhotoStorage()
            ),
            addMemory: AddConcertMemory(
                repository: repository, 
                photoStorage: LocalConcertPhotoStorage()
            ),
            editConcert: EditConcert(
                repository: CoreDataConcertRepository(
                    container: PersistenceController.preview.container
                )
            ), 
            deleteMemory: DeleteConcertMemory(
                repository: repository,
                photoStorage: LocalConcertPhotoStorage()
            ), 
            deleteConcert: DeleteConcert(
                repository: CoreDataConcertRepository(
                    container: PersistenceController.preview.container
                ),
                photoStorage: LocalConcertPhotoStorage()
            )
        )
    }
}

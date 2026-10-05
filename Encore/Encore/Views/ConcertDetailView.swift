//
//  SwiftUIView.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import SwiftUI

struct ConcertDetailView: View {
    @StateObject private var viewModel: ConcertDetailViewModel
    @State private var showingAddMemory = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingEditConcert = false

    private let editConcert: EditConcert
    private let addMemory: AddConcertMemory

    init(
        concert: Concert,
        revisitMemories: RevisitConcertMemories,
        addMemory: AddConcertMemory,
        editConcert: EditConcert,
        deleteMemory: DeleteConcertMemory
    ) {
        _viewModel = StateObject(
            wrappedValue: ConcertDetailViewModel(
                concert: concert,
                revisitMemories: revisitMemories,
                deleteMemory: deleteMemory
            )
        )

        self.addMemory = addMemory
        self.editConcert = editConcert
    }

    var body: some View {
        Form {
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
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .accessibilityLabel("Concert memory photo")
                            } else if let photoError = viewModel.photoErrors[memory.id] {
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
        .navigationTitle(viewModel.concert.artistName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditConcert = true
                }
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
            )
        )
    }
}

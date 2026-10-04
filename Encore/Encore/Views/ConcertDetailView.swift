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

    private let addMemory: AddConcertMemory

    init(
        concert: Concert,
        revisitMemories: RevisitConcertMemories,
        addMemory: AddConcertMemory
    ) {
        _viewModel = StateObject(
            wrappedValue: ConcertDetailViewModel(
                concert: concert,
                revisitMemories: revisitMemories
            )
        )
        self.addMemory = addMemory
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
                repository: repository
            ),
            addMemory: AddConcertMemory(
                repository: repository, 
                photoStorage: LocalConcertPhotoStorage()
            )
        )
    }
}

//
//  ConcertLibraryView.swift
//  Encore
//
//  Created by Yufan on 27/9/2026.
//

import SwiftUI

struct ConcertLibraryView: View {
    @StateObject private var viewModel: ConcertLibraryViewModel
    @State private var showingAddConcert = false

    private let recordConcert: RecordAttendedConcert

    init(
        browseHistory: BrowseConcertHistory,
        recordConcert: RecordAttendedConcert
    ) {
        _viewModel = StateObject(
            wrappedValue: ConcertLibraryViewModel(
                browseHistory: browseHistory
            )
        )
        self.recordConcert = recordConcert
    }

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text(errorMessage)
                            .multilineTextAlignment(.center)

                        Button("Try Again") {
                            viewModel.loadConcerts()
                        }
                    }
                    .padding()
                } else if viewModel.concerts.isEmpty {
                    ContentUnavailableView(
                        "Your concert journal starts here",
                        systemImage: "music.mic",
                        description: Text(
                            "Tap + to record a concert you attended."
                        )
                    )
                } else {
                    List(viewModel.concerts) { concert in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(concert.artistName)
                                .font(.headline)

                            Text(concert.venueName)
                                .font(.subheadline)

                            Text(
                                concert.concertDate,
                                format: .dateTime.day().month().year()
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("My Concerts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddConcert = true
                    } label: {
                        Label("Add Concert", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddConcert) {
                AddConcertView(recordConcert: recordConcert) {
                    viewModel.loadConcerts()
                }
            }
            .onAppear {
                viewModel.loadConcerts()
            }
        }
    }
}

#Preview {
    let repository = CoreDataConcertRepository(
        container: PersistenceController.preview.container
    )

    ConcertLibraryView(
        browseHistory: BrowseConcertHistory(repository: repository),
        recordConcert: RecordAttendedConcert(repository: repository)
    )
}

//
//  SwiftUIView.swift
//  Encore
//
//  Created by Yufan on 1/10/2026.
//

import SwiftUI

struct ConcertDetailView: View {
    let concert: Concert

    var body: some View {
        Form {
            Section("Concert details") {
                LabeledContent("Artist", value: concert.artistName)
                LabeledContent("Venue", value: concert.venueName)

                LabeledContent("Date") {
                    Text(
                        concert.concertDate,
                        format: .dateTime.day().month().year()
                    )
                }
            }
        }
        .navigationTitle(concert.artistName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ConcertDetailView(
            concert: Concert(
                id: UUID(),
                artistName: "Taylor Swift",
                venueName: "Accor Stadium",
                concertDate: Date(),
                createdAt: Date()
            )
        )
    }
}

//
//  EncoreWidget.swift
//  EncoreWidget
//
//  Created by Yufan on 4/10/2026.
//

import WidgetKit
import SwiftUI
import UIKit
import ImageIO

struct MemoryWidgetEntry: TimelineEntry {
    let date: Date
    let memory: FeaturedConcertMemory?
    let photo: UIImage?
    let message: String?

    static var sample: MemoryWidgetEntry {
        MemoryWidgetEntry(
            date: Date(),
            memory: FeaturedConcertMemory(
                id: UUID(),
                concertID: UUID(),
                artistName: "Bad Bunny",
                venueName: "Engie Stadium",
                concertDate: Date(),
                caption: "A night to remember",
                photoFilename: nil
            ),
            photo: nil,
            message: nil
        )
    }
}

struct MemoryWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MemoryWidgetEntry {
        .sample
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (MemoryWidgetEntry) -> Void
    ) {
        completion(context.isPreview ? .sample : loadEntry())
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<MemoryWidgetEntry>) -> Void
    ) {
        let entry = loadEntry()
        let nextRefresh = Date().addingTimeInterval(60 * 60)

        completion(
            Timeline(
                entries: [entry],
                policy: .after(nextRefresh)
            )
        )
    }

    private func loadEntry() -> MemoryWidgetEntry {
        let persistence = PersistenceController(
            migrateExistingStore: false
        )

        guard persistence.startupError == nil else {
            return messageEntry(
                "Open Encore to set up your concert memories."
            )
        }

        let repository = CoreDataFeaturedConcertMemoryRepository(
            container: persistence.container
        )

        do {
            guard let memory = try repository.fetchLatestMemory() else {
                return messageEntry(
                    "Add a concert memory in Encore to see it here."
                )
            }

            return MemoryWidgetEntry(
                date: Date(),
                memory: memory,
                photo: loadThumbnail(named: memory.photoFilename),
                message: nil
            )
        } catch {
            return messageEntry(
                "Unable to load your memory. Open Encore to try again."
            )
        }
    }

    private func messageEntry(_ message: String) -> MemoryWidgetEntry {
        MemoryWidgetEntry(
            date: Date(),
            memory: nil,
            photo: nil,
            message: message
        )
    }

    private func loadThumbnail(named filename: String?) -> UIImage? {
        guard
            let filename,
            filename.hasSuffix(".jpg"),
            UUID(uuidString: String(filename.dropLast(4))) != nil
        else {
            return nil
        }

        do {
            let directory = try EncoreSharedStorage.photoDirectoryURL()
            let url = directory.appendingPathComponent(filename)

            let sourceOptions: [CFString: Any] = [
                kCGImageSourceShouldCache: false
            ]

            guard let source = CGImageSourceCreateWithURL(
                url as CFURL,
                sourceOptions as CFDictionary
            ) else {
                return nil
            }

            let thumbnailOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 600
            ]

            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                thumbnailOptions as CFDictionary
            ) else {
                return nil
            }

            return UIImage(cgImage: thumbnail)
        } catch {
            return nil
        }
    }
}

struct MemoryWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: MemoryWidgetEntry

    var body: some View {
        Group {
            if let memory = entry.memory {
                if family == .systemMedium {
                    mediumLayout(memory)
                } else {
                    smallLayout(memory)
                }
            } else {
                emptyLayout
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .leading
        )
        .containerBackground(for: .widget) {
            Color(.secondarySystemBackground)
        }
    }

    private func smallLayout(
        _ memory: FeaturedConcertMemory
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            photo(width: nil, height: 64)

            Text(memory.artistName)
                .font(.headline)
                .lineLimit(1)

            Text(memory.concertDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func mediumLayout(
        _ memory: FeaturedConcertMemory
    ) -> some View {
        HStack(spacing: 12) {
            photo(width: 110, height: 120)

            VStack(alignment: .leading, spacing: 6) {
                Text("ENCORE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(memory.artistName)
                    .font(.headline)
                    .lineLimit(1)

                Text(memory.venueName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(memory.concertDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let caption = memory.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func photo(
        width: CGFloat?,
        height: CGFloat
    ) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.accentColor.opacity(0.12))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .overlay {
                if let image = entry.photo {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityLabel("Concert memory")
    }

    private var emptyLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Encore", systemImage: "music.note")
                .font(.headline)

            Text(entry.message ?? "Open Encore to view your memories.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct EncoreWidget: Widget {
    let kind = "EncoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MemoryWidgetProvider()
        ) { entry in
            MemoryWidgetView(entry: entry)
        }
        .configurationDisplayName("Concert Memories")
        .description("Revisit your most recently added concert memory.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    EncoreWidget()
} timeline: {
    MemoryWidgetEntry.sample
}

#Preview(as: .systemMedium) {
    EncoreWidget()
} timeline: {
    MemoryWidgetEntry.sample
}

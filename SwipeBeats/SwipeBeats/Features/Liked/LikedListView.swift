//
//  LikedListView.swift
//  SwipeBeats
//
//  Created by Vu Minh Khoi Ha on 21.01.26.
//

import SwiftUI
import SwiftData

struct LikedListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var audio: AudioPlayerService

    @Query(sort: \LikedTrackEntity.createdAt, order: .reverse)
    private var likedTracks: [LikedTrackEntity]

    @State private var detailTrack: Track?

    private var likesStore: LikedTracksStore {
        LikedTracksStore(context: modelContext)
    }

    var body: some View {
        Group {
            if likedTracks.isEmpty {
                ContentUnavailableView(
                    "Noch keine Likes",
                    systemImage: "heart",
                    description: Text("Swipe dich durch Tracks und like deine Favoriten. Sie werden hier gespeichert.")
                )
            } else {
                List {
                    ForEach(likedTracks) { item in
                        Button {
                            detailTrack = makeTrack(from: item)
                        } label: {
                            row(item)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .sheet(item: $detailTrack) { track in
            NavigationStack {
                TrackDetailView(track: track, audio: audio)
            }
        }
    }

    private func row(_ item: LikedTrackEntity) -> some View {
        HStack(spacing: 12) {
            artwork(item)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.trackName)
                    .font(.headline)
                    .lineLimit(1)

                Text(item.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func artwork(_ item: LikedTrackEntity) -> some View {
        if let urlString = item.artworkURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholderArtwork
                @unknown default:
                    placeholderArtwork
                }
            }
        } else {
            placeholderArtwork
        }
    }

    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.secondary.opacity(0.2))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
    }

    private func openCollectionLink(for item: LikedTrackEntity) {
        guard
            let urlString = item.collectionViewURL,
            let url = URL(string: urlString)
        else { return }

        openURL(url)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            likesStore.unlike(trackId: likedTracks[index].trackId)
        }
    }

    private func makeTrack(from item: LikedTrackEntity) -> Track {
        Track(
            id: item.trackId,
            artistName: item.artistName,
            trackName: item.trackName,
            artworkURL: item.artworkURL.flatMap(URL.init(string:)),
            previewURL: item.previewURL.flatMap(URL.init(string:)),
            collectionViewURL: item.collectionViewURL.flatMap(URL.init(string:)),
            primaryGenreName: nil
        )
    }
}

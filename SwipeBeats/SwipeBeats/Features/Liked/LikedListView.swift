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
    @EnvironmentObject private var audio: AudioPlayerService
    @EnvironmentObject private var toastManager: ToastManager

    let onOpenArtistInExplore: (String) -> Void

    @Query(sort: \LikedTrackEntity.createdAt, order: .reverse)
    private var likedTracks: [LikedTrackEntity]

    @State private var detailTrack: Track?

    private var likesStore: LikedTracksStore {
        LikedTracksStore(context: modelContext)
    }

    var body: some View {
        Group {
            if likedTracks.isEmpty {
                ContentUnavailableView {
                    Label("Noch keine Likes", systemImage: "heart")
                } description: {
                    Text("Swipe dich durch Tracks und like deine Favoriten. Sie werden hier gespeichert.")
                }
            } else {
                List {
                    ForEach(likedTracks) { item in
                        Button {
                            detailTrack = makeTrack(from: item)
                        } label: {
                            row(item)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.trackName) von \(item.artistName)")
                        .accessibilityHint("Öffnet die Track-Details")
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if item.previewURL.flatMap(URL.init(string:)) != nil {
                                Button {
                                    playPreview(from: item)
                                } label: {
                                    Label("Vorschau", systemImage: "play.fill")
                                }
                                .tint(.teal)
                            }
                        }
                        .contextMenu {
                            Button {
                                detailTrack = makeTrack(from: item)
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }

                            if item.previewURL.flatMap(URL.init(string:)) != nil {
                                Button {
                                    playPreview(from: item)
                                } label: {
                                    Label("Vorschau abspielen", systemImage: "play.fill")
                                }
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(item: $detailTrack) { track in
            NavigationStack {
                TrackDetailView(
                    track: track,
                    audio: audio,
                    onOpenArtist: { artistName in
                        detailTrack = nil
                        onOpenArtistInExplore(artistName)
                    }
                )
            }
        }
    }

    private func row(_ item: LikedTrackEntity) -> some View {
        let hasPreview = item.previewURL.flatMap(URL.init(string:)) != nil

        return HStack(spacing: 12) {
            artwork(item)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.pink, in: Circle())
                        .offset(x: 4, y: 4)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.trackName)
                    .font(.headline)
                    .lineLimit(1)

                Text(item.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Label(hasPreview ? "30 Sek. Vorschau" : "Keine Vorschau", systemImage: hasPreview ? "play.circle.fill" : "speaker.slash.fill")
                    .font(.caption)
                    .foregroundStyle(hasPreview ? .teal : .secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: hasPreview ? "play.fill" : "chevron.right")
                .font(.caption)
                .foregroundStyle(hasPreview ? .teal : .secondary)
        }
        .padding(.vertical, 4)
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
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.secondary.opacity(0.2))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            likesStore.unlike(trackId: likedTracks[index].trackId)
        }
        if !offsets.isEmpty {
            toastManager.show("Aus Favoriten entfernt", icon: "heart.slash")
        }
    }

    private func playPreview(from item: LikedTrackEntity) {
        let track = makeTrack(from: item)
        guard let previewURL = track.previewURL else { return }

        audio.setNowPlaying(track: track)
        audio.toggle(url: previewURL)
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

import SwiftUI

struct MiniPlayerBar: View {
    @ObservedObject var audio: AudioPlayerService
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(audio.nowPlayingTitle?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Unbekannt")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let artist = audio.nowPlayingArtist?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
                    Text(artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .layoutPriority(1)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }

            Spacer()

            Button {
                audio.toggle(url: nil)
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)

            Button {
                audio.stop()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

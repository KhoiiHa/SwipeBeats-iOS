import SwiftUI

struct MiniPlayerBar: View {
    @ObservedObject var audio: AudioPlayerService
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(audio.nowPlayingTitle?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Unbekannt")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(audio.nowPlayingArtist?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? " ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .layoutPriority(1)

            Spacer()

            Button {
                audio.toggle(url: nil)
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)

            Button {
                audio.stop()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            onTap?()
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

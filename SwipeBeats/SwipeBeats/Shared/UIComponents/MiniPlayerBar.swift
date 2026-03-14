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
            .accessibilityLabel(audio.isPlaying ? "Wiedergabe pausieren" : "Wiedergabe starten")
            .accessibilityHint("Steuert die aktuelle Vorschau")

            Button {
                audio.stop()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Wiedergabe stoppen")
            .accessibilityHint("Beendet die aktuelle Vorschau")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint("Öffnet den aktuell gespielten Track")
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

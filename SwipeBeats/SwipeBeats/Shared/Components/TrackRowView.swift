import SwiftUI

struct TrackRowView: View {
    let track: Track

    var body: some View {
        HStack(spacing: 12) {
            AsyncArtworkImage(url: track.artworkURL)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(track.trackName)
                    .font(.headline)
                    .lineLimit(1)

                Text(track.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
    }
}


//
//  LikedTrackEntity.swift
//  SwipeBeats
//
//  Created by Vu Minh Khoi Ha on 21.01.26.
//

import Foundation
import SwiftData

@Model
final class LikedTrackEntity {
    // Internal unique id for SwiftData (separate from iTunes trackId)
    @Attribute(.unique) var uuid: UUID

    // iTunes identifiers + display fields
    var trackId: Int
    var trackName: String
    var artistName: String

    // Store URLs as Strings for persistence simplicity
    var artworkURL: String?
    var previewURL: String?
    var collectionViewURL: String?

    var createdAt: Date

    init(
        uuid: UUID = UUID(),
        trackId: Int,
        trackName: String,
        artistName: String,
        artworkURL: String? = nil,
        previewURL: String? = nil,
        collectionViewURL: String? = nil,
        createdAt: Date = .now
    ) {
        self.uuid = uuid
        self.trackId = trackId
        self.trackName = trackName
        self.artistName = artistName
        self.artworkURL = artworkURL
        self.previewURL = previewURL
        self.collectionViewURL = collectionViewURL
        self.createdAt = createdAt
    }
}

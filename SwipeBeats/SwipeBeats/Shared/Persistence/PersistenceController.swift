//
//  PersistenceController.swift
//  SwipeBeats
//
//  Created by Vu Minh Khoi Ha on 21.01.26.
//

import Foundation
import SwiftData

enum PersistenceController {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            LikedTrackEntity.self,
            PlaylistEntity.self
        ])

        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: inMemory
        )

        return try ModelContainer(for: schema, configurations: configuration)
    }
}

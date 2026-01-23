//
//  SwipeBeatsApp.swift
//  SwipeBeats
//
//  Created by Vu Minh Khoi Ha on 20.01.26.
//

import SwiftUI
import SwiftData

@main
struct SwipeBeatsApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: LikedTrackEntity.self)
    }
}

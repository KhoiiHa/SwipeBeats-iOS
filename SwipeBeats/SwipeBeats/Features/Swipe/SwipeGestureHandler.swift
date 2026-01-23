import Foundation
import SwiftUI

struct SwipeGestureHandler {

    enum Decision {
        case like
        case skip
        case none
    }

    let threshold: CGFloat

    init(threshold: CGFloat = 120) {
        self.threshold = threshold
    }

    func decision(for translation: CGSize) -> Decision {
        if translation.width >= threshold { return .like }
        if translation.width <= -threshold { return .skip }
        return .none
    }

    func rotation(for translation: CGSize) -> Angle {
        // leichte Rotation, capped
        let capped = max(min(translation.width, 220), -220)
        return .degrees(Double(capped / 22))
    }

    func overlayOpacity(for translation: CGSize) -> Double {
        // 0...1 abhängig von Distanz zum threshold
        let progress = min(abs(translation.width) / threshold, 1)
        return Double(progress)
    }
}

import Foundation
import Combine

struct AppToast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let icon: String?
}

@MainActor
final class ToastManager: ObservableObject {
    @Published var toast: AppToast?

    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, icon: String? = nil) {
        dismissTask?.cancel()
        toast = AppToast(message: message, icon: icon)

        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }

    func hide() {
        dismissTask?.cancel()
        dismissTask = nil
        toast = nil
    }
}

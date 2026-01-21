import Foundation

enum AppError: LocalizedError, Equatable {
    case network
    case decoding
    case unknown

    var errorDescription: String? {
        switch self {
        case .network: return "Netzwerkfehler. Bitte versuche es erneut."
        case .decoding: return "Daten konnten nicht verarbeitet werden."
        case .unknown: return "Unbekannter Fehler."
        }
    }
}

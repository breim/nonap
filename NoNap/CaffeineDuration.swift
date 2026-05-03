import Foundation

enum CaffeineDuration: String, CaseIterable, Identifiable {
    case indefinite
    case fifteenMinutes
    case thirtyMinutes
    case oneHour

    var id: String { rawValue }

    var title: String {
        switch self {
        case .indefinite:
            "Indefinitely"
        case .fifteenMinutes:
            "15 minutes"
        case .thirtyMinutes:
            "30 minutes"
        case .oneHour:
            "1 hour"
        }
    }

    var seconds: Int? {
        switch self {
        case .indefinite:
            nil
        case .fifteenMinutes:
            15 * 60
        case .thirtyMinutes:
            30 * 60
        case .oneHour:
            60 * 60
        }
    }
}


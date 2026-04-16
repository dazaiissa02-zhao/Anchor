import Foundation

enum SessionStatus: String, Codable {
    case running
    case paused
    case reviewing
    case completed
    case abandoned
}

enum ThoughtStatus: String, Codable {
    case parked
    case discarded
    case later
    case convertedToTask
}

struct FocusSession: Codable, Identifiable {
    var id: String
    var title: String
    var nextAction: String
    var durationMinutes: Int
    var startedAt: Date
    var endedAt: Date?
    var status: SessionStatus
    var outputNote: String
    var totalPausedSeconds: TimeInterval
    var pausedAt: Date?
    var midpointSent: Bool
    var lastIntervalReminderAt: Date
    var lastCaptureAt: Date?
    var lastStrongReminderAt: Date?
}

struct CapturedThought: Codable, Identifiable {
    var id: String
    var sessionId: String
    var content: String
    var createdAt: Date
    var status: ThoughtStatus
    var convertedTaskId: String?
}

struct AnchorTask: Codable, Identifiable {
    var id: String
    var title: String
    var sourceThoughtId: String
    var createdAt: Date
    var status: String
}

struct AnchorState: Codable {
    var currentSessionId: String?
    var sessions: [FocusSession]
    var thoughts: [CapturedThought]
    var tasks: [AnchorTask]

    static let empty = AnchorState(currentSessionId: nil, sessions: [], thoughts: [], tasks: [])
}

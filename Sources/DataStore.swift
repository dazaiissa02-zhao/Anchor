import Foundation

final class DataStore {
    var state: AnchorState
    let fileURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = support.appendingPathComponent("Anchor", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("anchor-data.json")
        state = DataStore.load(from: fileURL)
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(state) {
            try? data.write(to: fileURL, options: [.atomic])
        }
    }

    func currentSession() -> FocusSession? {
        guard let id = state.currentSessionId else { return nil }
        return state.sessions.first { $0.id == id }
    }

    func currentSessionIndex() -> Int? {
        guard let id = state.currentSessionId else { return nil }
        return state.sessions.firstIndex { $0.id == id }
    }

    func thoughts(for sessionId: String) -> [CapturedThought] {
        state.thoughts.filter { $0.sessionId == sessionId }
    }

    func inboxThoughts() -> [CapturedThought] {
        state.thoughts.filter { $0.sessionId == "inbox" }
    }

    private static func load(from url: URL) -> AnchorState {
        guard let data = try? Data(contentsOf: url) else { return .empty }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(AnchorState.self, from: data)) ?? .empty
    }
}

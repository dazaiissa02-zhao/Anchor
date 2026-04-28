import AppKit
import UserNotifications

extension AppDelegate {
    func fireReminder(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: makeId("notification"), content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.refreshAll(message: granted ? "通知已开启。" : "通知没有开启。")
            }
        }
    }

    func refreshAll(message: String) {
        updateStatusIcon()
        rebuildMenu()
        mainWindow.refresh(message: message)
        todayReviewWindow?.refresh()
        inboxWindow?.refresh()
    }

    func showMainWindow(surface: MainSurface? = nil) {
        if let surface {
            mainSurface = surface
        }
        statusPopover?.performClose(nil)
        mainWindow.refresh(message: "")
        mainWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showCapture() {
        statusPopover?.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        captureWindow.present()
    }

    func showTodayReview() {
        reviewReferenceDate = Calendar.current.startOfDay(for: Date())
        showMainWindow(surface: .todayReview)
    }

    func showInbox() {
        showMainWindow(surface: .inbox)
    }

    func showFocusSurface(message: String = "") {
        mainSurface = .focus
        refreshAll(message: message)
        showMainWindow()
    }

    func todayStats(for date: Date = Date()) -> TodayStats {
        let calendar = Calendar.current
        let sessions = store.state.sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: date) }
        let ids = Set(sessions.map(\.id))
        let thoughts = store.state.thoughts.filter { ids.contains($0.sessionId) }
        let outputs = sessions.filter { !$0.outputNote.isEmpty }.count
        let seconds = sessions.reduce(TimeInterval(0)) { total, session in
            total + elapsedSeconds(session)
        }
        if sessions.isEmpty {
            let title = calendar.isDateInToday(date) ? "还没有锚定" : "这一天还没有记录"
            return TodayStats(sessionsText: title, detailText: "从一件事开始", totalSeconds: 0, sessions: sessions, thoughts: thoughts, outputs: outputs)
        }
        return TodayStats(
            sessionsText: "\(sessions.count) 段 · \(formatDurationCompact(seconds))",
            detailText: "\(thoughts.count) 条停靠 · \(outputs) 个产出",
            totalSeconds: seconds,
            sessions: sessions,
            thoughts: thoughts,
            outputs: outputs
        )
    }

    func moveThoughtToInbox(_ thoughtId: String) {
        guard let index = store.state.thoughts.firstIndex(where: { $0.id == thoughtId }) else { return }
        store.state.thoughts[index].sessionId = "inbox"
        store.state.thoughts[index].status = .parked
        store.state.thoughts[index].convertedTaskId = nil
        store.save()
        refreshAll(message: "")
    }

    func startSessionFromThought(_ thoughtId: String, durationMinutes: Int = 25) {
        if store.currentSession() != nil {
            convertThoughtToPendingAnchor(thoughtId)
            return
        }
        guard let index = store.state.thoughts.firstIndex(where: { $0.id == thoughtId }) else { return }
        let content = store.state.thoughts[index].content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        store.state.thoughts[index].status = .convertedToTask
        if store.state.thoughts[index].convertedTaskId == nil {
            let task = AnchorTask(id: makeId("task"), title: content, sourceThoughtId: thoughtId, createdAt: Date(), status: "open")
            store.state.tasks.append(task)
            store.state.thoughts[index].convertedTaskId = task.id
        }
        store.save()

        mainSurface = .focus
        startSession(title: content, nextAction: "", durationMinutes: durationMinutes)
    }

    func deleteThought(_ thoughtId: String) {
        store.state.thoughts.removeAll { $0.id == thoughtId }
        store.save()
        refreshAll(message: "")
    }

    func convertThoughtToPendingAnchor(_ thoughtId: String) {
        guard let index = store.state.thoughts.firstIndex(where: { $0.id == thoughtId }) else { return }
        let content = store.state.thoughts[index].content
        pendingAnchorTitle = content
        pendingReturnNote = ""
        store.state.thoughts[index].status = .convertedToTask
        if store.state.thoughts[index].convertedTaskId == nil {
            let task = AnchorTask(id: makeId("task"), title: content, sourceThoughtId: thoughtId, createdAt: Date(), status: "open")
            store.state.tasks.append(task)
            store.state.thoughts[index].convertedTaskId = task.id
        }
        store.save()
        if store.currentSession()?.status == .reviewing {
            refreshAll(message: "已放到下一段锚定。完成复盘后继续。")
        } else if store.currentSession() != nil {
            refreshAll(message: "已放到下一段锚定。当前锚点结束后继续。")
        } else {
            mainSurface = .focus
            refreshAll(message: "已带入待锚定。")
            showMainWindow()
        }
    }
}

struct TodayStats {
    let sessionsText: String
    let detailText: String
    let totalSeconds: TimeInterval
    let sessions: [FocusSession]
    let thoughts: [CapturedThought]
    let outputs: Int
}

func formatDurationCompact(_ seconds: TimeInterval) -> String {
    let totalMinutes = max(0, Int(round(seconds / 60)))
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 && minutes > 0 {
        return "\(hours)h\(minutes)m"
    }
    if hours > 0 {
        return "\(hours)h"
    }
    return "\(minutes)m"
}

import Foundation

extension AppDelegate {
    func startTicker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func tick() {
        guard let index = store.currentSessionIndex() else {
            updateStatusIcon()
            rebuildMenu()
            mainWindow.updateTimerOnly()
            return
        }

        let session = store.state.sessions[index]
        if session.status == .running && remainingSeconds(session) <= 0 {
            fireReminder(title: "这一段结束了", body: "先记录产出，再处理停靠想法。")
            finishSession(showWindow: false)
            scheduleDelayedReviewPrompt()
            return
        }

        maybeTriggerReminders(index: index)
        updateStatusIcon()
        rebuildMenu()
        mainWindow.updateTimerOnly()
    }

    func startSession(title: String, nextAction: String, durationMinutes: Int) {
        let now = Date()
        let session = FocusSession(
            id: makeId("session"),
            title: title,
            nextAction: nextAction,
            durationMinutes: durationMinutes,
            startedAt: now,
            endedAt: nil,
            status: .running,
            outputNote: "",
            totalPausedSeconds: 0,
            pausedAt: nil,
            midpointSent: false,
            lastIntervalReminderAt: now,
            lastCaptureAt: nil,
            lastStrongReminderAt: nil
        )
        store.state.sessions.append(session)
        store.state.currentSessionId = session.id
        store.save()
        refreshAll(message: "开始了。现在只做：\(nextAction)")
    }

    func parkThought(_ content: String) {
        let trimmed = String(content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500))
        guard !trimmed.isEmpty else { return }

        guard let index = store.currentSessionIndex(), store.state.sessions[index].status == .running else {
            let thought = CapturedThought(id: makeId("thought"), sessionId: "inbox", content: trimmed, createdAt: Date(), status: .parked, convertedTaskId: nil)
            store.state.thoughts.append(thought)
            store.save()
            refreshAll(message: "已先放到收件箱。开始锚点后再处理。")
            return
        }

        let sessionId = store.state.sessions[index].id
        let thought = CapturedThought(id: makeId("thought"), sessionId: sessionId, content: trimmed, createdAt: Date(), status: .parked, convertedTaskId: nil)
        store.state.thoughts.append(thought)
        store.state.sessions[index].lastCaptureAt = Date()
        store.save()

        if !maybeTriggerThoughtSpike(index: index) {
            refreshAll(message: "已停靠。回到：\(store.state.sessions[index].nextAction)")
        }
    }

    func maybeTriggerThoughtSpike(index: Int) -> Bool {
        let session = store.state.sessions[index]
        let recent = store.thoughts(for: session.id).filter { Date().timeIntervalSince($0.createdAt) <= thoughtSpikeWindow }
        let ready = session.lastStrongReminderAt.map { Date().timeIntervalSince($0) >= strongReminderCooldown } ?? true
        if recent.count >= thoughtSpikeThreshold && ready {
            store.state.sessions[index].lastStrongReminderAt = Date()
            store.save()
            fireReminder(title: "先别处理这些想法", body: "都已经停靠了。回到：\(session.nextAction)")
            refreshAll(message: "都已经停靠了。回到：\(session.nextAction)")
            return true
        }
        return false
    }

    func maybeTriggerReminders(index: Int) {
        var session = store.state.sessions[index]
        guard session.status == .running else { return }

        let elapsed = elapsedSeconds(session)
        let duration = TimeInterval(session.durationMinutes * 60)
        let captureCooldown = session.lastCaptureAt.map { Date().timeIntervalSince($0) < normalCooldownAfterCapture } ?? false

        if !session.midpointSent && elapsed >= duration / 2 {
            session.midpointSent = true
            session.lastIntervalReminderAt = Date()
            store.state.sessions[index] = session
            store.save()
            fireReminder(title: "还在这一件事上吗", body: "现在只需要继续：\(session.nextAction)")
            refreshAll(message: "现在只需要继续：\(session.nextAction)")
            return
        }

        if !captureCooldown && Date().timeIntervalSince(session.lastIntervalReminderAt) >= reminderInterval {
            session.lastIntervalReminderAt = Date()
            store.state.sessions[index] = session
            store.save()
            fireReminder(title: "回到当前任务", body: "现在只需要继续：\(session.nextAction)")
            refreshAll(message: "现在只需要继续：\(session.nextAction)")
        }
    }

    func togglePause() {
        guard let index = store.currentSessionIndex() else { return }
        if store.state.sessions[index].status == .running {
            store.state.sessions[index].status = .paused
            store.state.sessions[index].pausedAt = Date()
            store.save()
            refreshAll(message: "已暂停。回来时继续这一小步。")
        } else if store.state.sessions[index].status == .paused {
            let pausedAt = store.state.sessions[index].pausedAt ?? Date()
            store.state.sessions[index].totalPausedSeconds += Date().timeIntervalSince(pausedAt)
            store.state.sessions[index].pausedAt = nil
            store.state.sessions[index].status = .running
            store.state.sessions[index].lastIntervalReminderAt = Date()
            store.save()
            refreshAll(message: "继续。现在回到：\(store.state.sessions[index].nextAction)")
        }
    }

    func finishSession(showWindow: Bool = true) {
        guard let index = store.currentSessionIndex() else { return }
        if store.state.sessions[index].status == .paused, let pausedAt = store.state.sessions[index].pausedAt {
            store.state.sessions[index].totalPausedSeconds += Date().timeIntervalSince(pausedAt)
            store.state.sessions[index].pausedAt = nil
        }
        store.state.sessions[index].status = .reviewing
        store.state.sessions[index].endedAt = Date()
        store.save()
        if showWindow {
            showMainWindow()
        }
        refreshAll(message: "")
    }

    func scheduleDelayedReviewPrompt() {
        delayedReviewWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self, self.store.currentSession()?.status == .reviewing else { return }
            self.showMainWindow()
        }
        delayedReviewWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 45, execute: item)
    }

    func completeReview(outputNote: String) {
        guard let index = store.currentSessionIndex() else { return }
        delayedReviewWorkItem?.cancel()
        store.state.sessions[index].outputNote = outputNote.trimmingCharacters(in: .whitespacesAndNewlines)
        store.state.sessions[index].status = .completed
        store.state.sessions[index].endedAt = Date()
        store.state.currentSessionId = nil
        store.save()
        refreshAll(message: "复盘完成。下一段只需要再选一个动作。")
    }

    func continueFromReview(minutes: Int = 15) {
        guard let index = store.currentSessionIndex(), store.state.sessions[index].status == .reviewing else { return }
        delayedReviewWorkItem?.cancel()
        let elapsedMinutes = Int(ceil(elapsedSeconds(store.state.sessions[index]) / 60))
        store.state.sessions[index].durationMinutes = max(store.state.sessions[index].durationMinutes + minutes, elapsedMinutes + minutes)
        store.state.sessions[index].status = .running
        store.state.sessions[index].endedAt = nil
        store.state.sessions[index].lastIntervalReminderAt = Date()
        store.save()
        refreshAll(message: "已加 \(minutes) 分钟。现在回到：\(store.state.sessions[index].nextAction)")
    }

    func abandonSession() {
        guard let index = store.currentSessionIndex() else { return }
        delayedReviewWorkItem?.cancel()
        if store.state.sessions[index].status == .paused, let pausedAt = store.state.sessions[index].pausedAt {
            store.state.sessions[index].totalPausedSeconds += Date().timeIntervalSince(pausedAt)
            store.state.sessions[index].pausedAt = nil
        }
        store.state.sessions[index].status = .abandoned
        store.state.sessions[index].endedAt = Date()
        store.state.currentSessionId = nil
        store.save()
        showMainWindow()
        refreshAll(message: "已放弃当前锚点。重新选择现在要做的事。")
    }

    func updateThought(_ thoughtId: String, status: ThoughtStatus) {
        guard let index = store.state.thoughts.firstIndex(where: { $0.id == thoughtId }) else { return }
        store.state.thoughts[index].status = status
        if status == .convertedToTask {
            if store.state.thoughts[index].convertedTaskId == nil {
                let task = AnchorTask(id: makeId("task"), title: store.state.thoughts[index].content, sourceThoughtId: thoughtId, createdAt: Date(), status: "open")
                store.state.tasks.append(task)
                store.state.thoughts[index].convertedTaskId = task.id
            }
        } else {
            store.state.thoughts[index].convertedTaskId = nil
        }
        store.save()
        refreshAll(message: "")
    }
}

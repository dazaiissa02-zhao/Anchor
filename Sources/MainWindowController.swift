import AppKit

final class MainWindowController: NSWindowController, NSTextFieldDelegate {
    weak var app: AppDelegate?
    let root = NSStackView()
    var timerLabel: NSTextField?
    var elapsedLabel: NSTextField?
    var messageLabel: NSTextField?
    var messageWorkItem: DispatchWorkItem?
    var planningTaskTextView: CommandReturnTextView?
    var planningActionTextView: CommandReturnTextView?
    var planningDuration: NSPopUpButton?

    init(app: AppDelegate) {
        self.app = app
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 620), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "锚点"
        window.backgroundColor = anchorBackgroundColor
        window.center()
        super.init(window: window)
        refresh(message: "")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refresh(message: String) {
        guard let app else { return }
        root.subviews.forEach { $0.removeFromSuperview() }
        timerLabel = nil
        elapsedLabel = nil
        root.orientation = .vertical
        root.alignment = .centerX
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 42, left: 32, bottom: 28, right: 32)
        window?.contentView = root

        addHeader()

        if let session = app.store.currentSession() {
            switch session.status {
            case .running, .paused:
                addRunning(session)
            case .reviewing:
                addReview(session)
            default:
                addPlanning()
            }
        } else {
            addPlanning()
        }

        addToday()
        if !message.isEmpty { showMessage(message) }
    }

    func addHeader() {
        root.addArrangedSubview(label("锚点 ★", size: 13, weight: .semibold, color: starlightColor))
        root.addArrangedSubview(label("现在只做这一件事", size: 24, weight: .semibold, color: anchorInkColor))
    }

    func addPlanning() {
        let task = multilineInput(placeholder: "例如：写一期桌面 MVP")
        let action = multilineInput(placeholder: "例如：完成菜单栏和停靠窗口")
        let duration = NSPopUpButton()
        ["15 分钟", "25 分钟", "45 分钟", "60 分钟"].forEach { duration.addItem(withTitle: $0) }
        duration.selectItem(withTitle: "25 分钟")
        let taskTextView = task.textView
        let actionTextView = action.textView
        planningTaskTextView = taskTextView
        planningActionTextView = actionTextView
        planningDuration = duration

        let start = button("开始", style: .primary) { [weak self] in
            self?.startPlanningSession()
        }
        start.keyEquivalent = "\r"

        taskTextView.onCommandReturn = { [weak self] in
            self?.startPlanningSession()
        }
        actionTextView.onCommandReturn = { [weak self] in
            self?.startPlanningSession()
        }

        messageLabel = label("", size: 13, weight: .medium, color: anchorDangerColor)
        let startHint = label("填完后点开始，或在输入框里按 ⌘ + 回车。", size: 12, color: anchorQuietColor)

        root.addArrangedSubview(formRow("当前任务", task.scrollView))
        root.addArrangedSubview(formRow("下一步动作", action.scrollView))
        root.addArrangedSubview(formRow("时间块", duration))
        root.addArrangedSubview(messageLabel!)
        root.addArrangedSubview(startHint)
        root.addArrangedSubview(start)
    }

    @objc func startPlanningSession() {
        guard
            let taskTextView = planningTaskTextView,
            let actionTextView = planningActionTextView,
            let duration = planningDuration,
            let durationTitle = duration.titleOfSelectedItem,
            let minutes = Int(durationTitle.components(separatedBy: " ").first ?? "25")
        else {
            showMessage("开始失败：没有找到当前输入。")
            return
        }

        let taskText = taskTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        let actionText = actionTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !taskText.isEmpty, !actionText.isEmpty else {
            showMessage("先写当前任务和下一步动作。")
            return
        }

        app?.startSession(title: taskText, nextAction: actionText, durationMinutes: minutes)
    }

    func addRunning(_ session: FocusSession) {
        root.addArrangedSubview(label("现在只做", size: 13, weight: .semibold, color: anchorMutedColor))
        root.addArrangedSubview(label(session.title, size: 28, weight: .semibold, color: anchorInkColor))
        root.addArrangedSubview(label("下一步：\(session.nextAction)", size: 17, weight: .medium, color: starlightColor))
        let timer = label(formatRemaining(session), size: 40, weight: .semibold, color: anchorInkColor)
        timerLabel = timer
        root.addArrangedSubview(timer)
        let elapsed = label("已进行：\(formatElapsed(session))", size: 13, weight: .medium, color: anchorMutedColor)
        elapsedLabel = elapsed
        root.addArrangedSubview(elapsed)

        messageLabel = label("", size: 13, weight: .medium, color: starlightColor)
        root.addArrangedSubview(messageLabel!)

        let actions = NSStackView()
        actions.orientation = .horizontal
        actions.spacing = 8
        actions.addArrangedSubview(button("停靠想法 ⌥⌘J", style: .secondary) { [weak self] in self?.app?.showCapture() })
        actions.addArrangedSubview(button(session.status == .paused ? "继续" : "暂停", style: .secondary) { [weak self] in self?.app?.togglePause() })
        actions.addArrangedSubview(button("结束并复盘", style: .danger) { [weak self] in self?.app?.finishSession() })
        actions.addArrangedSubview(button("放弃当前锚点", style: .secondary) { [weak self] in self?.app?.abandonSession() })
        root.addArrangedSubview(actions)
    }

    func addReview(_ session: FocusSession) {
        root.addArrangedSubview(label("时间到了", size: 22, weight: .semibold, color: anchorInkColor))
        root.addArrangedSubview(label("收尾，或者再给这一段 15 分钟。", size: 14, color: anchorMutedColor))
        root.addArrangedSubview(label(session.title, size: 18, weight: .semibold, color: anchorInkColor))
        root.addArrangedSubview(label("下一步：\(session.nextAction)", size: 14, weight: .medium, color: starlightColor))
        root.addArrangedSubview(label("本段用时：\(formatElapsed(session))", size: 13, weight: .medium, color: anchorMutedColor))

        let output = NSTextView()
        output.string = session.outputNote
        output.font = NSFont.systemFont(ofSize: 14)
        output.textColor = anchorInkColor
        output.drawsBackground = false
        output.minSize = NSSize(width: 0, height: 90)
        output.isVerticallyResizable = true
        let scroll = NSScrollView()
        scroll.documentView = output
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.wantsLayer = true
        scroll.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.84).cgColor
        scroll.layer?.cornerRadius = 8
        scroll.layer?.borderWidth = 1
        scroll.layer?.borderColor = anchorSoftColor.cgColor
        scroll.heightAnchor.constraint(equalToConstant: 110).isActive = true
        scroll.widthAnchor.constraint(equalToConstant: 520).isActive = true
        root.addArrangedSubview(formRow("完成时，写一句产出", scroll))

        let thoughts = app?.store.thoughts(for: session.id) ?? []
        if thoughts.isEmpty {
            root.addArrangedSubview(label("这段时间没有停靠想法。", size: 14, color: .secondaryLabelColor))
        } else {
            for thought in thoughts {
                let row = NSStackView()
                row.orientation = .vertical
                row.spacing = 8
                row.addArrangedSubview(label(thought.content, size: 14))
                let actions = NSStackView()
                actions.orientation = .horizontal
                actions.spacing = 8
                actions.addArrangedSubview(button("丢弃", style: thought.status == .discarded ? .primary : .secondary) { [weak self] in self?.app?.updateThought(thought.id, status: .discarded) })
                actions.addArrangedSubview(button("以后看", style: thought.status == .later ? .primary : .secondary) { [weak self] in self?.app?.updateThought(thought.id, status: .later) })
                actions.addArrangedSubview(button("变成任务", style: thought.status == .convertedToTask ? .primary : .secondary) { [weak self] in self?.app?.updateThought(thought.id, status: .convertedToTask) })
                row.addArrangedSubview(actions)
                root.addArrangedSubview(row)
            }
        }

        let actions = NSStackView()
        actions.orientation = .horizontal
        actions.spacing = 8
        actions.addArrangedSubview(button("再继续 15 分钟", style: .primary) { [weak self] in self?.app?.continueFromReview(minutes: 15) })
        actions.addArrangedSubview(button("完成复盘", style: .secondary) { [weak self, weak output] in self?.app?.completeReview(outputNote: output?.string ?? "") })
        actions.addArrangedSubview(button("放弃当前锚点", style: .danger) { [weak self] in self?.app?.abandonSession() })
        root.addArrangedSubview(actions)
    }

    func addToday() {
        guard let app else { return }
        let calendar = Calendar.current
        let todaySessions = app.store.state.sessions.filter { calendar.isDateInToday($0.startedAt) }
        let ids = Set(todaySessions.map(\.id))
        let todayThoughts = app.store.state.thoughts.filter { ids.contains($0.sessionId) }
        let inboxCount = app.store.inboxThoughts().count
        let completed = todaySessions.filter { $0.status == .completed }.count
        let discarded = todayThoughts.filter { $0.status == .discarded }.count
        let outputs = todaySessions.filter { !$0.outputNote.isEmpty }.count
        root.addArrangedSubview(separator())
        root.addArrangedSubview(label("今天：\(completed) 个时间块 · \(todayThoughts.count) 条停靠 · \(discarded) 条丢弃 · \(outputs) 个产出 · 收件箱 \(inboxCount) 条", size: 13, color: anchorMutedColor))
    }

    func updateTimerOnly() {
        guard let session = app?.store.currentSession() else { return }
        timerLabel?.stringValue = formatRemaining(session)
        elapsedLabel?.stringValue = "已进行：\(formatElapsed(session))"
    }

    func showMessage(_ message: String) {
        messageLabel?.stringValue = message
        messageWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.messageLabel?.stringValue = "" }
        messageWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: item)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField, field.identifier?.rawValue == "thought" else { return }
        if !field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            app?.parkThought(field.stringValue)
            field.stringValue = ""
        }
    }
}

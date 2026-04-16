import AppKit

final class CaptureWindowController: NSWindowController, NSTextFieldDelegate {
    weak var app: AppDelegate?
    let inputField = NSTextField()
    let messageLabel = NSTextField(labelWithString: "")
    let stack = NSStackView()
    let listStack = NSStackView()

    init(app: AppDelegate) {
        self.app = app
        let window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 580, height: 560), styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        window.title = "✦ 停靠想法"
        window.backgroundColor = anchorBackgroundColor
        window.center()
        window.level = .floating
        window.isReleasedWhenClosed = false
        super.init(window: window)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func build() {
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        window?.contentView = stack
        stack.addArrangedSubview(label("✦ 先停靠，不打断当下", size: 17, weight: .semibold, color: starlightColor))
        inputField.placeholderString = "输入一句想法，然后回车"
        inputField.delegate = self
        inputField.font = NSFont.systemFont(ofSize: 15)
        inputField.textColor = anchorInkColor
        inputField.isBordered = false
        inputField.wantsLayer = true
        inputField.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.84).cgColor
        inputField.layer?.cornerRadius = 8
        inputField.layer?.borderWidth = 1
        inputField.layer?.borderColor = anchorSoftColor.cgColor
        inputField.heightAnchor.constraint(equalToConstant: 38).isActive = true
        inputField.widthAnchor.constraint(equalToConstant: 530).isActive = true
        stack.addArrangedSubview(inputField)
        messageLabel.textColor = anchorMutedColor
        stack.addArrangedSubview(messageLabel)

        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(label("停靠区", size: 14, weight: .semibold, color: anchorInkColor))

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.heightAnchor.constraint(equalToConstant: 330).isActive = true
        scroll.widthAnchor.constraint(equalToConstant: 530).isActive = true
        listStack.orientation = .vertical
        listStack.alignment = .leading
        listStack.spacing = 10
        listStack.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        scroll.documentView = listStack
        stack.addArrangedSubview(scroll)
    }

    func focusInput() {
        inputField.stringValue = ""
        if let session = app?.store.currentSession(), session.status == .running {
            inputField.isEnabled = true
            messageLabel.stringValue = "回到：\(session.nextAction)"
        } else {
            inputField.isEnabled = true
            messageLabel.stringValue = "还没有正在进行的锚点。可以先放到收件箱。"
        }
        refreshList()
        window?.makeFirstResponder(inputField)
    }

    func present() {
        guard let window else { return }
        if let screenFrame = NSScreen.main?.visibleFrame {
            let origin = NSPoint(
                x: screenFrame.midX - window.frame.width / 2,
                y: screenFrame.midY - window.frame.height / 2
            )
            window.setFrameOrigin(origin)
        }
        focusInput()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        let text = inputField.stringValue
        app?.parkThought(text)
        inputField.stringValue = ""
        messageLabel.stringValue = "已停靠。可以继续输入，也可以关闭窗口。"
        refreshList()
    }

    func refreshList() {
        guard let app else { return }
        listStack.subviews.forEach { $0.removeFromSuperview() }

        let currentSession = app.store.currentSession()
        let currentThoughts = currentSession.map { session in
            app.store.thoughts(for: session.id).sorted { $0.createdAt > $1.createdAt }
        } ?? []
        let inboxThoughts = app.store.inboxThoughts().sorted { $0.createdAt > $1.createdAt }

        if currentSession == nil && inboxThoughts.isEmpty {
            listStack.addArrangedSubview(label("还没有停靠想法。", size: 14, color: .secondaryLabelColor))
            return
        }

        if let session = currentSession {
            addThoughtSection(
                title: "当前锚点",
                subtitle: session.title,
                thoughts: currentThoughts,
                emptyText: "这个锚点还没有停靠想法。"
            )
        }

        if !inboxThoughts.isEmpty {
            addThoughtSection(
                title: "收件箱",
                subtitle: "没有锚点时先放在这里",
                thoughts: inboxThoughts,
                emptyText: ""
            )
        }
    }

    func addThoughtSection(title: String, subtitle: String, thoughts: [CapturedThought], emptyText: String) {
        listStack.addArrangedSubview(label(title, size: 14, weight: .bold, color: starlightColor))
        listStack.addArrangedSubview(label(subtitle, size: 12, color: .secondaryLabelColor))

        if thoughts.isEmpty {
            listStack.addArrangedSubview(label(emptyText, size: 13, color: .secondaryLabelColor))
            return
        }

        for thought in thoughts.prefix(12) {
            listStack.addArrangedSubview(thoughtRow(thought))
        }
    }

    func thoughtRow(_ thought: CapturedThought) -> NSView {
        let row = NSStackView()
        row.orientation = .vertical
        row.alignment = .leading
        row.spacing = 4
        row.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        row.widthAnchor.constraint(equalToConstant: 500).isActive = true
        row.wantsLayer = true
        row.layer?.cornerRadius = 8
        row.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        row.addArrangedSubview(label(thought.content, size: 14, weight: .semibold))
        row.addArrangedSubview(label("\(statusText(thought.status)) · \(dateText(thought.createdAt))", size: 12, color: .secondaryLabelColor))
        return row
    }

    func statusText(_ status: ThoughtStatus) -> String {
        switch status {
        case .parked:
            return "已停靠"
        case .discarded:
            return "已丢弃"
        case .later:
            return "以后看"
        case .convertedToTask:
            return "已转任务"
        }
    }

    func dateText(_ date: Date) -> String {
        shortDateText(date)
    }
}

final class ThoughtListWindowController: NSWindowController {
    weak var app: AppDelegate?
    let stack = NSStackView()

    init(app: AppDelegate) {
        self.app = app
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 560), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "停靠想法"
        window.center()
        super.init(window: window)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func build() {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = stack
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        window?.contentView = scroll
        refresh()
    }

    func refresh() {
        guard let app else { return }
        stack.subviews.forEach { $0.removeFromSuperview() }
        stack.addArrangedSubview(label("停靠想法", size: 24, weight: .bold))
        stack.addArrangedSubview(label("这里是所有被接住的念头。当前版本先做查看，处理动作在复盘里完成。", size: 13, color: .secondaryLabelColor))
        stack.addArrangedSubview(separator())

        let thoughts = app.store.state.thoughts.sorted { $0.createdAt > $1.createdAt }
        if thoughts.isEmpty {
            stack.addArrangedSubview(label("还没有停靠想法。", size: 15, color: .secondaryLabelColor))
            return
        }

        for thought in thoughts {
            stack.addArrangedSubview(thoughtRow(thought, app: app))
        }
    }

    func thoughtRow(_ thought: CapturedThought, app: AppDelegate) -> NSView {
        let box = NSStackView()
        box.orientation = .vertical
        box.alignment = .leading
        box.spacing = 6
        box.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        box.widthAnchor.constraint(equalToConstant: 560).isActive = true
        box.wantsLayer = true
        box.layer?.cornerRadius = 8
        box.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        box.addArrangedSubview(label(thought.content, size: 15, weight: .semibold))
        box.addArrangedSubview(label("\(sourceText(for: thought, app: app)) · \(statusText(thought.status)) · \(dateText(thought.createdAt))", size: 12, color: .secondaryLabelColor))
        return box
    }

    func sourceText(for thought: CapturedThought, app: AppDelegate) -> String {
        if thought.sessionId == "inbox" { return "收件箱" }
        if let session = app.store.state.sessions.first(where: { $0.id == thought.sessionId }) {
            return session.title
        }
        return "未知时间块"
    }

    func statusText(_ status: ThoughtStatus) -> String {
        switch status {
        case .parked:
            return "已停靠"
        case .discarded:
            return "已丢弃"
        case .later:
            return "以后看"
        case .convertedToTask:
            return "已转任务"
        }
    }

    func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

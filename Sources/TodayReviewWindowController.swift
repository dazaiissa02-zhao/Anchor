import AppKit

final class TodayReviewWindowController: NSWindowController {
    weak var app: AppDelegate?
    let stack = NSStackView()

    init(app: AppDelegate) {
        self.app = app
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "今日回顾"
        window.backgroundColor = anchorBackgroundColor
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
        scroll.drawsBackground = false
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        scroll.documentView = stack
        window?.contentView = scroll
        refresh()
    }

    func refresh() {
        guard let app else { return }
        stack.subviews.forEach { $0.removeFromSuperview() }

        let stats = app.todayStats()
        let header = hStack(spacing: 12)
        header.widthAnchor.constraint(equalToConstant: 680).isActive = true
        header.addArrangedSubview(label("今日回顾", size: 28, weight: .semibold, color: anchorInkColor))
        let fill = NSView()
        header.addArrangedSubview(fill)
        header.addArrangedSubview(label(todayText(), size: 14, weight: .medium, color: anchorMutedColor))
        stack.addArrangedSubview(header)

        let metrics = hStack(spacing: 12)
        metrics.widthAnchor.constraint(equalToConstant: 680).isActive = true
        metrics.addArrangedSubview(metricCard(title: "今天守住了", value: "\(stats.sessions.count) 段"))
        metrics.addArrangedSubview(metricCard(title: "总锚定时间", value: formatDurationCompact(stats.totalSeconds)))
        metrics.addArrangedSubview(metricCard(title: "停靠 / 产出", value: "\(stats.thoughts.count) / \(stats.outputs)"))
        stack.addArrangedSubview(metrics)

        if stats.sessions.isEmpty {
            let empty = styledBox(cornerRadius: 22, backgroundColor: anchorPaperColor)
            empty.widthAnchor.constraint(equalToConstant: 680).isActive = true
            empty.addArrangedSubview(label("今天还没有锚定", size: 20, weight: .semibold, color: anchorInkColor))
            empty.addArrangedSubview(label("从一件事开始。", size: 14, color: anchorMutedColor))
            stack.addArrangedSubview(empty)
        } else {
            for session in stats.sessions.sorted(by: { $0.startedAt < $1.startedAt }) {
                stack.addArrangedSubview(sessionRow(session, app: app))
            }
        }

        let actions = hStack(spacing: 12)
        actions.addArrangedSubview(button("处理收件箱", style: .secondary) { [weak app] in app?.showInbox() })
        actions.addArrangedSubview(button("导出 JSON", style: .subtle) { [weak app] in
            guard let app else { return }
            NSWorkspace.shared.activateFileViewerSelecting([app.store.fileURL])
        })
        stack.addArrangedSubview(actions)
    }

    func metricCard(title: String, value: String) -> NSView {
        let card = styledBox(cornerRadius: 18, backgroundColor: anchorPaperDeepColor)
        card.widthAnchor.constraint(equalToConstant: 218).isActive = true
        card.heightAnchor.constraint(equalToConstant: 92).isActive = true
        card.addArrangedSubview(label(title, size: 13, weight: .medium, color: anchorMutedColor))
        card.addArrangedSubview(label(value, size: 24, weight: .semibold, color: anchorInkColor))
        return card
    }

    func sessionRow(_ session: FocusSession, app: AppDelegate) -> NSView {
        let row = styledBox(cornerRadius: 18, backgroundColor: anchorPaperColor)
        row.widthAnchor.constraint(equalToConstant: 680).isActive = true
        row.orientation = .horizontal
        row.alignment = .top

        let time = vStack(spacing: 6)
        time.widthAnchor.constraint(equalToConstant: 130).isActive = true
        time.addArrangedSubview(label(timeRangeText(session), size: 13, weight: .semibold, color: anchorMutedColor))
        time.addArrangedSubview(label(formatDurationCompact(elapsedSeconds(session)), size: 14, weight: .semibold, color: starlightColor))

        let content = vStack(spacing: 5)
        content.widthAnchor.constraint(equalToConstant: 390).isActive = true
        content.addArrangedSubview(label(session.title, size: 18, weight: .semibold, color: anchorInkColor))
        let thoughts = app.store.thoughts(for: session.id)
        let note: String
        if session.status == .abandoned {
            note = "已放下 · 停靠 \(thoughts.count) 条"
        } else if session.outputNote.isEmpty {
            note = "停靠 \(thoughts.count) 条"
        } else {
            note = "产出：\(session.outputNote) · 停靠 \(thoughts.count) 条"
        }
        content.addArrangedSubview(label(note, size: 13, color: anchorMutedColor))

        let badge = label(statusText(session.status), size: 13, weight: .semibold, color: anchorMutedColor)
        badge.alignment = .center
        badge.widthAnchor.constraint(equalToConstant: 84).isActive = true

        row.addArrangedSubview(time)
        row.addArrangedSubview(content)
        row.addArrangedSubview(badge)
        return row
    }

    func todayText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M 月 d 日，EEEE"
        return formatter.string(from: Date())
    }

    func timeRangeText(_ session: FocusSession) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: session.startedAt)
        let end = formatter.string(from: session.endedAt ?? Date())
        return "\(start) - \(end)"
    }

    func statusText(_ status: SessionStatus) -> String {
        switch status {
        case .running:
            return "进行中"
        case .paused:
            return "已暂停"
        case .reviewing:
            return "待复盘"
        case .completed:
            return "完成"
        case .abandoned:
            return "已放下"
        }
    }
}

import AppKit

final class InboxWindowController: NSWindowController {
    weak var app: AppDelegate?
    let stack = NSStackView()

    init(app: AppDelegate) {
        self.app = app
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "收件箱"
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
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        scroll.documentView = stack
        window?.contentView = scroll
        refresh()
    }

    func refresh() {
        guard let app else { return }
        stack.subviews.forEach { $0.removeFromSuperview() }
        let thoughts = app.store.inboxThoughts().sorted { $0.createdAt > $1.createdAt }

        let header = hStack(spacing: 12)
        header.widthAnchor.constraint(equalToConstant: 600).isActive = true
        header.addArrangedSubview(label("收件箱", size: 28, weight: .semibold, color: anchorInkColor))
        let fill = NSView()
        header.addArrangedSubview(fill)
        header.addArrangedSubview(label("\(thoughts.count) 条念头", size: 14, weight: .medium, color: anchorMutedColor))
        stack.addArrangedSubview(header)

        if thoughts.isEmpty {
            let empty = styledBox(cornerRadius: 22, backgroundColor: anchorPaperColor)
            empty.widthAnchor.constraint(equalToConstant: 600).isActive = true
            empty.addArrangedSubview(label("没有待处理念头", size: 20, weight: .semibold, color: anchorInkColor))
            stack.addArrangedSubview(empty)
            return
        }

        for thought in thoughts {
            stack.addArrangedSubview(inboxRow(thought))
        }
    }

    func inboxRow(_ thought: CapturedThought) -> NSView {
        let row = styledBox(cornerRadius: 18, backgroundColor: anchorPaperColor)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.widthAnchor.constraint(equalToConstant: 600).isActive = true

        let content = vStack(spacing: 5)
        content.widthAnchor.constraint(equalToConstant: 300).isActive = true
        content.addArrangedSubview(fixedLabel(thought.content, width: 300, size: 16, weight: .medium, color: anchorInkColor, lines: 2))
        content.addArrangedSubview(label(shortDateText(thought.createdAt), size: 12, color: anchorMutedColor))

        let actions = hStack(spacing: 8)
        actions.addArrangedSubview(button("删除", style: .subtle) { [weak self] in
            self?.app?.deleteThought(thought.id)
        })
        actions.addArrangedSubview(button("开始锚定", style: .primary) { [weak self] in
            self?.app?.convertThoughtToPendingAnchor(thought.id)
            self?.close()
        })

        row.addArrangedSubview(content)
        row.addArrangedSubview(actions)
        return row
    }
}

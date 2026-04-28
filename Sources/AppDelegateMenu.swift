import AppKit

extension AppDelegate {
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(toggleStatusPopoverFromMenuBar)
        updateStatusIcon()
    }

    func updateStatusIcon() {
        let title: String
        let color: NSColor
        switch store.currentSession()?.status {
        case .running:
            title = "★"
            color = starlightColor
        case .paused:
            title = "☆"
            color = anchorMutedColor
        case .reviewing:
            title = "✦"
            color = starlightColor
        default:
            title = "☆"
            color = anchorMutedColor
        }

        statusItem.button?.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: color,
                .font: anchorFont(.display, size: 18, weight: .semibold)
            ]
        )
        statusItem.button?.toolTip = statusTooltip()
    }

    func rebuildMenu() {
        updateStatusIcon()
    }

    func statusTooltip() -> String {
        guard let session = store.currentSession() else {
            return "待锚定"
        }
        switch session.status {
        case .reviewing:
            return "等待复盘：\(session.title)"
        case .paused:
            return "已暂停：\(session.title)"
        default:
            return "正在锚定：\(session.title)"
        }
    }

    @objc func toggleStatusPopoverFromMenuBar() {
        guard let button = statusItem.button else { return }
        guard store.currentSession() != nil else {
            showMainWindow()
            return
        }
        if statusPopover.isShown {
            statusPopover.performClose(nil)
            return
        }

        statusPopover.contentViewController = StatusPopoverController(app: self)
        statusPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

final class StatusPopoverController: NSViewController {
    weak var app: AppDelegate?
    private let quickThoughtField = AnchorTextField()
    private let quickThoughtStatusLabel = label("", size: 12, weight: .medium, color: anchorQuietColor)
    private var thoughtComposerExpanded = false
    private weak var thoughtComposerDetails: NSView?

    init(app: AppDelegate) {
        self.app = app
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let wrapper = styledBox(cornerRadius: 26, backgroundColor: anchorPaperColor)
        wrapper.widthAnchor.constraint(equalToConstant: 360).isActive = true
        wrapper.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)

        guard let app else {
            view = wrapper
            return
        }

        if let session = app.store.currentSession() {
            switch session.status {
            case .reviewing:
                wrapper.addArrangedSubview(reviewingView(session, app: app))
            case .paused:
                wrapper.addArrangedSubview(pausedView(session, app: app))
            default:
                wrapper.addArrangedSubview(runningView(session, app: app))
            }
        }

        wrapper.addArrangedSubview(separator())
        wrapper.addArrangedSubview(footer(app: app))
        view = wrapper
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if thoughtComposerExpanded, app?.store.currentSession()?.status == .running {
            view.window?.makeFirstResponder(quickThoughtField)
        }
    }

    private func runningView(_ session: FocusSession, app: AppDelegate) -> NSView {
        let stack = vStack(spacing: 12)
        stack.widthAnchor.constraint(equalToConstant: 320).isActive = true

        let titleRow = hStack(spacing: 8)
        titleRow.widthAnchor.constraint(equalToConstant: 320).isActive = true
        titleRow.addArrangedSubview(label("★", size: 21, weight: .semibold, color: starlightColor))
        titleRow.addArrangedSubview(label("正在锚定", size: 16, weight: .semibold, color: anchorInkColor))
        let fill = NSView()
        titleRow.addArrangedSubview(fill)
        titleRow.addArrangedSubview(label("\(Int(ceil(max(0, remainingSeconds(session)) / 60)))m", size: 13, weight: .medium, color: anchorQuietColor))
        stack.addArrangedSubview(titleRow)

        let title = fixedLabel(session.title, width: 320, size: 28, weight: .semibold, color: anchorInkColor, lines: 2)
        title.lineBreakMode = .byTruncatingTail
        stack.addArrangedSubview(title)

        let meta = label(runningMeta(session, app: app), size: 13, weight: .medium, color: anchorMutedColor)
        meta.widthAnchor.constraint(equalToConstant: 320).isActive = true
        stack.addArrangedSubview(meta)

        stack.addArrangedSubview(thoughtComposer(session: session, app: app))
        return stack
    }

    private func pausedView(_ session: FocusSession, app: AppDelegate) -> NSView {
        let stack = vStack(spacing: 12)
        stack.widthAnchor.constraint(equalToConstant: 320).isActive = true

        let titleRow = hStack(spacing: 8)
        titleRow.addArrangedSubview(label("☆", size: 21, weight: .semibold, color: anchorMutedColor))
        titleRow.addArrangedSubview(label("已暂停", size: 16, weight: .semibold, color: anchorInkColor))
        stack.addArrangedSubview(titleRow)

        stack.addArrangedSubview(fixedLabel(session.title, width: 320, size: 28, weight: .semibold, color: anchorInkColor, lines: 2))
        let resume = button("继续当前锚点", style: .primary) { [weak self] in
            self?.resumeCurrentAnchor()
        }
        resume.widthAnchor.constraint(equalToConstant: 238).isActive = true
        stack.addArrangedSubview(resume)
        return stack
    }

    private func reviewingView(_ session: FocusSession, app: AppDelegate) -> NSView {
        let stack = vStack(spacing: 12)
        stack.widthAnchor.constraint(equalToConstant: 320).isActive = true

        let titleRow = hStack(spacing: 8)
        titleRow.widthAnchor.constraint(equalToConstant: 320).isActive = true
        titleRow.addArrangedSubview(label("✦", size: 21, weight: .semibold, color: starlightColor))
        titleRow.addArrangedSubview(label("等待复盘", size: 16, weight: .semibold, color: anchorMutedColor))
        let fill = NSView()
        titleRow.addArrangedSubview(fill)
        titleRow.addArrangedSubview(label("⌛︎", size: 16, weight: .semibold, color: anchorQuietColor))
        titleRow.addArrangedSubview(iconButton("↗", style: .subtle) { [weak app] in app?.showMainWindow() })
        stack.addArrangedSubview(titleRow)

        stack.addArrangedSubview(fixedLabel(session.title, width: 320, size: 30, weight: .semibold, color: anchorInkColor, lines: 2))
        return stack
    }

    private func footer(app: AppDelegate) -> NSView {
        let footer = hStack(spacing: 10)
        footer.widthAnchor.constraint(equalToConstant: 320).isActive = true
        footer.addArrangedSubview(button("今天", style: .subtle) { [weak app] in app?.showTodayReview() })
        footer.addArrangedSubview(button("收件箱", style: .subtle) { [weak app] in app?.showInbox() })
        return footer
    }

    private func runningMeta(_ session: FocusSession, app: AppDelegate) -> String {
        let todayCount = app.todayStats().sessions.count
        let todayDuration = formatDurationCompact(app.todayStats().totalSeconds)
        return "剩 \(Int(ceil(max(0, remainingSeconds(session)) / 60))) 分钟 · 第 \(max(todayCount, 1)) 段 · 今日 \(todayDuration)"
    }

    private func thoughtComposer(session: FocusSession, app: AppDelegate) -> NSView {
        let stack = vStack(spacing: 10)
        stack.widthAnchor.constraint(equalToConstant: 320).isActive = true

        quickThoughtStatusLabel.stringValue = "已存草 \(app.store.thoughts(for: session.id).count) 条"

        let summaryRow = hStack(spacing: 8)
        summaryRow.widthAnchor.constraint(equalToConstant: 320).isActive = true
        summaryRow.addArrangedSubview(quickThoughtStatusLabel)
        let fill = NSView()
        summaryRow.addArrangedSubview(fill)
        summaryRow.addArrangedSubview(iconButton("✦", style: .subtle) { [weak self] in
            self?.toggleThoughtComposer()
        })
        stack.addArrangedSubview(summaryRow)

        let details = vStack(spacing: 10)
        details.widthAnchor.constraint(equalToConstant: 320).isActive = true
        details.isHidden = !thoughtComposerExpanded
        thoughtComposerDetails = details

        quickThoughtField.placeholderAttributedString = NSAttributedString(
            string: "写下刚冒出来的念头",
            attributes: [
                .font: anchorFont(.chinese, size: 16, weight: .medium),
                .foregroundColor: anchorQuietColor
            ]
        )
        quickThoughtField.target = self
        quickThoughtField.action = #selector(saveThoughtFromPopover)

        let fieldBox = NSView()
        fieldBox.translatesAutoresizingMaskIntoConstraints = false
        fieldBox.wantsLayer = true
        fieldBox.layer?.backgroundColor = anchorPaperSoftColor.cgColor
        fieldBox.layer?.cornerRadius = 20
        fieldBox.layer?.borderWidth = 1
        fieldBox.layer?.borderColor = anchorSoftColor.withAlphaComponent(0.55).cgColor
        fieldBox.widthAnchor.constraint(equalToConstant: 320).isActive = true
        fieldBox.heightAnchor.constraint(equalToConstant: 108).isActive = true
        quickThoughtField.translatesAutoresizingMaskIntoConstraints = false
        fieldBox.addSubview(quickThoughtField)
        NSLayoutConstraint.activate([
            quickThoughtField.leadingAnchor.constraint(equalTo: fieldBox.leadingAnchor, constant: 16),
            quickThoughtField.trailingAnchor.constraint(equalTo: fieldBox.trailingAnchor, constant: -16),
            quickThoughtField.topAnchor.constraint(equalTo: fieldBox.topAnchor, constant: 18)
        ])
        details.addArrangedSubview(fieldBox)

        let footer = hStack(spacing: 8)
        footer.widthAnchor.constraint(equalToConstant: 320).isActive = true
        footer.addArrangedSubview(button("收起", style: .subtle) { [weak self] in
            self?.toggleThoughtComposer(force: false)
        })
        let detailsFill = NSView()
        footer.addArrangedSubview(detailsFill)
        footer.addArrangedSubview(button("存草", style: .subtle) { [weak self] in
            self?.saveThoughtFromPopover()
        })
        details.addArrangedSubview(footer)
        stack.addArrangedSubview(details)

        return stack
    }

    @objc private func saveThoughtFromPopover() {
        let text = quickThoughtField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let app, let session = app.store.currentSession() else { return }
        app.parkThought(text)
        quickThoughtField.stringValue = ""
        quickThoughtStatusLabel.stringValue = "已存草 \(app.store.thoughts(for: session.id).count) 条"
        toggleThoughtComposer(force: false)
    }

    @objc private func resumeCurrentAnchor() {
        app?.togglePause()
        app?.statusPopover?.performClose(nil)
    }

    private func toggleThoughtComposer(force: Bool? = nil) {
        thoughtComposerExpanded = force ?? !thoughtComposerExpanded
        thoughtComposerDetails?.isHidden = !thoughtComposerExpanded
        if thoughtComposerExpanded {
            view.window?.makeFirstResponder(quickThoughtField)
        } else {
            quickThoughtField.stringValue = ""
            view.window?.makeFirstResponder(nil)
        }
        view.needsLayout = true
        view.layoutSubtreeIfNeeded()
        view.invalidateIntrinsicContentSize()
        let targetSize = view.fittingSize
        preferredContentSize = targetSize
        app?.statusPopover?.contentSize = targetSize
    }
}

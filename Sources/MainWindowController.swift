import AppKit

final class MainWindowController: NSWindowController, NSTextFieldDelegate {
    private let contentWidth: CGFloat = 920
    private let summaryGap: CGFloat = 16
    private var summaryCardWidth: CGFloat { (contentWidth - summaryGap) / 2 }

    weak var app: AppDelegate?
    let canvasView = PaperCanvasView()
    let root = NSStackView()

    var timerLabel: NSTextField?
    var elapsedLabel: NSTextField?
    var messageLabel: NSTextField?
    var messageWorkItem: DispatchWorkItem?
    var planningTaskTextView: CommandReturnTextView?
    var planningReturnTextView: CommandReturnTextView?
    var planningDurationMinutes = 25
    var reviewOutputTextView: NSTextView?
    var reviewContinueMinutes = 15
    var isReviewDurationExpanded = false
    var reviewCalendarMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()

    init(app: AppDelegate) {
        self.app = app
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 840),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Anchor"
        window.backgroundColor = anchorBackgroundColor
        window.center()
        window.minSize = NSSize(width: 980, height: 760)
        super.init(window: window)
        buildShell()
        refresh(message: "")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildShell() {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        canvasView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = canvasView

        root.orientation = .vertical
        root.alignment = .centerX
        root.spacing = 18
        root.edgeInsets = NSEdgeInsets(top: 34, left: 30, bottom: 28, right: 30)
        root.translatesAutoresizingMaskIntoConstraints = false

        canvasView.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: canvasView.topAnchor),
            root.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: canvasView.trailingAnchor),
            root.bottomAnchor.constraint(lessThanOrEqualTo: canvasView.bottomAnchor),
            root.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor)
        ])
    }

    func refresh(message: String) {
        guard let app else { return }
        preservePlanningDrafts()
        clearRoot()
        timerLabel = nil
        elapsedLabel = nil
        messageLabel = nil
        reviewOutputTextView = nil

        switch app.mainSurface {
        case .todayReview:
            addTodayReviewPage()
        case .inbox:
            addInboxPage()
        case .focus:
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
        }

        if app.mainSurface == .focus, app.store.currentSession()?.status == .reviewing, let reviewOutputTextView {
            DispatchQueue.main.async { [weak self] in
                self?.window?.makeFirstResponder(reviewOutputTextView)
            }
        }

        if !message.isEmpty {
            showMessage(message)
        }
    }

    private func clearRoot() {
        for view in root.arrangedSubviews {
            root.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func addTitleBar(state: String, symbol: String, trailingTitle: String? = "今日回顾 ›", trailingAction: (() -> Void)? = nil) {
        let bar = hStack(spacing: 12)
        bar.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        let left = hStack(spacing: 10)
        left.addArrangedSubview(label(symbol, size: 24, weight: .semibold, color: starlightColor))
        left.addArrangedSubview(label(state, size: 18, weight: .semibold, color: anchorInkColor))
        bar.addArrangedSubview(left)

        let fill = NSView()
        fill.translatesAutoresizingMaskIntoConstraints = false
        bar.addArrangedSubview(fill)

        if let trailingTitle {
            let action = button(trailingTitle, style: .subtle) { [weak self] in
                if let trailingAction {
                    trailingAction()
                } else {
                    self?.app?.showTodayReview()
                }
            }
            action.heightAnchor.constraint(equalToConstant: 40).isActive = true
            bar.addArrangedSubview(action)
        }

        root.addArrangedSubview(bar)
    }

    func addNavigationTitleBar(title: String, symbol: String = "‹", subtitle: String? = nil) {
        let bar = hStack(spacing: 12)
        bar.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        let back = button(symbol, style: .subtle) { [weak self] in
            self?.app?.showFocusSurface()
        }
        back.widthAnchor.constraint(equalToConstant: 54).isActive = true
        bar.addArrangedSubview(back)

        let titles = vStack(spacing: 2)
        titles.addArrangedSubview(label(title, size: 18, weight: .semibold, color: anchorInkColor))
        if let subtitle {
            titles.addArrangedSubview(label(subtitle, size: 13, weight: .medium, color: anchorQuietColor))
        }
        bar.addArrangedSubview(titles)

        let fill = NSView()
        bar.addArrangedSubview(fill)
        root.addArrangedSubview(bar)
    }

    func addPlanning() {
        guard let app else { return }
        addTitleBar(state: "待锚定", symbol: "☆")

        let card = styledBox(cornerRadius: 30, backgroundColor: anchorPaperColor)
        card.alignment = .centerX
        card.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        card.addArrangedSubview(spacer(height: 4))
        card.addArrangedSubview(label("现在要定个什么？", size: 16, weight: .semibold, color: anchorMutedColor))

        let task = MultilineInput(placeholder: "比如：写 Anchor 的下一版桌面体验", width: 760, height: 98)
        task.textView.string = app.pendingAnchorTitle ?? ""
        task.textView.syncPlaceholder()
        task.textView.onCommandReturn = { [weak self] in self?.startPlanningSession() }
        planningTaskTextView = task.textView
        card.addArrangedSubview(formRow("当前锚点", task.containerView, hint: "这段时间里只守住这一件事。", width: 760))

        let returnNote = MultilineInput(placeholder: "比如：回来时先把主窗口草图收完", width: 760, height: 92)
        returnNote.textView.string = app.pendingReturnNote ?? ""
        returnNote.textView.syncPlaceholder()
        returnNote.textView.onCommandReturn = { [weak self] in self?.startPlanningSession() }
        planningReturnTextView = returnNote.textView
        card.addArrangedSubview(formRow("回来时（可选）", returnNote.containerView, hint: "留给回来的自己一句提醒。", width: 760))

        card.addArrangedSubview(durationSelector(title: "锚定多久", options: [15, 25, 45, 60], selected: planningDurationMinutes) { [weak self] value in
            self?.preservePlanningDrafts()
            self?.planningDurationMinutes = value
            self?.refresh(message: "")
        })

        let actionRow = hStack(spacing: 12)
        let start = button("开始锚定", style: .primary) { [weak self] in self?.startPlanningSession() }
        start.widthAnchor.constraint(greaterThanOrEqualToConstant: 164).isActive = true
        actionRow.addArrangedSubview(start)
        actionRow.addArrangedSubview(button("星光停靠", style: .subtle) { [weak self] in self?.app?.showCapture() })
        card.addArrangedSubview(actionRow)

        messageLabel = label("", size: 13, weight: .medium, color: anchorDangerColor)
        card.addArrangedSubview(messageLabel!)
        root.addArrangedSubview(card)

        addSummaryCards()
    }

    @objc func startPlanningSession() {
        guard let taskTextView = planningTaskTextView, let returnTextView = planningReturnTextView else {
            showMessage("开始失败：没有找到当前输入。")
            return
        }

        let taskText = taskTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        let returnText = returnTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !taskText.isEmpty else {
            showMessage("先写当前锚点。")
            return
        }

        app?.pendingAnchorTitle = nil
        app?.pendingReturnNote = nil
        app?.startSession(title: taskText, nextAction: returnText, durationMinutes: planningDurationMinutes)
    }

    private func preservePlanningDrafts() {
        guard app?.store.currentSession() == nil else { return }
        if let taskText = planningTaskTextView?.string {
            let trimmed = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
            app?.pendingAnchorTitle = trimmed.isEmpty ? nil : taskText
        }
        if let returnText = planningReturnTextView?.string {
            let trimmed = returnText.trimmingCharacters(in: .whitespacesAndNewlines)
            app?.pendingReturnNote = trimmed.isEmpty ? nil : returnText
        }
    }

    func addRunning(_ session: FocusSession) {
        addTitleBar(state: session.status == .paused ? "已暂停" : "当前锚定中", symbol: "★")

        let card = styledBox(cornerRadius: 32, backgroundColor: anchorPaperColor)
        card.alignment = .centerX
        card.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        card.heightAnchor.constraint(greaterThanOrEqualToConstant: 420).isActive = true

        card.addArrangedSubview(spacer(height: 8))
        card.addArrangedSubview(label("现在只做", size: 16, weight: .semibold, color: anchorMutedColor))

        let title = label(session.title, size: 54, weight: .semibold, color: anchorInkColor)
        title.alignment = .center
        title.lineBreakMode = .byTruncatingTail
        title.maximumNumberOfLines = 1
        title.widthAnchor.constraint(equalToConstant: 820).isActive = true
        card.addArrangedSubview(title)

        let timer = monoLabel(formatRemaining(session), size: 40, color: starlightColor)
        timer.alignment = .center
        timerLabel = timer
        card.addArrangedSubview(timer)

        let elapsed = label("已进行 \(formatElapsed(session))", size: 13, weight: .medium, color: anchorQuietColor)
        elapsed.alignment = .center
        elapsedLabel = elapsed
        card.addArrangedSubview(elapsed)

        if !session.nextAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let note = label("回来时：\(session.nextAction)", size: 17, weight: .medium, color: anchorMutedColor)
            note.alignment = .center
            note.widthAnchor.constraint(equalToConstant: 760).isActive = true
            card.addArrangedSubview(note)
        }
        card.addArrangedSubview(spacer(height: 6))

        root.addArrangedSubview(card)

        addSummaryCards()

        let actions = hStack(spacing: 12)
        actions.addArrangedSubview(button("星光停靠", style: .primary) { [weak self] in self?.app?.showCapture() })
        actions.addArrangedSubview(button(session.status == .paused ? "继续" : "暂停", style: .secondary) { [weak self] in
            self?.app?.togglePause()
        })
        actions.addArrangedSubview(button("提前复盘", style: .secondary) { [weak self] in
            self?.app?.finishSession()
        })
        root.addArrangedSubview(actions)
        root.addArrangedSubview(button("放下当前锚点", style: .subtle) { [weak self] in self?.app?.abandonSession() })
    }

    func addReview(_ session: FocusSession) {
        addTitleBar(state: "Checkpoint", symbol: "✦", trailingTitle: "\(session.durationMinutes)m", trailingAction: {})

        let panel = styledBox(cornerRadius: 28, backgroundColor: anchorPaperColor)
        panel.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        let header = hStack(spacing: 12)
        header.widthAnchor.constraint(equalToConstant: 840).isActive = true
        let title = label(session.title, size: 30, weight: .semibold, color: anchorInkColor)
        title.lineBreakMode = .byTruncatingTail
        title.maximumNumberOfLines = 1
        title.widthAnchor.constraint(equalToConstant: 760).isActive = true
        header.addArrangedSubview(title)
        let metaFill = NSView()
        header.addArrangedSubview(metaFill)
        header.addArrangedSubview(label(shortDateText(session.endedAt ?? Date()), size: 13, weight: .medium, color: anchorQuietColor))
        panel.addArrangedSubview(header)

        let columns = hStack(spacing: 18, alignment: .top)
        columns.widthAnchor.constraint(equalToConstant: 860).isActive = true

        let outputColumn = vStack(spacing: 10)
        outputColumn.widthAnchor.constraint(equalToConstant: 420).isActive = true
        outputColumn.addArrangedSubview(label("产出", size: 14, weight: .semibold, color: anchorMutedColor))
        outputColumn.addArrangedSubview(reviewOutputView(session))

        let thoughtColumn = vStack(spacing: 10)
        thoughtColumn.widthAnchor.constraint(equalToConstant: 420).isActive = true
        let thoughts = app?.store.thoughts(for: session.id).filter { $0.status == .parked || $0.status == .later } ?? []
        thoughtColumn.addArrangedSubview(label("存草想法 · \(thoughts.count) 条", size: 14, weight: .semibold, color: anchorMutedColor))
        if thoughts.isEmpty {
            let empty = styledBox(cornerRadius: 20, backgroundColor: anchorPaperSoftColor)
            empty.widthAnchor.constraint(equalToConstant: 420).isActive = true
            empty.addArrangedSubview(label("这一段没有存草。", size: 15, weight: .medium, color: anchorQuietColor))
            thoughtColumn.addArrangedSubview(empty)
        } else {
            for thought in thoughts.sorted(by: { $0.createdAt < $1.createdAt }) {
                thoughtColumn.addArrangedSubview(reviewThoughtRow(thought))
            }
        }

        columns.addArrangedSubview(outputColumn)
        columns.addArrangedSubview(thoughtColumn)
        panel.addArrangedSubview(columns)

        let actions = hStack(spacing: 12, alignment: .top)
        actions.addArrangedSubview(reviewContinueControl())
        actions.addArrangedSubview(button("完成复盘", style: .secondary) { [weak self] in
            self?.app?.completeReview(outputNote: self?.reviewOutputTextView?.string ?? "")
        })
        actions.addArrangedSubview(button("更换锚点", style: .danger) { [weak self] in
            self?.app?.abandonSession()
        })
        panel.addArrangedSubview(actions)

        messageLabel = label("", size: 13, weight: .medium, color: anchorMutedColor)
        panel.addArrangedSubview(messageLabel!)
        root.addArrangedSubview(panel)
    }

    private func reviewOutputView(_ session: FocusSession) -> NSView {
        let input = MultilineInput(placeholder: "写下这一段真正产出了什么", width: 420, height: 240)
        input.textView.font = anchorFont(.chinese, size: 18, weight: .regular)
        input.textView.string = session.outputNote
        input.textView.syncPlaceholder()
        reviewOutputTextView = input.textView
        return input.containerView
    }

    private func reviewContinueControl() -> NSView {
        let wrapper = vStack(spacing: 2)
        wrapper.alignment = .leading

        let trigger = button("继续 \(reviewContinueMinutes) 分钟 ▾", style: .primary) { [weak self] in
            self?.isReviewDurationExpanded.toggle()
            self?.refresh(message: "")
        }
        trigger.widthAnchor.constraint(equalToConstant: 232).isActive = true
        wrapper.addArrangedSubview(trigger)

        if isReviewDurationExpanded {
            let options = vStack(spacing: 8)
            [5, 15, 25, 45].forEach { minutes in
                let option = button("继续 \(minutes) 分钟", style: minutes == reviewContinueMinutes ? .primary : .subtle) { [weak self] in
                    self?.reviewContinueMinutes = minutes
                    self?.isReviewDurationExpanded = false
                    self?.app?.continueFromReview(minutes: minutes)
                }
                option.widthAnchor.constraint(equalToConstant: 232).isActive = true
                options.addArrangedSubview(option)
            }
            let card = styledBox(cornerRadius: 20, backgroundColor: anchorPaperColor)
            card.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            card.widthAnchor.constraint(equalToConstant: 248).isActive = true
            card.layer?.shadowRadius = 10
            card.layer?.shadowOffset = NSSize(width: 0, height: -1)
            card.addArrangedSubview(options)
            wrapper.addArrangedSubview(card)
        }

        return wrapper
    }

    func reviewThoughtRow(_ thought: CapturedThought) -> NSView {
        let row = styledBox(cornerRadius: 20, backgroundColor: anchorPaperWhiteColor)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.widthAnchor.constraint(equalToConstant: 420).isActive = true

        let content = fixedLabel(thought.content, width: 320, size: 16, weight: .medium, color: anchorInkColor, lines: 2)
        row.addArrangedSubview(content)

        let fill = NSView()
        row.addArrangedSubview(fill)

        let menuButton = iconButton("···", style: .subtle) {}
        if let closureButton = menuButton as? ClosureButton {
            closureButton.onClick = { [weak self, weak menuButton] in
                guard let self, let menuButton else { return }
                let menu = NSMenu()
                menu.addItem(ClosureMenuItem(title: "丢弃") { [weak self] in self?.app?.updateThought(thought.id, status: .discarded) })
                menu.addItem(ClosureMenuItem(title: "留在收件箱") { [weak self] in self?.app?.moveThoughtToInbox(thought.id) })
                menu.addItem(ClosureMenuItem(title: "变成下个锚点") { [weak self] in self?.app?.convertThoughtToPendingAnchor(thought.id) })
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: menuButton.bounds.height + 4), in: menuButton)
            }
        }
        row.addArrangedSubview(menuButton)
        return row
    }

    func addSummaryCards() {
        guard let app else { return }
        let stats = app.todayStats()
        let cards = hStack(spacing: summaryGap, alignment: .top)
        cards.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        cards.addArrangedSubview(summaryCard(title: "今天", main: stats.sessionsText, sub: stats.detailText) { [weak self] in
            self?.app?.showTodayReview()
        })
        cards.addArrangedSubview(summaryCard(title: "收件箱", main: "\(app.store.inboxThoughts().count) 条念头", sub: "稍后处理") { [weak self] in
            self?.app?.showInbox()
        })
        root.addArrangedSubview(cards)
    }

    func addTodayReviewPage() {
        guard let app else { return }
        let selectedDate = Calendar.current.startOfDay(for: app.reviewReferenceDate)
        if !Calendar.current.isDate(selectedDate, equalTo: reviewCalendarMonth, toGranularity: .month) {
            reviewCalendarMonth = monthStart(for: selectedDate)
        }
        let stats = app.todayStats(for: selectedDate)
        addTodayReviewHeader(selectedDate: selectedDate)

        let leftWidth: CGFloat = 618
        let rightWidth: CGFloat = contentWidth - leftWidth - 18
        let layout = hStack(spacing: 18, alignment: .top)
        layout.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        let shell = styledBox(cornerRadius: 30, backgroundColor: anchorPaperColor)
        shell.widthAnchor.constraint(equalToConstant: leftWidth).isActive = true

        let headline = hStack(spacing: 10, alignment: .top)
        headline.widthAnchor.constraint(equalToConstant: leftWidth - 44).isActive = true

        let headlineText = vStack(spacing: 4)
        headlineText.addArrangedSubview(label(reviewPanelTitleText(selectedDate), size: 18, weight: .semibold, color: anchorInkColor))
        headlineText.addArrangedSubview(label(reviewHeaderDateText(selectedDate), size: 13, weight: .medium, color: anchorQuietColor))
        headline.addArrangedSubview(headlineText)
        headline.addArrangedSubview(NSView())
        shell.addArrangedSubview(headline)

        let metricWidth = (leftWidth - 44 - 12) / 2
        let metricsTop = hStack(spacing: 12)
        metricsTop.widthAnchor.constraint(equalToConstant: leftWidth - 44).isActive = true
        metricsTop.addArrangedSubview(metricCard(title: "锚了", value: "\(stats.sessions.count) 段", width: metricWidth))
        metricsTop.addArrangedSubview(metricCard(title: "总时长", value: formatDurationCompact(stats.totalSeconds), width: metricWidth))
        shell.addArrangedSubview(metricsTop)

        let metricsBottom = hStack(spacing: 12)
        metricsBottom.widthAnchor.constraint(equalToConstant: leftWidth - 44).isActive = true
        metricsBottom.addArrangedSubview(metricCard(title: "存草", value: "\(stats.thoughts.count) 条", width: metricWidth))
        metricsBottom.addArrangedSubview(metricCard(title: "产出", value: "\(stats.outputs) 条", width: metricWidth))
        shell.addArrangedSubview(metricsBottom)

        let body = vStack(spacing: 12)
        body.widthAnchor.constraint(equalToConstant: leftWidth - 44).isActive = true
        if stats.sessions.isEmpty {
            let empty = styledBox(cornerRadius: 22, backgroundColor: anchorPaperSoftColor)
            empty.widthAnchor.constraint(equalToConstant: leftWidth - 44).isActive = true
            empty.addArrangedSubview(label("这一天还没有记录。", size: 20, weight: .semibold, color: anchorInkColor))
            empty.addArrangedSubview(label("右侧点亮的日期可以直接切换查看。", size: 14, weight: .medium, color: anchorMutedColor))
            body.addArrangedSubview(empty)
        } else {
            for session in stats.sessions.sorted(by: { $0.startedAt < $1.startedAt }) {
                body.addArrangedSubview(todaySessionRow(session, app: app, width: leftWidth - 44))
            }
        }
        shell.addArrangedSubview(body)

        let actions = hStack(spacing: 12)
        actions.addArrangedSubview(button("看收件箱", style: .secondary) { [weak self] in
            self?.app?.showInbox()
        })
        actions.addArrangedSubview(button("导出记录", style: .subtle) { [weak app] in
            guard let app else { return }
            NSWorkspace.shared.activateFileViewerSelecting([app.store.fileURL])
        })
        shell.addArrangedSubview(actions)

        layout.addArrangedSubview(shell)
        layout.addArrangedSubview(reviewCalendarPanel(selectedDate: selectedDate, width: rightWidth))
        root.addArrangedSubview(layout)
    }

    private func addTodayReviewHeader(selectedDate: Date) {
        let bar = hStack(spacing: 12)
        bar.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        let back = button("‹", style: .subtle) { [weak self] in
            self?.app?.showFocusSurface()
        }
        back.widthAnchor.constraint(equalToConstant: 54).isActive = true
        bar.addArrangedSubview(back)

        let titles = vStack(spacing: 2)
        titles.addArrangedSubview(label("今日回顾", size: 18, weight: .semibold, color: anchorInkColor))
        titles.addArrangedSubview(label(reviewHeaderDateText(selectedDate), size: 13, weight: .medium, color: anchorQuietColor))
        bar.addArrangedSubview(titles)
        root.addArrangedSubview(bar)
    }

    func addInboxPage() {
        guard let app else { return }
        let thoughts = app.store.inboxThoughts().sorted { $0.createdAt > $1.createdAt }
        addNavigationTitleBar(title: "收件箱", subtitle: thoughts.isEmpty ? "现在是空的" : "\(thoughts.count) 条待处理念头")

        let shell = styledBox(cornerRadius: 30, backgroundColor: anchorPaperColor)
        shell.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true

        let intro = label("这里收着那些不该打断当下、但也不该丢掉的念头。", size: 15, weight: .medium, color: anchorMutedColor)
        intro.widthAnchor.constraint(equalToConstant: 860).isActive = true
        shell.addArrangedSubview(intro)

        if thoughts.isEmpty {
            let empty = styledBox(cornerRadius: 22, backgroundColor: anchorPaperSoftColor)
            empty.widthAnchor.constraint(equalToConstant: 860).isActive = true
            empty.addArrangedSubview(label("没有待处理念头。", size: 20, weight: .semibold, color: anchorInkColor))
            empty.addArrangedSubview(label("当你有分心瞬间时，再用星光停靠把它们接住。", size: 14, weight: .medium, color: anchorMutedColor))
            shell.addArrangedSubview(empty)
        } else {
            let list = styledBox(cornerRadius: 24, backgroundColor: anchorPaperSoftColor)
            list.widthAnchor.constraint(equalToConstant: 860).isActive = true
            list.spacing = 0
            list.edgeInsets = NSEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            for (index, thought) in thoughts.enumerated() {
                list.addArrangedSubview(inboxThoughtRow(thought))
                if index < thoughts.count - 1 {
                    let line = separator()
                    line.widthAnchor.constraint(equalToConstant: 828).isActive = true
                    list.addArrangedSubview(line)
                }
            }
            shell.addArrangedSubview(list)
        }

        root.addArrangedSubview(shell)
    }

    func summaryCard(title: String, main: String, sub: String, action: @escaping () -> Void) -> NSView {
        let card = clickableBox(cornerRadius: 24, backgroundColor: anchorPaperDeepColor, action: action)
        card.widthAnchor.constraint(equalToConstant: summaryCardWidth).isActive = true
        card.heightAnchor.constraint(equalToConstant: 132).isActive = true
        card.addArrangedSubview(label(title, size: 15, weight: .semibold, color: anchorMutedColor))
        card.addArrangedSubview(label(main, size: 34, weight: .semibold, color: anchorInkColor))
        card.addArrangedSubview(label(sub, size: 15, weight: .medium, color: anchorMutedColor))
        return card
    }

    private func durationSelector(title: String, options: [Int], selected: Int, onSelect: @escaping (Int) -> Void) -> NSView {
        let wrapper = vStack(spacing: 10)
        wrapper.widthAnchor.constraint(equalToConstant: 760).isActive = true
        wrapper.addArrangedSubview(label(title, size: 13, weight: .semibold, color: anchorMutedColor))

        let row = hStack(spacing: 10)
        options.forEach { value in
            row.addArrangedSubview(selectablePillButton("\(value)", selected: value == selected) {
                onSelect(value)
            })
        }
        row.addArrangedSubview(label("分钟", size: 15, weight: .medium, color: anchorQuietColor))
        wrapper.addArrangedSubview(row)
        return wrapper
    }

    func metricCard(title: String, value: String, width: CGFloat) -> NSView {
        let card = styledBox(cornerRadius: 22, backgroundColor: anchorPaperDeepColor)
        card.widthAnchor.constraint(equalToConstant: width).isActive = true
        card.heightAnchor.constraint(equalToConstant: 132).isActive = true
        card.edgeInsets = NSEdgeInsets(top: 26, left: 24, bottom: 22, right: 24)
        card.spacing = 12

        let titleLabel = fixedLabel(title, width: width - 48, size: 14, weight: .medium, color: anchorMutedColor, lines: 1)
        titleLabel.lineBreakMode = .byTruncatingTail
        let valueLabel = fixedLabel(value, width: width - 48, size: 30, weight: .semibold, color: anchorInkColor, lines: 1)

        card.addArrangedSubview(titleLabel)
        card.addArrangedSubview(valueLabel)
        return card
    }

    func todaySessionRow(_ session: FocusSession, app: AppDelegate, width: CGFloat = 860) -> NSView {
        let row = styledBox(cornerRadius: 22, backgroundColor: anchorPaperWhiteColor)
        row.widthAnchor.constraint(equalToConstant: width).isActive = true
        row.orientation = .horizontal
        row.alignment = .top

        let timeWidth: CGFloat = width >= 760 ? 148 : 104
        let badgeWidth: CGFloat = 108
        let contentWidth = max(220, width - timeWidth - badgeWidth - 70)

        let time = vStack(spacing: 6)
        time.widthAnchor.constraint(equalToConstant: timeWidth).isActive = true
        time.addArrangedSubview(label(timeRangeText(session), size: 13, weight: .semibold, color: anchorMutedColor))
        time.addArrangedSubview(monoLabel(formatDurationCompact(elapsedSeconds(session)), size: 15, color: starlightColor))

        let content = vStack(spacing: 6)
        content.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        content.addArrangedSubview(fixedLabel(session.title, width: contentWidth, size: 20, weight: .semibold, color: anchorInkColor, lines: 2))
        let thoughts = app.store.thoughts(for: session.id)
        let note: String
        if session.status == .abandoned {
            note = "已放下 · 存草 \(thoughts.count) 条"
        } else if session.outputNote.isEmpty {
            note = "存草 \(thoughts.count) 条"
        } else {
            note = "产出：\(session.outputNote) · 存草 \(thoughts.count) 条"
        }
        content.addArrangedSubview(fixedLabel(note, width: contentWidth, size: 14, weight: .medium, color: anchorMutedColor, lines: 3))

        let badge = button(statusText(session.status), style: .subtle) {}
        badge.widthAnchor.constraint(equalToConstant: 108).isActive = true

        row.addArrangedSubview(time)
        row.addArrangedSubview(content)
        row.addArrangedSubview(NSView())
        row.addArrangedSubview(badge)
        return row
    }

    func inboxThoughtRow(_ thought: CapturedThought) -> NSView {
        let row = vStack(spacing: 12)
        row.widthAnchor.constraint(equalToConstant: 860).isActive = true
        row.edgeInsets = NSEdgeInsets(top: 18, left: 10, bottom: 18, right: 10)

        let top = hStack(spacing: 16, alignment: .top)
        top.widthAnchor.constraint(equalToConstant: 820).isActive = true

        let content = vStack(spacing: 8)
        content.widthAnchor.constraint(equalToConstant: 560).isActive = true
        content.addArrangedSubview(fixedLabel(thought.content, width: 560, size: 20, weight: .semibold, color: anchorInkColor, lines: 3))
        content.addArrangedSubview(label(shortDateText(thought.createdAt), size: 13, weight: .medium, color: anchorQuietColor))

        let actions = hStack(spacing: 10)
        actions.alignment = .centerY
        let start = compactIconButton("↗", style: .primary, size: 34) { [weak self] in
            self?.app?.startSessionFromThought(thought.id)
        }
        start.toolTip = "开启锚定"
        let discard = compactIconButton("×", style: .subtle, size: 30) { [weak self] in
            self?.confirmDeleteThought(thought)
        }

        top.addArrangedSubview(content)
        let fill = NSView()
        top.addArrangedSubview(fill)
        actions.addArrangedSubview(start)
        actions.addArrangedSubview(discard)
        top.addArrangedSubview(actions)

        row.addArrangedSubview(top)
        return row
    }

    private func confirmDeleteThought(_ thought: CapturedThought) {
        guard let window else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "确定删除这条念头？"
        alert.informativeText = "“\(thought.content)” 删除后不会保留。"
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            self?.app?.deleteThought(thought.id)
        }
    }

    private func reviewHeaderDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M 月 d 日，EEEE"
        return formatter.string(from: date)
    }

    private func reviewPanelTitleText(_ date: Date) -> String {
        Calendar.current.isDateInToday(date) ? "今天的锚定" : "这一天的锚定"
    }

    private func monthStart(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
    }

    private func reviewCalendarPanel(selectedDate: Date, width: CGFloat) -> NSView {
        guard let app else { return NSView() }

        let panel = styledBox(cornerRadius: 30, backgroundColor: anchorPaperColor)
        panel.widthAnchor.constraint(equalToConstant: width).isActive = true
        panel.edgeInsets = NSEdgeInsets(top: 20, left: 18, bottom: 20, right: 18)
        panel.spacing = 14

        let header = hStack(spacing: 8)
        header.widthAnchor.constraint(equalToConstant: width - 36).isActive = true

        let previous = compactIconButton("‹", style: .subtle, size: 28) { [weak self] in
            guard let self else { return }
            self.reviewCalendarMonth = Calendar.current.date(byAdding: .month, value: -1, to: self.reviewCalendarMonth) ?? self.reviewCalendarMonth
            self.refresh(message: "")
        }
        previous.toolTip = "上个月"

        let next = compactIconButton("›", style: .subtle, size: 28) { [weak self] in
            guard let self else { return }
            self.reviewCalendarMonth = Calendar.current.date(byAdding: .month, value: 1, to: self.reviewCalendarMonth) ?? self.reviewCalendarMonth
            self.refresh(message: "")
        }
        next.toolTip = "下个月"

        let monthLabel = label(reviewCalendarMonthText(reviewCalendarMonth), size: 15, weight: .semibold, color: anchorInkColor)

        header.addArrangedSubview(previous)
        header.addArrangedSubview(monthLabel)
        header.addArrangedSubview(NSView())
        header.addArrangedSubview(next)
        panel.addArrangedSubview(header)

        let weekdays = hStack(spacing: 6)
        weekdays.widthAnchor.constraint(equalToConstant: width - 36).isActive = true
        ["一", "二", "三", "四", "五", "六", "日"].forEach { symbol in
            let cell = label(symbol, size: 11, weight: .semibold, color: anchorQuietColor)
            cell.alignment = .center
            cell.widthAnchor.constraint(equalToConstant: 30).isActive = true
            weekdays.addArrangedSubview(cell)
        }
        panel.addArrangedSubview(weekdays)

        let daysWithContent = contentDays(in: reviewCalendarMonth, app: app)
        let calendarGrid = vStack(spacing: 6)
        calendarGrid.widthAnchor.constraint(equalToConstant: width - 36).isActive = true
        for week in calendarRows(for: reviewCalendarMonth) {
            let row = hStack(spacing: 6)
            row.widthAnchor.constraint(equalToConstant: width - 36).isActive = true
            for day in week {
                row.addArrangedSubview(calendarDayCell(date: day, selectedDate: selectedDate, markedDays: daysWithContent))
            }
            calendarGrid.addArrangedSubview(row)
        }
        panel.addArrangedSubview(calendarGrid)

        return panel
    }

    private func reviewCalendarMonthText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 M 月"
        return formatter.string(from: date)
    }

    private func calendarRows(for month: Date) -> [[Date?]] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let dayRange = calendar.range(of: .day, in: .month, for: month) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: month)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7

        var entries = Array(repeating: Optional<Date>.none, count: leading)
        for day in dayRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: month) {
                entries.append(calendar.startOfDay(for: date))
            }
        }
        while entries.count % 7 != 0 {
            entries.append(nil)
        }

        return stride(from: 0, to: entries.count, by: 7).map { index in
            Array(entries[index ..< min(index + 7, entries.count)])
        }
    }

    private func contentDays(in month: Date, app: AppDelegate) -> Set<Date> {
        let calendar = Calendar.current
        return Set(
            app.store.state.sessions
                .filter { calendar.isDate($0.startedAt, equalTo: month, toGranularity: .month) }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )
    }

    private func calendarDayCell(date: Date?, selectedDate: Date, markedDays: Set<Date>) -> NSView {
        guard let date else {
            let blank = NSView()
            blank.translatesAutoresizingMaskIntoConstraints = false
            blank.widthAnchor.constraint(equalToConstant: 30).isActive = true
            blank.heightAnchor.constraint(equalToConstant: 30).isActive = true
            return blank
        }

        let calendar = Calendar.current
        let hasContent = markedDays.contains(calendar.startOfDay(for: date))
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let cell = ClosureButton(title: "\(calendar.component(.day, from: date))", target: nil, action: nil)
        cell.isBordered = false
        cell.translatesAutoresizingMaskIntoConstraints = false
        cell.widthAnchor.constraint(equalToConstant: 30).isActive = true
        cell.heightAnchor.constraint(equalToConstant: 30).isActive = true
        cell.target = cell
        cell.action = #selector(ClosureButton.triggerClick)
        cell.onClick = { [weak self] in
            self?.app?.reviewReferenceDate = calendar.startOfDay(for: date)
            self?.reviewCalendarMonth = self?.monthStart(for: date) ?? date
            self?.refresh(message: "")
        }
        cell.wantsLayer = true
        cell.layer?.cornerRadius = 15
        cell.layer?.borderWidth = 1
        cell.layer?.shadowColor = NSColor.black.withAlphaComponent(0.03).cgColor
        cell.layer?.shadowOpacity = 1
        cell.layer?.shadowRadius = 4
        cell.layer?.shadowOffset = NSSize(width: 0, height: -1)

        if isSelected {
            cell.layer?.backgroundColor = starlightSoftColor.withAlphaComponent(0.95).cgColor
            cell.layer?.borderColor = starlightColor.withAlphaComponent(0.45).cgColor
        } else if hasContent {
            cell.layer?.backgroundColor = starlightGhostColor.withAlphaComponent(0.72).cgColor
            cell.layer?.borderColor = starlightColor.withAlphaComponent(0.22).cgColor
        } else {
            cell.layer?.backgroundColor = anchorPaperWhiteColor.cgColor
            cell.layer?.borderColor = anchorSoftColor.withAlphaComponent(0.55).cgColor
        }

        cell.attributedTitle = NSAttributedString(
            string: "\(calendar.component(.day, from: date))",
            attributes: [
                .font: anchorFont(.mono, size: 13, weight: .semibold),
                .foregroundColor: isSelected ? anchorInkColor : (hasContent ? anchorInkColor : anchorMutedColor)
            ]
        )
        return cell
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

    func updateTimerOnly() {
        guard let session = app?.store.currentSession() else { return }
        timerLabel?.stringValue = formatRemaining(session)
        elapsedLabel?.stringValue = "已进行 \(formatElapsed(session))"
    }

    func showMessage(_ message: String) {
        messageLabel?.stringValue = message
        messageWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.messageLabel?.stringValue = ""
        }
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

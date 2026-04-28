import AppKit

final class CaptureWindowController: NSWindowController {
    weak var app: AppDelegate?
    let canvasView = PaperCanvasView()
    let stack = NSStackView()
    var input: MultilineInput?
    var closeWorkItem: DispatchWorkItem?

    init(app: AppDelegate) {
        self.app = app
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 320),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = "星光停靠"
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
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        canvasView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = canvasView

        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 22, left: 20, bottom: 18, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        canvasView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: canvasView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: canvasView.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: canvasView.bottomAnchor)
        ])

        refreshContent()
    }

    func refreshContent(message: String? = nil) {
        guard let app else { return }
        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let dish = styledBox(cornerRadius: 26, backgroundColor: anchorPaperColor)
        dish.alignment = .leading
        dish.widthAnchor.constraint(equalToConstant: 420).isActive = true

        let titleRow = hStack(spacing: 8)
        titleRow.widthAnchor.constraint(equalToConstant: 372).isActive = true
        titleRow.addArrangedSubview(label("✦", size: 20, weight: .semibold, color: starlightColor))
        titleRow.addArrangedSubview(label("星光停靠", size: 18, weight: .semibold, color: anchorInkColor))
        dish.addArrangedSubview(titleRow)

        let input = MultilineInput(placeholder: "把刚冒出来的念头轻轻放下", width: 372, height: 120)
        self.input = input
        input.textView.onCommandReturn = { [weak self] in self?.submitThought() }
        dish.addArrangedSubview(input.containerView)

        let targetText: String
        if let session = app.store.currentSession(), session.status == .running || session.status == .paused {
            targetText = "将收进：\(session.title) 的收草棚"
        } else {
            targetText = "将收进：收件箱"
        }
        dish.addArrangedSubview(label(targetText, size: 13, weight: .medium, color: anchorQuietColor))

        if let message {
            dish.addArrangedSubview(label(message, size: 14, weight: .medium, color: anchorMutedColor))
        }

        let actions = hStack(spacing: 10)
        actions.addArrangedSubview(button("关", style: .subtle) { [weak self] in self?.close() })
        actions.addArrangedSubview(button("存草", style: .primary) { [weak self] in self?.submitThought() })
        dish.addArrangedSubview(actions)

        stack.addArrangedSubview(dish)
    }

    func focusInput() {
        closeWorkItem?.cancel()
        input?.textView.string = ""
        input?.textView.syncPlaceholder()
        window?.makeFirstResponder(input?.textView)
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
        refreshContent()
        focusInput()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    @objc func submitThought() {
        let text = input?.textView.string.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }
        app?.parkThought(text)
        refreshContent(message: successMessage())

        closeWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.window?.close() }
        closeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }

    func successMessage() -> String {
        if let session = app?.store.currentSession(), session.status == .running || session.status == .paused {
            return "刚刚接住了。回去继续：\(session.title)"
        }
        return "刚刚接住了。"
    }
}

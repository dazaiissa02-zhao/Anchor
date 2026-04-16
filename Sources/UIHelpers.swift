import AppKit
import Foundation

enum ButtonStyle {
    case primary
    case secondary
    case danger
}

final class MultilineInput {
    let scrollView: NSScrollView
    let textView: CommandReturnTextView

    init(placeholder: String) {
        textView = CommandReturnTextView()
        textView.font = NSFont.systemFont(ofSize: 15, weight: .regular)
        textView.textColor = anchorInkColor
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 10, height: 9)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 500, height: CGFloat.greatestFiniteMagnitude)
        textView.string = ""

        scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.wantsLayer = true
        scrollView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.84).cgColor
        scrollView.layer?.cornerRadius = 8
        scrollView.layer?.borderWidth = 1
        scrollView.layer?.borderColor = anchorSoftColor.cgColor
        scrollView.heightAnchor.constraint(equalToConstant: 92).isActive = true
        scrollView.widthAnchor.constraint(equalToConstant: 520).isActive = true

        textView.setAccessibilityPlaceholderValue(placeholder)
    }
}

final class CommandReturnTextView: NSTextView {
    var onCommandReturn: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        let isCommandReturn = event.modifierFlags.contains(.command) && (event.keyCode == 36 || event.keyCode == 76)
        if isCommandReturn {
            onCommandReturn?()
            return
        }
        super.keyDown(with: event)
    }
}

func label(_ text: String, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = .labelColor) -> NSTextField {
    let field = NSTextField(labelWithString: text)
    field.font = NSFont.systemFont(ofSize: size, weight: weight)
    field.textColor = color
    field.lineBreakMode = .byWordWrapping
    field.maximumNumberOfLines = 0
    return field
}

func input(_ label: String, placeholder: String) -> NSTextField {
    let field = NSTextField()
    field.placeholderString = placeholder
    field.heightAnchor.constraint(equalToConstant: 34).isActive = true
    return field
}

func multilineInput(placeholder: String) -> MultilineInput {
    MultilineInput(placeholder: placeholder)
}

func formRow(_ title: String, _ view: NSView, trailing: NSView? = nil, hint: String? = nil) -> NSView {
    let wrapper = NSStackView()
    wrapper.orientation = .vertical
    wrapper.spacing = 7
    wrapper.alignment = .leading
    wrapper.widthAnchor.constraint(equalToConstant: 520).isActive = true
    wrapper.addArrangedSubview(label(title, size: 12, weight: .semibold, color: anchorMutedColor))
    if let hint {
        wrapper.addArrangedSubview(label(hint, size: 12, color: anchorQuietColor))
    }
    if let trailing {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        row.addArrangedSubview(view)
        row.addArrangedSubview(trailing)
        wrapper.addArrangedSubview(row)
    } else {
        wrapper.addArrangedSubview(view)
    }
    return wrapper
}

func button(_ title: String, style: ButtonStyle, action: @escaping () -> Void) -> NSButton {
    let button = ClosureButton(title: title, target: nil, action: nil)
    button.isBordered = false
    button.wantsLayer = true
    button.layer?.cornerRadius = 8
    button.heightAnchor.constraint(equalToConstant: 36).isActive = true
    button.widthAnchor.constraint(greaterThanOrEqualToConstant: max(76, CGFloat(title.count * 14 + 28))).isActive = true
    button.target = button
    button.action = #selector(ClosureButton.triggerClick)
    button.onClick = action
    let backgroundColor: NSColor
    let textColor: NSColor
    switch style {
    case .primary:
        backgroundColor = starlightColor
        textColor = anchorInkColor
    case .danger:
        backgroundColor = anchorDangerColor.withAlphaComponent(0.10)
        textColor = anchorDangerColor
    case .secondary:
        backgroundColor = anchorSoftColor
        textColor = anchorInkColor
    }
    button.layer?.backgroundColor = backgroundColor.cgColor
    button.attributedTitle = NSAttributedString(
        string: title,
        attributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: textColor
        ]
    )
    return button
}

final class ClosureButton: NSButton {
    var onClick: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        target = self
        action = #selector(triggerClick)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        target = self
        action = #selector(triggerClick)
    }

    @objc func triggerClick() {
        onClick?()
    }
}

func separator() -> NSBox {
    let box = NSBox()
    box.boxType = .separator
    return box
}

func makeId(_ prefix: String) -> String {
    "\(prefix)_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6))"
}

func shortDateText(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm"
    return formatter.string(from: date)
}

func elapsedSeconds(_ session: FocusSession, now: Date = Date()) -> TimeInterval {
    let activeEnd: Date
    if session.status == .paused {
        activeEnd = session.pausedAt ?? now
    } else if session.status == .running {
        activeEnd = now
    } else {
        activeEnd = session.endedAt ?? now
    }
    return max(0, activeEnd.timeIntervalSince(session.startedAt) - session.totalPausedSeconds)
}

func remainingSeconds(_ session: FocusSession) -> TimeInterval {
    TimeInterval(session.durationMinutes * 60) - elapsedSeconds(session)
}

func formatRemaining(_ session: FocusSession) -> String {
    let seconds = max(0, Int(ceil(remainingSeconds(session))))
    let minutes = seconds / 60
    let rest = seconds % 60
    return String(format: "%02d:%02d", minutes, rest)
}

func formatElapsed(_ session: FocusSession) -> String {
    let seconds = max(0, Int(floor(elapsedSeconds(session))))
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let rest = seconds % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, rest)
    }
    return String(format: "%02d:%02d", minutes, rest)
}

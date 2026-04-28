import AppKit
import Foundation

enum ButtonStyle {
    case primary
    case secondary
    case subtle
    case danger
}

enum AnchorFontKind {
    case display
    case serif
    case chinese
    case mono
}

func anchorFont(_ kind: AnchorFontKind, size: CGFloat, weight: NSFont.Weight = .regular, italic: Bool = false) -> NSFont {
    let candidates: [String]
    switch kind {
    case .display:
        candidates = ["Cormorant Garamond SemiBold", "Cormorant Garamond", "Times New Roman"]
    case .serif:
        candidates = ["EB Garamond", "Noto Serif SC", "Songti SC"]
    case .chinese:
        candidates = ["Noto Serif SC SemiBold", "Noto Serif SC", "Songti SC", "STSong"]
    case .mono:
        candidates = ["JetBrains Mono", "SF Mono", "Menlo"]
    }

    let base = candidates.compactMap { NSFont(name: $0, size: size) }.first
        ?? NSFont.systemFont(ofSize: size, weight: weight)

    let descriptor = base.fontDescriptor
    let withTraits = italic ? descriptor.withSymbolicTraits(.italic) : descriptor
    return NSFont(descriptor: withTraits, size: size) ?? base
}

final class PaperCanvasView: NSView {
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        anchorBackgroundColor.setFill()
        dirtyRect.fill()

        let bounds = self.bounds
        let highlight = NSGradient(colors: [
            starlightGhostColor.withAlphaComponent(0.55),
            anchorBackgroundColor.withAlphaComponent(0.0)
        ])
        highlight?.draw(fromCenter: NSPoint(x: bounds.midX, y: bounds.height * 0.24), radius: 12, toCenter: NSPoint(x: bounds.midX, y: bounds.height * 0.24), radius: bounds.width * 0.48, options: [])

        anchorFaintColor.withAlphaComponent(0.12).setStroke()
        let grid = NSBezierPath()
        stride(from: CGFloat(0), through: bounds.width, by: 34).forEach { x in
            grid.move(to: NSPoint(x: x, y: 0))
            grid.line(to: NSPoint(x: x, y: bounds.height))
        }
        grid.lineWidth = 1
        grid.stroke()
    }
}

final class AnchorTextField: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isBordered = false
        isBezeled = false
        drawsBackground = false
        focusRingType = .none
        backgroundColor = .clear
        textColor = anchorInkColor
        font = anchorFont(.chinese, size: 22, weight: .medium)
        cell?.usesSingleLineMode = true
        lineBreakMode = .byTruncatingTail
    }
}

class CommandReturnTextView: NSTextView {
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

final class PlaceholderTextView: CommandReturnTextView {
    weak var placeholderField: NSTextField?

    override func didChangeText() {
        super.didChangeText()
        syncPlaceholder()
    }

    func syncPlaceholder() {
        placeholderField?.isHidden = !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

final class TextFocusContainerView: NSView {
    weak var targetTextView: NSTextView?

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(targetTextView)
    }
}

final class PassthroughLabelField: NSTextField {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

final class MultilineInput {
    let containerView: NSView
    let scrollView: NSScrollView
    let textView: PlaceholderTextView
    let placeholderLabel: NSTextField

    init(placeholder: String, width: CGFloat = 640, height: CGFloat = 92) {
        textView = PlaceholderTextView()
        textView.font = anchorFont(.chinese, size: 20, weight: .medium)
        textView.textColor = anchorInkColor
        textView.drawsBackground = false
        textView.focusRingType = .none
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: width - 40, height: .greatestFiniteMagnitude)
        textView.string = ""

        scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let focusView = TextFocusContainerView()
        focusView.targetTextView = textView
        containerView = focusView
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = anchorPaperWhiteColor.cgColor
        containerView.layer?.cornerRadius = 18
        containerView.layer?.borderColor = anchorSoftColor.withAlphaComponent(0.7).cgColor
        containerView.layer?.borderWidth = 1
        containerView.layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
        containerView.layer?.shadowOpacity = 1
        containerView.layer?.shadowRadius = 10
        containerView.layer?.shadowOffset = NSSize(width: 0, height: -2)

        placeholderLabel = PassthroughLabelField(labelWithString: placeholder)
        placeholderLabel.font = anchorFont(.chinese, size: 18, weight: .medium)
        placeholderLabel.textColor = anchorQuietColor
        placeholderLabel.maximumNumberOfLines = 0
        placeholderLabel.backgroundColor = .clear
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(scrollView)
        containerView.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: width),
            containerView.heightAnchor.constraint(equalToConstant: height),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),
            placeholderLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            placeholderLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20)
        ])

        textView.placeholderField = placeholderLabel
        textView.setAccessibilityPlaceholderValue(placeholder)
        textView.syncPlaceholder()
    }
}

func label(_ text: String, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = .labelColor) -> NSTextField {
    let field = NSTextField(labelWithString: text)
    field.font = anchorFont(.chinese, size: size, weight: weight)
    field.textColor = color
    field.lineBreakMode = .byWordWrapping
    field.maximumNumberOfLines = 0
    field.backgroundColor = .clear
    return field
}

func displayLabel(_ text: String, size: CGFloat, color: NSColor = anchorInkColor, italic: Bool = false) -> NSTextField {
    let field = NSTextField(labelWithString: text)
    field.font = anchorFont(.display, size: size, weight: .semibold, italic: italic)
    field.textColor = color
    field.maximumNumberOfLines = 0
    return field
}

func monoLabel(_ text: String, size: CGFloat, color: NSColor = anchorInkColor) -> NSTextField {
    let field = NSTextField(labelWithString: text)
    field.font = anchorFont(.mono, size: size, weight: .medium)
    field.textColor = color
    field.maximumNumberOfLines = 1
    return field
}

func input(_ label: String, placeholder: String) -> NSTextField {
    let field = AnchorTextField()
    field.identifier = NSUserInterfaceItemIdentifier(label)
    field.placeholderAttributedString = NSAttributedString(
        string: placeholder,
        attributes: [
            .font: anchorFont(.chinese, size: 16, weight: .medium),
            .foregroundColor: anchorQuietColor
        ]
    )
    field.heightAnchor.constraint(equalToConstant: 44).isActive = true
    return field
}

func multilineInput(placeholder: String) -> MultilineInput {
    MultilineInput(placeholder: placeholder)
}

func formRow(_ title: String, _ view: NSView, trailing: NSView? = nil, hint: String? = nil, width: CGFloat = 520) -> NSView {
    let wrapper = vStack(spacing: 8)
    wrapper.alignment = .leading
    wrapper.widthAnchor.constraint(equalToConstant: width).isActive = true
    wrapper.addArrangedSubview(label(title, size: 13, weight: .semibold, color: anchorMutedColor))
    if let hint {
        wrapper.addArrangedSubview(label(hint, size: 12, weight: .medium, color: anchorQuietColor))
    }
    if let trailing {
        let row = hStack(spacing: 10)
        row.addArrangedSubview(view)
        row.addArrangedSubview(trailing)
        wrapper.addArrangedSubview(row)
    } else {
        wrapper.addArrangedSubview(view)
    }
    return wrapper
}

func button(_ title: String, style: ButtonStyle, action: @escaping () -> Void) -> NSButton {
    let control = ClosureButton(title: title, target: nil, action: nil)
    control.isBordered = false
    control.bezelStyle = .regularSquare
    control.translatesAutoresizingMaskIntoConstraints = false
    control.heightAnchor.constraint(equalToConstant: 50).isActive = true
    control.widthAnchor.constraint(greaterThanOrEqualToConstant: max(96, CGFloat(title.count) * 16 + 38)).isActive = true
    control.target = control
    control.action = #selector(ClosureButton.triggerClick)
    control.onClick = action
    applyButtonStyle(control, style: style)
    control.attributedTitle = NSAttributedString(
        string: title,
        attributes: [
            .font: anchorFont(.chinese, size: 15, weight: .semibold),
            .foregroundColor: buttonTitleColor(style)
        ]
    )
    return control
}

func iconButton(_ title: String, style: ButtonStyle = .subtle, action: @escaping () -> Void) -> NSButton {
    let control = ClosureButton(title: title, target: nil, action: nil)
    control.isBordered = false
    control.translatesAutoresizingMaskIntoConstraints = false
    control.heightAnchor.constraint(equalToConstant: 36).isActive = true
    control.widthAnchor.constraint(equalToConstant: 36).isActive = true
    control.target = control
    control.action = #selector(ClosureButton.triggerClick)
    control.onClick = action
    control.toolTip = title
    applyButtonStyle(control, style: style, cornerRadius: 18)
    control.attributedTitle = NSAttributedString(
        string: title,
        attributes: [
            .font: anchorFont(.mono, size: 13, weight: .semibold),
            .foregroundColor: buttonTitleColor(style)
        ]
    )
    return control
}

func compactButton(_ title: String, style: ButtonStyle, width: CGFloat? = nil, action: @escaping () -> Void) -> NSButton {
    let control = ClosureButton(title: title, target: nil, action: nil)
    control.isBordered = false
    control.translatesAutoresizingMaskIntoConstraints = false
    control.heightAnchor.constraint(equalToConstant: 38).isActive = true
    control.widthAnchor.constraint(greaterThanOrEqualToConstant: width ?? max(84, CGFloat(title.count) * 14 + 24)).isActive = true
    control.target = control
    control.action = #selector(ClosureButton.triggerClick)
    control.onClick = action
    applyButtonStyle(control, style: style, cornerRadius: 19)
    control.layer?.shadowRadius = 5
    control.attributedTitle = NSAttributedString(
        string: title,
        attributes: [
            .font: anchorFont(.chinese, size: 13, weight: .semibold),
            .foregroundColor: buttonTitleColor(style)
        ]
    )
    return control
}

func compactIconButton(_ title: String, style: ButtonStyle, size: CGFloat = 30, action: @escaping () -> Void) -> NSButton {
    let control = ClosureButton(title: title, target: nil, action: nil)
    control.isBordered = false
    control.translatesAutoresizingMaskIntoConstraints = false
    control.heightAnchor.constraint(equalToConstant: size).isActive = true
    control.widthAnchor.constraint(equalToConstant: size).isActive = true
    control.target = control
    control.action = #selector(ClosureButton.triggerClick)
    control.onClick = action
    applyButtonStyle(control, style: style, cornerRadius: size / 2)
    control.layer?.shadowRadius = 4
    control.attributedTitle = NSAttributedString(
        string: title,
        attributes: [
            .font: anchorFont(.mono, size: max(11, size * 0.35), weight: .semibold),
            .foregroundColor: buttonTitleColor(style)
        ]
    )
    return control
}

func selectablePillButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> NSButton {
    let control = ClosureButton(title: title, target: nil, action: nil)
    control.isBordered = false
    control.translatesAutoresizingMaskIntoConstraints = false
    control.heightAnchor.constraint(equalToConstant: 42).isActive = true
    control.widthAnchor.constraint(greaterThanOrEqualToConstant: max(52, CGFloat(title.count) * 14 + 30)).isActive = true
    control.target = control
    control.action = #selector(ClosureButton.triggerClick)
    control.onClick = action
    control.wantsLayer = true
    control.layer?.cornerRadius = 21
    control.layer?.borderWidth = selected ? 0 : 1
    control.layer?.borderColor = anchorSoftColor.cgColor
    control.layer?.backgroundColor = (selected ? starlightSoftColor.withAlphaComponent(0.92) : anchorPaperWhiteColor).cgColor
    control.attributedTitle = NSAttributedString(
        string: title,
        attributes: [
            .font: anchorFont(.mono, size: 15, weight: .semibold),
            .foregroundColor: selected ? anchorInkColor : anchorMutedColor
        ]
    )
    return control
}

func buttonTitleColor(_ style: ButtonStyle) -> NSColor {
    switch style {
    case .primary, .secondary:
        return anchorInkColor
    case .subtle:
        return anchorMutedColor
    case .danger:
        return anchorDangerColor
    }
}

func applyButtonStyle(_ button: NSButton, style: ButtonStyle, cornerRadius: CGFloat = 25) {
    button.wantsLayer = true
    button.layer?.cornerRadius = cornerRadius
    button.layer?.borderWidth = 1
    button.layer?.shadowColor = NSColor.black.withAlphaComponent(0.04).cgColor
    button.layer?.shadowOpacity = 1
    button.layer?.shadowRadius = 8
    button.layer?.shadowOffset = NSSize(width: 0, height: -2)

    switch style {
    case .primary:
        button.layer?.backgroundColor = starlightSoftColor.withAlphaComponent(0.95).cgColor
        button.layer?.borderColor = starlightColor.withAlphaComponent(0.4).cgColor
    case .secondary:
        button.layer?.backgroundColor = anchorPaperWhiteColor.withAlphaComponent(0.9).cgColor
        button.layer?.borderColor = anchorSoftColor.withAlphaComponent(0.8).cgColor
    case .subtle:
        button.layer?.backgroundColor = anchorPaperSoftColor.withAlphaComponent(0.92).cgColor
        button.layer?.borderColor = anchorSoftColor.withAlphaComponent(0.55).cgColor
    case .danger:
        button.layer?.backgroundColor = NSColor(calibratedRed: 0.97, green: 0.92, blue: 0.89, alpha: 1).cgColor
        button.layer?.borderColor = anchorDangerColor.withAlphaComponent(0.18).cgColor
    }
}

func vStack(spacing: CGFloat = 12, alignment: NSLayoutConstraint.Attribute = .leading) -> NSStackView {
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.spacing = spacing
    stack.alignment = alignment
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
}

func hStack(spacing: CGFloat = 10, alignment: NSLayoutConstraint.Attribute = .centerY) -> NSStackView {
    let stack = NSStackView()
    stack.orientation = .horizontal
    stack.spacing = spacing
    stack.alignment = alignment
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
}

func fixedLabel(
    _ text: String,
    width: CGFloat,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = .labelColor,
    lines: Int = 0
) -> NSTextField {
    let field = label(text, size: size, weight: weight, color: color)
    field.maximumNumberOfLines = lines
    field.preferredMaxLayoutWidth = width
    field.widthAnchor.constraint(equalToConstant: width).isActive = true
    return field
}

func styledBox(
    cornerRadius: CGFloat = 24,
    backgroundColor: NSColor = anchorPaperColor,
    borderColor: NSColor = anchorSoftColor,
    borderWidth: CGFloat = 1
) -> NSStackView {
    let box = vStack(spacing: 14)
    box.edgeInsets = NSEdgeInsets(top: 22, left: 22, bottom: 22, right: 22)
    box.wantsLayer = true
    box.layer?.cornerRadius = cornerRadius
    box.layer?.backgroundColor = backgroundColor.cgColor
    box.layer?.borderColor = borderColor.withAlphaComponent(0.6).cgColor
    box.layer?.borderWidth = borderWidth
    box.layer?.shadowColor = NSColor.black.withAlphaComponent(0.05).cgColor
    box.layer?.shadowOpacity = 1
    box.layer?.shadowRadius = 24
    box.layer?.shadowOffset = NSSize(width: 0, height: -3)
    return box
}

func clickableBox(
    cornerRadius: CGFloat = 24,
    backgroundColor: NSColor = anchorPaperColor,
    borderColor: NSColor = anchorSoftColor,
    borderWidth: CGFloat = 1,
    action: @escaping () -> Void
) -> ClickableStackView {
    let box = ClickableStackView()
    box.orientation = .vertical
    box.spacing = 12
    box.alignment = .leading
    box.edgeInsets = NSEdgeInsets(top: 22, left: 22, bottom: 22, right: 22)
    box.wantsLayer = true
    box.layer?.cornerRadius = cornerRadius
    box.layer?.backgroundColor = backgroundColor.cgColor
    box.layer?.borderColor = borderColor.withAlphaComponent(0.6).cgColor
    box.layer?.borderWidth = borderWidth
    box.layer?.shadowColor = NSColor.black.withAlphaComponent(0.04).cgColor
    box.layer?.shadowOpacity = 1
    box.layer?.shadowRadius = 18
    box.layer?.shadowOffset = NSSize(width: 0, height: -2)
    box.onClick = action
    return box
}

func spacer(height: CGFloat) -> NSView {
    let view = NSView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalToConstant: height).isActive = true
    return view
}

func pill(_ text: String, selected: Bool = false) -> NSTextField {
    let field = monoLabel(text, size: 14, color: selected ? anchorInkColor : anchorMutedColor)
    field.alignment = .center
    field.wantsLayer = true
    field.layer?.cornerRadius = 19
    field.layer?.backgroundColor = (selected ? starlightSoftColor.withAlphaComponent(0.9) : anchorPaperWhiteColor).cgColor
    field.layer?.borderColor = anchorSoftColor.cgColor
    field.layer?.borderWidth = selected ? 0 : 1
    field.heightAnchor.constraint(equalToConstant: 38).isActive = true
    field.widthAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
    return field
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

final class ClosureMenuItem: NSMenuItem {
    var onSelect: (() -> Void)?

    init(title: String, action: @escaping () -> Void) {
        self.onSelect = action
        super.init(title: title, action: #selector(triggerSelect), keyEquivalent: "")
        target = self
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        target = self
        action = #selector(triggerSelect)
    }

    @objc func triggerSelect() {
        onSelect?()
    }
}

final class ClickableStackView: NSStackView {
    var onClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

func separator() -> NSBox {
    let box = NSBox()
    box.boxType = .separator
    box.borderColor = anchorFaintColor.withAlphaComponent(0.35)
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

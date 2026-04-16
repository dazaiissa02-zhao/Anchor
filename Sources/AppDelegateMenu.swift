import AppKit

extension AppDelegate {
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon()
        rebuildMenu()
    }

    func updateStatusIcon() {
        let title: String
        switch store.currentSession()?.status {
        case .running:
            title = "★"
        case .paused:
            title = "☆"
        case .reviewing:
            title = "✦"
        default:
            title = "☆"
        }
        statusItem.button?.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: starlightColor,
                .font: NSFont.systemFont(ofSize: 16, weight: .bold)
            ]
        )
        statusItem.button?.toolTip = "锚点"
    }

    func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(viewItem(statusMenuView()))
        menu.addItem(.separator())
        menu.addItem(item("◎ 打开锚点", #selector(showMainWindowFromMenu)))
        menu.addItem(item("✦ 停靠想法", #selector(showCaptureFromMenu)))
        let pauseTitle = store.currentSession()?.status == .paused ? "▶ 继续" : "Ⅱ 暂停"
        let pauseItem = item(pauseTitle, #selector(togglePauseFromMenu))
        pauseItem.isEnabled = {
            guard let status = store.currentSession()?.status else { return false }
            return status == .running || status == .paused
        }()
        menu.addItem(pauseItem)
        let reviewItem = item("■ 结束并复盘", #selector(finishFromMenu))
        reviewItem.isEnabled = {
            guard let status = store.currentSession()?.status else { return false }
            return status == .running || status == .paused || status == .reviewing
        }()
        menu.addItem(reviewItem)
        let abandonItem = item("× 放弃当前锚点", #selector(abandonFromMenu))
        abandonItem.isEnabled = store.currentSession() != nil
        menu.addItem(abandonItem)
        menu.addItem(.separator())
        menu.addItem(item("开启通知", #selector(requestNotificationsFromMenu)))
        menu.addItem(item("导出 JSON", #selector(revealDataFileFromMenu)))
        menu.addItem(.separator())
        menu.addItem(item("退出", #selector(quitFromMenu)))
        statusItem.menu = menu
    }

    func statusMenuView() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 18, bottom: 12, right: 18)
        stack.widthAnchor.constraint(equalToConstant: 280).isActive = true

        if let session = store.currentSession() {
            stack.addArrangedSubview(menuStatusLabel("现在：\(session.title)", size: 17, weight: .semibold, color: .labelColor))
            stack.addArrangedSubview(menuStatusLabel("下一步：\(session.nextAction)", size: 17, weight: .semibold, color: starlightColor))
            stack.addArrangedSubview(menuStatusLabel("剩余：\(formatRemaining(session))", size: 18, weight: .bold, color: starlightColor))
            stack.addArrangedSubview(menuStatusLabel("已进行：\(formatElapsed(session))", size: 14, weight: .regular, color: anchorMutedColor))
        } else {
            stack.addArrangedSubview(menuStatusLabel("还没有当前锚点", size: 17, weight: .semibold, color: .labelColor))
            stack.addArrangedSubview(menuStatusLabel("先开始一段任务", size: 15, weight: .regular, color: starlightColor))
        }

        return stack
    }

    func viewItem(_ view: NSView) -> NSMenuItem {
        let item = NSMenuItem()
        item.view = view
        return item
    }

    func menuStatusLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: size, weight: weight)
        field.textColor = color
        field.lineBreakMode = .byTruncatingTail
        field.maximumNumberOfLines = 1
        return field
    }

    func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = self
        return menuItem
    }

    @objc func showMainWindowFromMenu() { showMainWindow() }
    @objc func showCaptureFromMenu() { showCapture() }
    @objc func togglePauseFromMenu() { togglePause() }
    @objc func finishFromMenu() { finishSession() }
    @objc func abandonFromMenu() { abandonSession() }
    @objc func requestNotificationsFromMenu() { requestNotifications() }
    @objc func revealDataFileFromMenu() { NSWorkspace.shared.activateFileViewerSelecting([store.fileURL]) }
    @objc func quitFromMenu() { NSApp.terminate(nil) }
}

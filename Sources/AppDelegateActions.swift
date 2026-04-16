import AppKit
import UserNotifications

extension AppDelegate {
    func fireReminder(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: makeId("notification"), content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.refreshAll(message: granted ? "通知已开启。" : "通知没有开启。")
            }
        }
    }

    func refreshAll(message: String) {
        updateStatusIcon()
        rebuildMenu()
        mainWindow.refresh(message: message)
    }

    func showMainWindow() {
        mainWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showCapture() {
        NSApp.activate(ignoringOtherApps: true)
        captureWindow.present()
    }
}

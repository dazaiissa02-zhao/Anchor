import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let store = DataStore()
    var statusItem: NSStatusItem!
    var mainWindow: MainWindowController!
    var captureWindow: CaptureWindowController!
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        mainWindow = MainWindowController(app: self)
        captureWindow = CaptureWindowController(app: self)
        setupStatusItem()
        HotKeyCenter.shared.onCapture = { [weak self] in self?.showCapture() }
        HotKeyCenter.shared.register()
        startTicker()
        showMainWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.save()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

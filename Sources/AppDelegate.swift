import AppKit
import UserNotifications

enum MainSurface {
    case focus
    case todayReview
    case inbox
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let store = DataStore()
    var statusItem: NSStatusItem!
    var mainWindow: MainWindowController!
    var captureWindow: CaptureWindowController!
    var todayReviewWindow: TodayReviewWindowController!
    var inboxWindow: InboxWindowController!
    var statusPopover: NSPopover!
    var timer: Timer?
    var delayedReviewWorkItem: DispatchWorkItem?
    var pendingAnchorTitle: String?
    var pendingReturnNote: String?
    var mainSurface: MainSurface = .focus
    var reviewReferenceDate: Date = Calendar.current.startOfDay(for: Date())

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        mainWindow = MainWindowController(app: self)
        captureWindow = CaptureWindowController(app: self)
        todayReviewWindow = TodayReviewWindowController(app: self)
        inboxWindow = InboxWindowController(app: self)
        statusPopover = NSPopover()
        statusPopover.behavior = .transient
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

import AppKit
import Carbon
import UserNotifications

let reminderInterval: TimeInterval = 5 * 60
let thoughtSpikeWindow: TimeInterval = 5 * 60
let thoughtSpikeThreshold = 3
let normalCooldownAfterCapture: TimeInterval = 60
let strongReminderCooldown: TimeInterval = 10 * 60
let starlightColor = NSColor(calibratedRed: 0.83, green: 0.63, blue: 0.09, alpha: 1)
let starlightSoftColor = NSColor(calibratedRed: 0.96, green: 0.87, blue: 0.60, alpha: 1)
let starlightGhostColor = NSColor(calibratedRed: 0.98, green: 0.94, blue: 0.82, alpha: 1)

let anchorInkColor = NSColor(calibratedRed: 0.16, green: 0.12, blue: 0.07, alpha: 1)
let anchorDarkColor = NSColor(calibratedRed: 0.24, green: 0.18, blue: 0.11, alpha: 1)
let anchorMutedColor = NSColor(calibratedRed: 0.42, green: 0.35, blue: 0.22, alpha: 1)
let anchorQuietColor = NSColor(calibratedRed: 0.61, green: 0.54, blue: 0.42, alpha: 1)
let anchorFaintColor = NSColor(calibratedRed: 0.75, green: 0.69, blue: 0.56, alpha: 1)

let anchorPaperWhiteColor = NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.94, alpha: 1)
let anchorPaperColor = NSColor(calibratedRed: 0.97, green: 0.95, blue: 0.88, alpha: 1)
let anchorPaperSoftColor = NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.91, alpha: 1)
let anchorPaperDeepColor = NSColor(calibratedRed: 0.91, green: 0.86, blue: 0.77, alpha: 1)
let anchorBackgroundColor = NSColor(calibratedRed: 0.95, green: 0.91, blue: 0.84, alpha: 1)
let anchorSoftColor = NSColor(calibratedRed: 0.88, green: 0.81, blue: 0.69, alpha: 1)

let anchorJadeColor = NSColor(calibratedRed: 0.42, green: 0.50, blue: 0.34, alpha: 1)
let anchorJadeSoftColor = NSColor(calibratedRed: 0.83, green: 0.86, blue: 0.77, alpha: 1)
let anchorDangerColor = NSColor(calibratedRed: 0.66, green: 0.24, blue: 0.17, alpha: 1)

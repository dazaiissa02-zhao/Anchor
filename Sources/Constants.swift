import AppKit
import Carbon
import UserNotifications

let reminderInterval: TimeInterval = 5 * 60
let thoughtSpikeWindow: TimeInterval = 5 * 60
let thoughtSpikeThreshold = 3
let normalCooldownAfterCapture: TimeInterval = 60
let strongReminderCooldown: TimeInterval = 10 * 60
let starlightColor = NSColor(calibratedRed: 0.98, green: 0.73, blue: 0.18, alpha: 1)
let anchorInkColor = NSColor(calibratedWhite: 0.16, alpha: 1)
let anchorMutedColor = NSColor(calibratedWhite: 0.48, alpha: 1)
let anchorQuietColor = NSColor(calibratedWhite: 0.66, alpha: 1)
let anchorSoftColor = NSColor(calibratedWhite: 0.93, alpha: 1)
let anchorBackgroundColor = NSColor(calibratedWhite: 0.985, alpha: 1)
let anchorDangerColor = NSColor(calibratedRed: 0.76, green: 0.24, blue: 0.24, alpha: 1)

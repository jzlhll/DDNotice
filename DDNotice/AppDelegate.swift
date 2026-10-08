//
//  AppDelegate.swift
//  DDNotice
//
//  Created by donglyu on 17/3/18.
//  Copyright © 2017年 donglyu. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var timeStatusView: TimeStatusView?
    private var mainWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        mainWindowController = NSApplication.shared.windows.first {
            $0.contentViewController is ViewController
        }?.windowController
        updateStatusItem()
        NotificationCenter.default.addObserver(
            self, selector: #selector(ReceiveNotiOpenStatusTimemMode(_:)),
            name: Notification.Name(NotiOpenPanelTimeViewMode), object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        DDTimer.shared.abortSleepTimer()
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showTimerWindow()
        }
        return true
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        NotificationCenter.default.post(name: Notification.Name("AppBecomeActive"), object: nil)
    }

    func applicationDidResignActive(_ notification: Notification) {
        NotificationCenter.default.post(name: Notification.Name("AppResignActive"), object: nil)
    }

    @objc func ClickTopMenuBarItem(sender: Any?) {
        showTimerWindow()
    }

    @objc func ReceiveNotiOpenStatusTimemMode(_ notification: Notification) {
        // Read the saved preference rather than casting notification payloads.
        updateStatusItem()
        if statusItem == nil {
            showTimerWindow()
        }
    }

    private func updateStatusItem() {
        guard UserDefaults.standard.bool(forKey: UserDefaultSwitchShowStatusTimeView) else {
            if let statusItem = statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
            }
            timeStatusView = nil
            statusItem = nil
            return
        }
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(ClickTopMenuBarItem(sender:))
        button.toolTip = "打开倒计时"
        if let image = NSImage(named: "setting_white")?.copy() as? NSImage {
            image.isTemplate = true
            image.size = NSSize(width: 16, height: 16)
            button.image = image
            button.imagePosition = .imageLeading
        }
        timeStatusView = TimeStatusView(button: button)
    }

    private func showTimerWindow() {
        if mainWindowController == nil {
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            mainWindowController = storyboard.instantiateController(withIdentifier: "TimeFiled")
                as? NSWindowController
        }
        mainWindowController?.showWindow(nil)
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        if #available(macOS 14.0, *) {
            NSApplication.shared.activate()
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

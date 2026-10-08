//
//  AppDelegate.swift
//  DDNotice
//
//  Created by donglyu on 17/3/18.
//  Copyright © 2017年 donglyu. All rights reserved.
//

import Cocoa

// 管理独立闹钟窗口及菜单栏中最近到期的倒计时。
@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var timeStatusView: TimeStatusView?
    private var mainWindowController: NSWindowController?
    private var timerWindowControllers: [NSWindowController] = []

    private var preferredTimerWindowController: NSWindowController? {
        let active = timerWindowControllers.compactMap { windowController -> (NSWindowController, ViewController)? in
            guard let controller = windowController.contentViewController as? ViewController,
                  controller.timer.isMainTimeInEffect else { return nil }
            return (windowController, controller)
        }
        let running = active.filter { !$0.1.timer.isPaused }.min {
            $0.1.timer.remainingTime < $1.1.timer.remainingTime
        }
        return running?.0 ?? active.first?.0 ?? mainWindowController ?? timerWindowControllers.first
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        timerWindowControllers = NSApplication.shared.windows.compactMap { window in
            guard window.contentViewController is ViewController else { return nil }
            window.delegate = self
            window.isExcludedFromWindowsMenu = false
            window.makeFirstResponder(nil)
            return window.windowController
        }
        mainWindowController = timerWindowControllers.first
        if mainWindowController == nil {
            createTimerWindow(sender: nil)
        }
        if let mainMenu = NSApplication.shared.mainMenu {
            let menu = NSMenu(title: "闹钟")
            menu.delegate = self
            let newItem = NSMenuItem(title: "新建闹钟", action: #selector(createTimerWindow(sender:)), keyEquivalent: "n")
            newItem.target = self
            menu.addItem(newItem)
            menu.addItem(.separator())
            let menuItem = NSMenuItem(title: "闹钟", action: nil, keyEquivalent: "")
            menuItem.submenu = menu
            mainMenu.insertItem(menuItem, at: 1)
        }
        updateStatusItem()
        NotificationCenter.default.addObserver(
            self, selector: #selector(ReceiveNotiOpenStatusTimemMode(_:)),
            name: Notification.Name(NotiOpenPanelTimeViewMode), object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(refreshTimeStatus(_:)),
            name: Notification.Name(NotiTimerUpdate), object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        for windowController in timerWindowControllers {
            (windowController.contentViewController as? ViewController)?.timer.abortSleepTimer()
        }
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for windowController in timerWindowControllers {
                windowController.showWindow(nil)
            }
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

    @objc func createTimerWindow(sender: Any?) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let windowController = storyboard.instantiateController(withIdentifier: "TimeFiled")
            as? NSWindowController, let window = windowController.window else { return }
        let previousWindow = NSApplication.shared.keyWindow ?? mainWindowController?.window
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.isExcludedFromWindowsMenu = false
        if let previousWindow = previousWindow {
            window.setFrameOrigin(NSPoint(x: previousWindow.frame.minX + 24,
                                          y: previousWindow.frame.minY - 24))
            window.setFrame(window.constrainFrameRect(window.frame, to: previousWindow.screen), display: false)
        }
        timerWindowControllers.append(windowController)
        mainWindowController = windowController
        showTimerWindow(windowController)
        updateTimeStatus()
    }

    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
        guard let controller = sender.contentViewController as? ViewController,
              let field = client as? NSTextField,
              field === controller.hourLabel || field === controller.minuteLabel
                || field === controller.secondsLabel else { return nil }
        return controller.timeFieldEditor
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let controller = window.contentViewController as? ViewController else { return }
        // 运行中的闹钟关闭窗口后继续计时，到期时自动显示。
        if !controller.timer.isMainTimeInEffect {
            timerWindowControllers.removeAll { $0.window === window }
            if mainWindowController?.window === window {
                mainWindowController = timerWindowControllers.last
            }
        }
        updateTimeStatus()
    }

    @objc func ClickTopMenuBarItem(sender: Any?) {
        showTimerWindow((sender as? NSMenuItem)?.representedObject as? NSWindowController)
    }

    @objc func ReceiveNotiOpenStatusTimemMode(_ notification: Notification) {
        updateStatusItem()
        if statusItem == nil {
            for windowController in timerWindowControllers {
                windowController.showWindow(nil)
            }
            showTimerWindow()
        }
    }

    @objc private func refreshTimeStatus(_ notification: Notification) {
        updateTimeStatus()
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
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        guard let button = item.button else { return }
        if let image = NSImage(named: "setting_white")?.copy() as? NSImage {
            image.isTemplate = true
            image.size = NSSize(width: 16, height: 16)
            button.image = image
            button.imagePosition = .imageLeading
        }
        timeStatusView = TimeStatusView(button: button)
        updateTimeStatus()
    }

    private func updateTimeStatus() {
        let controller = preferredTimerWindowController?.contentViewController as? ViewController
        timeStatusView?.updateRemainingTime(remaining: controller?.timer.remainingTime ?? 0)
        statusItem?.button?.toolTip = controller.map { $0.reminderMessage + " · 点击查看所有闹钟" }
            ?? "新建闹钟"
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        for windowController in timerWindowControllers {
            guard let controller = windowController.contentViewController as? ViewController else { continue }
            let seconds = Int(ceil(max(0, controller.timer.remainingTime)))
            let time = String(format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
            let title = controller.reminderMessage + " · " + time
                + (controller.timer.isPaused ? " · 已暂停" : "")
            let item = NSMenuItem(title: title, action: #selector(ClickTopMenuBarItem(sender:)), keyEquivalent: "")
            item.target = self
            item.representedObject = windowController
            menu.addItem(item)
        }
        if !timerWindowControllers.isEmpty {
            menu.addItem(.separator())
        }
        let addItem = NSMenuItem(title: "+ 新建闹钟", action: #selector(createTimerWindow(sender:)), keyEquivalent: "n")
        addItem.target = self
        menu.addItem(addItem)
    }

    private func showTimerWindow(_ selectedWindowController: NSWindowController? = nil) {
        guard let windowController = selectedWindowController ?? preferredTimerWindowController else {
            createTimerWindow(sender: nil)
            return
        }
        mainWindowController = windowController
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
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

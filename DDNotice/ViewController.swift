//
//  ViewController.swift
//  DDNotice
//
//  Created by donglyu on 17/3/18.
//  Copyright © 2017年 donglyu. All rights reserved.
//  todo : 监听点击了关闭按钮的事件。

import Cocoa
import AVFoundation

// 使用系统外观绘制无边框的计时面板背景。
final class TimerPanelView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(rect: bounds).fill()
    }

    @available(macOS 10.14, *)
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}

// 覆盖系统切换焦点时的默认选中样式，保持数字原色和透明背景。
final class TimerFieldEditor: NSTextView {
    override var selectedTextAttributes: [NSAttributedString.Key: Any] {
        get { [.backgroundColor: NSColor.clear] }
        set { super.selectedTextAttributes = [.backgroundColor: NSColor.clear] }
    }
}

class ViewController: NSViewController, NSTextFieldDelegate {
    private static let runningTextColor = adaptiveTextColor(
        light: NSColor(srgbRed: 0.24, green: 0.50, blue: 0.36, alpha: 1),
        dark: NSColor(srgbRed: 0.48, green: 0.74, blue: 0.59, alpha: 1))
    private static let pausedTextColor = adaptiveTextColor(
        light: NSColor(srgbRed: 0.61, green: 0.45, blue: 0.19, alpha: 1),
        dark: NSColor(srgbRed: 0.82, green: 0.72, blue: 0.46, alpha: 1))
    private static let finishedTextColor = adaptiveTextColor(
        light: NSColor(srgbRed: 0.67, green: 0.36, blue: 0.35, alpha: 1),
        dark: NSColor(srgbRed: 0.84, green: 0.57, blue: 0.56, alpha: 1))

    private static func adaptiveTextColor(light: NSColor, dark: NSColor) -> NSColor {
        if #available(macOS 10.15, *) {
            return NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            }
        }
        return light
    }

    @IBOutlet var TimingContainerView: NSView!
    @IBOutlet weak var TimingNSBox: NSBox!
    @IBOutlet weak var TimingFieldBoxContainerView: NSView!
    @IBOutlet weak var hourLabel: NSTextField!
    @IBOutlet weak var minuteLabel: NSTextField!
    @IBOutlet weak var secondsLabel: NSTextField!
    
    @IBOutlet weak var abortBtn: NSButton!
    @IBOutlet weak var startBtn: NSButton!

    
    let timer = DDTimer()
    // 时间输入使用独立编辑器，选中数字时保持透明背景。
    let timeFieldEditor: NSTextView = {
        let editor = TimerFieldEditor()
        editor.isFieldEditor = true
        editor.isRichText = false
        editor.drawsBackground = false
        editor.insertionPointColor = .labelColor
        editor.selectedTextAttributes = [.backgroundColor: NSColor.clear]
        return editor
    }()
    private(set) var reminderMessage = "闹钟"
    private let reminderTitleField = NSTextField(labelWithString: "闹钟")
    private var titlebarController: NSTitlebarAccessoryViewController?

    var soundPlayer : AVAudioPlayer?

    var isTimeTick = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        timer.abortSleepTimer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TimingNSBox.boxType = .custom
        TimingNSBox.isTransparent = true
        TimingNSBox.borderWidth = 0
        TimingNSBox.fillColor = .clear
        TimingNSBox.contentViewMargins = .zero

        for field in [hourLabel, minuteLabel, secondsLabel].compactMap({ $0 }) {
            field.isBordered = false
            field.isBezeled = false
            field.drawsBackground = false
            field.focusRingType = .none
            field.textColor = .labelColor
            field.font = .monospacedDigitSystemFont(ofSize: 34, weight: .medium)
        }
        for button in [abortBtn, startBtn].compactMap({ $0 }) {
            button.bezelStyle = .rounded
            button.isBordered = true
            button.font = .systemFont(ofSize: 13)
        }
        startBtn.keyEquivalent = "\r"
        
        hourLabel.delegate = self
        minuteLabel.delegate = self
        secondsLabel.delegate = self
        updateTimeFields(remaining: timer.remainingTime)
        isTimeTick = timer.isMainTimeInEffect && !timer.isPaused
        setLabelEditable(editable: !timer.isMainTimeInEffect)
        startBtn.title = timer.isPaused ? "继续" : (isTimeTick ? "暂停" : "开始")
        
        ChangeTextFiledShadowColor(color: timer.isMainTimeInEffect
                                  ? (isTimeTick ? .systemGreen : .systemYellow) : .labelColor)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: NSNotification.Name("AppBecomeActive"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appResignActive), name: NSNotification.Name("AppResignActive"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TimerUpdateNoti), name: NSNotification.Name(NotiTimerUpdate), object: timer)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(TimerEndAndNoti), name: NSNotification.Name(NotiTimerEndAction), object: timer)
        
        
        
        
    }
    

    

    override func viewDidAppear() {
        super.viewDidAppear()
        guard let window = view.window, titlebarController == nil else { return }
        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .right
        accessory.view = NSView(frame: NSRect(x: 0, y: 0, width: 146, height: 22))

        reminderTitleField.frame = NSRect(x: 4, y: 2, width: 106, height: 18)
        reminderTitleField.font = .systemFont(ofSize: 11, weight: .medium)
        reminderTitleField.textColor = .labelColor
        reminderTitleField.alignment = .center
        reminderTitleField.lineBreakMode = .byTruncatingTail
        reminderTitleField.setAccessibilityLabel("提醒文案，双击编辑")
        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(editReminderTitle(_:)))
        doubleClick.numberOfClicksRequired = 2
        reminderTitleField.addGestureRecognizer(doubleClick)
        accessory.view.addSubview(reminderTitleField)

        let addButton = NSButton(title: "+", target: self, action: #selector(addAlarm(_:)))
        addButton.frame = NSRect(x: 116, y: 0, width: 26, height: 22)
        addButton.font = .systemFont(ofSize: 18, weight: .regular)
        addButton.isBordered = false
        addButton.toolTip = "新建闹钟"
        addButton.setAccessibilityLabel("新建闹钟")
        accessory.view.addSubview(addButton)

        window.titleVisibility = .hidden
        window.tabbingMode = .disallowed
        window.addTitlebarAccessoryViewController(accessory)
        titlebarController = accessory
        updateReminderTitle()
    }

    @objc private func addAlarm(_ sender: Any?) {
        (NSApplication.shared.delegate as? AppDelegate)?.createTimerWindow(sender: sender)
    }

    @objc private func editReminderTitle(_ sender: Any?) {
        guard let window = view.window, window.attachedSheet == nil else { return }
        let alert = NSAlert()
        alert.messageText = "编辑提醒文案"
        alert.informativeText = "标题也会用作计时结束时的提醒。"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 26))
        input.stringValue = reminderMessage
        input.placeholderString = "输入提醒文案"
        alert.accessoryView = input
        alert.window.initialFirstResponder = input
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            let message = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            self?.reminderMessage = message.isEmpty ? "闹钟" : message
            self?.updateReminderTitle()
        }
        alert.window.makeFirstResponder(input)
        input.selectText(nil)
    }

    private func updateReminderTitle() {
        reminderTitleField.stringValue = reminderMessage
        reminderTitleField.toolTip = reminderMessage + "\n双击修改提醒文案"
        view.window?.title = reminderMessage
        NotificationCenter.default.post(name: Notification.Name(NotiTimerUpdate), object: timer,
                                        userInfo: ["remaining": timer.remainingTime])
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: Main

    @IBAction func abortBtnClick(_ sender: Any) {
        timer.abortSleepTimer()
        // update Label str.
        self.setLabelEditable(editable: true)
        startBtn.title = "开始"
        isTimeTick = false
        
        ChangeTextFiledShadowColor(color: .labelColor)
    }

    @IBAction func startBtnClick(_ sender: Any) {
        if timer.isMainTimeInEffect && !timer.isPaused {
            timer.PauseTimer()
            startBtn.title = "继续"
            isTimeTick = false
            ChangeTextFiledShadowColor(color: .systemYellow)
            return
        }

        if timer.isPaused {
            timer.ContinueTimer()
        } else {
            let hour = max(0, min(99, hourLabel.integerValue))
            let minute = max(0, min(59, minuteLabel.integerValue))
            let seconds = max(0, min(59, secondsLabel.integerValue))
            let timeInterval = hour * 3600 + minute * 60 + seconds
            guard timeInterval > 0 else { return }
            timer.runSleepTimer(seconds: NSNumber(value: timeInterval))
        }
        setLabelEditable(editable: false)
        startBtn.title = "暂停"
        isTimeTick = true
        ChangeTextFiledShadowColor(color: .systemGreen)
        if UserDefaults.standard.bool(forKey: UserDefaultSwitchShowStatusTimeView) {
            view.window?.orderOut(nil)
        }
    }

}

extension ViewController{
    // MARK: Private
    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSTextField,
              field === hourLabel || field === minuteLabel || field === secondsLabel else { return }
        field.stringValue = String(field.stringValue.filter { "0123456789".contains($0) }.prefix(2))
        if field !== hourLabel && field.integerValue > 59 {
            field.stringValue = "59"
        }
    }

    func setLabelEditable(editable:Bool)  {
        hourLabel.isEditable = editable
        minuteLabel.isEditable = editable
        secondsLabel.isEditable = editable
        hourLabel.isSelectable = editable
        minuteLabel.isSelectable = editable
        secondsLabel.isSelectable = editable
        
        if editable {
            hourLabel.stringValue = "00"
            minuteLabel.stringValue = "00"
            secondsLabel.stringValue = "00"
        }
        
    }
    
    func ChangeTextFiledShadowColor(color:NSColor){
        let textColor: NSColor
        if color == .systemGreen {
            textColor = Self.runningTextColor
        } else if color == .systemYellow {
            textColor = Self.pausedTextColor
        } else if color == .systemRed {
            textColor = Self.finishedTextColor
        } else {
            textColor = color
        }
        hourLabel.textColor = textColor
        minuteLabel.textColor = textColor
        secondsLabel.textColor = textColor
    }
    
    // MARK: - ---Noti
    
    @objc func appBecomeActive(){
        view.needsDisplay = true
    }
    
    @objc func appResignActive(){
        view.needsDisplay = true
    }
    
    
    @objc func TimerUpdateNoti(objc: Notification) {
        guard let remaining = objc.userInfo?["remaining"] as? TimeInterval else { return }
        updateTimeFields(remaining: remaining)
    }

    private func updateTimeFields(remaining: TimeInterval) {
        let totalSeconds = Int(ceil(max(0, remaining)))
        hourLabel.stringValue = String(format: "%02d", totalSeconds / 3600)
        minuteLabel.stringValue = String(format: "%02d", totalSeconds / 60 % 60)
        secondsLabel.stringValue = String(format: "%02d", totalSeconds % 60)
    }

    @objc func TimerEndAndNoti(){
        
        setLabelEditable(editable: true)
        self.ChangeTextFiledShadowColor(color: .systemRed)
        
        let isPlaySounds = UserDefaults.standard.integer(forKey:UserDefaultIsPlaySounds)
        
        if isPlaySounds == 1 || UserDefaults.standard.object(forKey: UserDefaultIsPlaySounds) == nil {
            self.prepareSound()
            self.playSound()
        }
        startBtn.title = "开始"
        isTimeTick = false
        
        
        guard let window = view.window else { return }
        window.makeKeyAndOrderFront(nil)
        if #available(macOS 14.0, *) {
            NSApplication.shared.activate()
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        SliceAlertManager.sharedManager.PopNormalAlertNoticeView(message: reminderMessage, window: window)
    }
    

}

extension ViewController{
    // MARK: - --Music About!
    
    func prepareSound() {
        
        if soundPlayer != nil {
            return
        }
        
        guard let audioFileUrl = Bundle.main.url(forResource: "夏日午后的农庄内音效",
                                                 withExtension: "wav") else {
                                                    return
        }
        
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: audioFileUrl)
            soundPlayer?.prepareToPlay()
        } catch {
            print("Sound player not available: \(error)")
        }
    }
    
    func playSound() {
        soundPlayer?.play()
    }

    
    /*
     1. 选择本地音乐， 复制到沙盒文件中... // 文件选择框，获取路劲
     2. 播放音乐
     */
    
    
    //5-5 .play
    func prepareAndPlaySound(filePath: String) {
        
        //
        
    }
}

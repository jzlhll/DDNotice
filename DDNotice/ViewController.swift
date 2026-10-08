//
//  ViewController.swift
//  DDNotice
//
//  Created by donglyu on 17/3/18.
//  Copyright © 2017年 donglyu. All rights reserved.
//  todo : 监听点击了关闭按钮的事件。

import Cocoa
import AVFoundation

class ViewController: NSViewController, NSTextFieldDelegate {

    @IBOutlet var TimingContainerView: NSView!
    @IBOutlet weak var TimingNSBox: NSBox!
    @IBOutlet weak var TimingFieldBoxContainerView: NSView!
    @IBOutlet weak var hourLabel: NSTextField!
    @IBOutlet weak var minuteLabel: NSTextField!
    @IBOutlet weak var secondsLabel: NSTextField!
    
    @IBOutlet weak var abortBtn: NSButton!
    @IBOutlet weak var startBtn: NSButton!

    
//    let timer = DDTimer.shared

    var soundPlayer : AVAudioPlayer?

    var isTimeTick = false
    var shadow: NSShadow?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.black.cgColor
        
        hourLabel.delegate = self
        minuteLabel.delegate = self
        secondsLabel.delegate = self
        updateTimeFields(remaining: DDTimer.shared.remainingTime)
        isTimeTick = DDTimer.shared.isMainTimeInEffect && !DDTimer.shared.isPaused
        setLabelEditable(editable: !DDTimer.shared.isMainTimeInEffect)
        startBtn.title = DDTimer.shared.isPaused ? "继续" : (isTimeTick ? "暂停" : "开始")
        
        shadow = NSShadow.init()
        shadow?.shadowColor = NSColor.clear
        shadow?.shadowBlurRadius = 7
        
        hourLabel.wantsLayer = true
        hourLabel.shadow = shadow
        minuteLabel.shadow = shadow;
        minuteLabel.wantsLayer = true
        secondsLabel.shadow = shadow;
        secondsLabel.wantsLayer = true
        self.view.layer?.borderColor = NSColor.red.cgColor
        self.view.layer?.borderWidth = 0
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: NSNotification.Name("AppBecomeActive"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appResignActive), name: NSNotification.Name("AppResignActive"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TimerUpdateNoti), name: NSNotification.Name(NotiTimerUpdate), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(TimerEndAndNoti), name: NSNotification.Name(NotiTimerEndAction), object: nil)
        
        
//        DDTimer.shared.delegate = self
        
        
    }
    

    

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: Main

    @IBAction func abortBtnClick(_ sender: Any) {
        DDTimer.shared.abortSleepTimer()
        // update Label str.
        self.setLabelEditable(editable: true)
        startBtn.title = "开始"
        isTimeTick = false
        
        self.view.layer?.borderWidth = 0
    }

    @IBAction func startBtnClick(_ sender: Any) {
        let timer = DDTimer.shared
        if timer.isMainTimeInEffect && !timer.isPaused {
            timer.PauseTimer()
            startBtn.title = "继续"
            isTimeTick = false
            ChangeTextFiledShadowColor(color: .yellow)
            view.layer?.borderWidth = 2
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
        ChangeTextFiledShadowColor(color: .green)
        view.layer?.borderWidth = 0
        if UserDefaults.standard.bool(forKey: UserDefaultSwitchShowStatusTimeView) {
            view.window?.close()
        }
    }

}

extension ViewController{
//    override func controlTextDidBeginEditing(_ obj: Notification) {
//        TimingFieldBoxContainerView.layer?.backgroundColor = NSColor.clear.cgColor
//    }
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
        self.shadow?.shadowColor = color
        self.hourLabel.shadow = self.shadow
        self.minuteLabel.shadow = self.shadow
        self.secondsLabel.shadow = self.shadow
    }
    
    // MARK: - ---Noti
    
    @objc func appBecomeActive(){
        self.TimingFieldBoxContainerView.layer?.backgroundColor = NSColor.black.cgColor
        
        if isTimeTick{
            
        }else{
            self.ChangeTextFiledShadowColor(color: NSColor.yellow)
        }
    }
    
    @objc func appResignActive(){
        
        if !isTimeTick {
            self.ChangeTextFiledShadowColor(color: NSColor.yellow)
        }
        
    }
    
    
    @objc func TimerUpdateNoti(objc: Notification) {
        guard let remaining = objc.object as? TimeInterval else { return }
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
        self.view.wantsLayer = true
        
        self.ChangeTextFiledShadowColor(color: NSColor.red)
        
        let isPlaySounds = UserDefaults.standard.integer(forKey:UserDefaultIsPlaySounds)
        
        if isPlaySounds == 1 || UserDefaults.standard.object(forKey: UserDefaultIsPlaySounds) == nil {
            self.prepareSound()
            self.playSound()
        }
        startBtn.title = "开始"
        isTimeTick = false
        
        
        let action = SliceAlertManager.sharedManager.PopNormalAlertNoticeView()
        
        if action == NSApplication.ModalResponse.alertFirstButtonReturn {
            self.ChangeTextFiledShadowColor(color: NSColor.yellow)
        }
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

//
//  PrefsViewController.swift
//  DDNotice
//
//  Created by donglyu on 17/4/4.
//  Copyright © 2017年 donglyu. All rights reserved.
//

import Cocoa

class PrefsViewController: NSViewController {

    
    @IBOutlet weak var isPlaySoundsCheckBtn: NSButton!
    @IBOutlet weak var switchStatusBarTimeBtn: NSButton!
    
    
    
    // notice words
    @IBOutlet var msgView: NSTextView!
    @IBOutlet weak var tipForShowConfirmOK: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Restore UI
        let isPlaySounds = UserDefaults.standard.bool(forKey: UserDefaultIsPlaySounds)
        if UserDefaults.standard.object(forKey: UserDefaultIsPlaySounds) == nil || isPlaySounds  {
            isPlaySoundsCheckBtn.state = .on
        }else{
            isPlaySoundsCheckBtn.state = .off
        }
        
        
        let isShowStaturBarTimeView = UserDefaults.standard.bool(forKey: UserDefaultSwitchShowStatusTimeView)
        if isShowStaturBarTimeView {
            switchStatusBarTimeBtn.state = .on
        }else{
            switchStatusBarTimeBtn.state = .off
        }
        
        
        
        let showMsg = UserDefaults.standard.string(forKey: UserDefaultMsgShow)
        
        if showMsg != nil {
            msgView.insertText(showMsg ?? "继续加油！努力努力再努力~", replacementRange: NSRange.init(location: 0, length: 0))
        }else{
            msgView.insertText("继续加油！努力努力再努力~", replacementRange: NSRange.init(location: 0, length: 0))
            
        }
        
        
        
        
        
        
        //
            
    
        
        
        
    }
    @IBAction func isPlaySoundsCheckBtnClick(_ sender: NSButton) {
        
        print("check box's state:\(sender.state)")
        
        UserDefaults.standard.set(sender.state == .on, forKey: UserDefaultIsPlaySounds)
    }
    
    
    @IBAction func switchStatusTimeClick(_ sender: NSButton) {
        
        UserDefaults.standard.set(sender.state == .on, forKey: UserDefaultSwitchShowStatusTimeView)
        
        // Others.
        
        
        NotificationCenter.default.post(name: NSNotification.Name(NotiOpenPanelTimeViewMode), object: sender.state == .on)
        
        
        
    }
    
    @IBAction func msgConfirmBtnClick(_ sender: Any) {
        
        let customMsg = msgView.string;
        UserDefaults.standard.set(customMsg, forKey: UserDefaultMsgShow)
        
        tipForShowConfirmOK.textColor = NSColor.blue
        let time: TimeInterval  = 1.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
            self.tipForShowConfirmOK.textColor = NSColor.clear
        }
        
    }

}

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

    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        isPlaySoundsCheckBtn.state = defaults.object(forKey: UserDefaultIsPlaySounds) == nil
            || defaults.bool(forKey: UserDefaultIsPlaySounds) ? .on : .off
        switchStatusBarTimeBtn.state = defaults.bool(forKey: UserDefaultSwitchShowStatusTimeView)
            ? .on : .off
    }

    @IBAction func isPlaySoundsCheckBtnClick(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: UserDefaultIsPlaySounds)
    }

    @IBAction func switchStatusTimeClick(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: UserDefaultSwitchShowStatusTimeView)
        NotificationCenter.default.post(name: NSNotification.Name(NotiOpenPanelTimeViewMode),
                                        object: sender.state == .on)
    }
}

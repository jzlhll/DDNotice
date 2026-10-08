//
//  SliceAlertManager.swift
//  Slice
//
//  Created by donglyu on 2019/4/5.
//  Copyright © 2019 donglyu. All rights reserved.
//

import Cocoa

// 将到期提醒附着到对应闹钟，避免阻塞其他闹钟的操作。
class SliceAlertManager: NSObject {
    static let sharedManager = SliceAlertManager()

    func PopNormalAlertNoticeView(message: String, window: NSWindow) {
        let myPopUp = NSAlert()
        myPopUp.messageText = message
        myPopUp.informativeText = "计时结束"
        myPopUp.alertStyle = .informational
        myPopUp.addButton(withTitle: "知道了")
        myPopUp.beginSheetModal(for: window)
    }
}

//
//  TimeStatusView.swift
//  Slice
//
//  Created by donglyu on 2019/4/2.
//  Copyright © 2019 donglyu. All rights reserved.
//

import Cocoa

// 在系统菜单栏按钮上显示当前选中闹钟的倒计时。
final class TimeStatusView: NSObject, TimerDelegate {
    private weak var button: NSStatusBarButton?

    init(button: NSStatusBarButton) {
        self.button = button
        super.init()
        updateRemainingTime(remaining: 0)
    }

    func updateRemainingTime(remaining: TimeInterval) {
        let totalSeconds = Int(ceil(max(0, remaining)))
        let text = String(format: "%02d:%02d:%02d", totalSeconds / 3600,
                          totalSeconds / 60 % 60, totalSeconds % 60)
        button?.attributedTitle = NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.labelColor
        ])
    }

    func TimerEndAction() {
        // 提醒和声音由各自的闹钟窗口处理。
        updateRemainingTime(remaining: 0)
    }
}

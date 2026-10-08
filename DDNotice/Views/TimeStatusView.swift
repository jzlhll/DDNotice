//
//  TimeStatusView.swift
//  Slice
//
//  Created by donglyu on 2019/4/2.
//  Copyright © 2019 donglyu. All rights reserved.
//

import Cocoa

// Formats the countdown on the standard status bar button.
final class TimeStatusView: NSObject, TimerDelegate {
    private weak var button: NSStatusBarButton?

    init(button: NSStatusBarButton) {
        self.button = button
        super.init()
        DDTimer.shared.delegate = self
        updateRemainingTime(remaining: DDTimer.shared.remainingTime)
    }

    func updateRemainingTime(remaining: TimeInterval) {
        let totalSeconds = Int(ceil(max(0, remaining)))
        let text = String(format: "%02d:%02d:%02d", totalSeconds / 3600,
                          totalSeconds / 60 % 60, totalSeconds % 60)
        button?.attributedTitle = NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.orange
        ])
    }

    func TimerEndAction() {
        // The timer window owns the completion alert and sound.
        updateRemainingTime(remaining: 0)
    }
}

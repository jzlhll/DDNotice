//
//  DDTimer.swift
//  DDNotice
//
//  Created by donglyu on 17/3/19.
//  Copyright © 2017年 donglyu. All rights reserved.
//

import Foundation

protocol TimerDelegate: AnyObject {
    func updateRemainingTime(remaining: TimeInterval)
    func TimerEndAction()
}

class DDTimer: NSObject {
    static let shared = DDTimer()

    private(set) var activityTimer: Timer?
    private(set) var sleepTimer: Timer?
    private(set) var endTime: TimeInterval = 0
    private(set) var isMainTimeInEffect = false
    private(set) var isPaused = false
    private var pausedRemainingTime: TimeInterval = 0
    weak var delegate: TimerDelegate?

    var remainingTime: TimeInterval {
        guard isMainTimeInEffect else { return 0 }
        return isPaused ? pausedRemainingTime : max(0, endTime - Date.timeIntervalSinceReferenceDate)
    }

    func runSleepTimer(seconds: NSNumber) {
        guard seconds.doubleValue.isFinite, seconds.doubleValue > 0 else { return }
        sleepTimer?.invalidate()
        endTime = Date.timeIntervalSinceReferenceDate + seconds.doubleValue
        isMainTimeInEffect = true
        isPaused = false
        pausedRemainingTime = 0
        let timer = Timer(timeInterval: 0.2, target: self, selector: #selector(updateTime(timer:)),
                          userInfo: nil, repeats: true)
        timer.tolerance = 0.05
        // 菜单和其他窗口交互期间也继续更新倒计时。
        RunLoop.main.add(timer, forMode: .common)
        sleepTimer = timer
        publishRemainingTime()
    }

    func abortSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        endTime = 0
        isMainTimeInEffect = false
        isPaused = false
        pausedRemainingTime = 0
        publishRemainingTime()
    }

    @objc func updateTime(timer: Timer) {
        guard isMainTimeInEffect, !isPaused, timer === sleepTimer else { return }
        if remainingTime <= 0 {
            abortSleepTimer()
            showAlert()
        } else {
            publishRemainingTime()
        }
    }

    private func publishRemainingTime() {
        let remaining = remainingTime
        delegate?.updateRemainingTime(remaining: remaining)
        NotificationCenter.default.post(name: Notification.Name(NotiTimerUpdate), object: self,
                                        userInfo: ["remaining": remaining])
    }

    func showAlert() {
        NotificationCenter.default.post(name: Notification.Name(NotiTimerEndAction), object: self)
        delegate?.TimerEndAction()
    }

    func PauseTimer() {
        guard isMainTimeInEffect, !isPaused else { return }
        pausedRemainingTime = remainingTime
        isPaused = true
        sleepTimer?.fireDate = .distantFuture
        publishRemainingTime()
    }

    func ContinueTimer() {
        guard isMainTimeInEffect, isPaused else { return }
        endTime = Date.timeIntervalSinceReferenceDate + pausedRemainingTime
        isPaused = false
        sleepTimer?.fireDate = Date()
        publishRemainingTime()
    }

    func runSystemActivityTimer() {
        activityTimer?.invalidate()
        activityTimer = Timer.scheduledTimer(timeInterval: 30, target: self,
                                             selector: #selector(systemActivity), userInfo: nil, repeats: true)
        activityTimer?.tolerance = 1
    }

    @objc func systemActivity() {}

    func killSynstemActivityTimer() {
        activityTimer?.invalidate()
        activityTimer = nil
    }
}

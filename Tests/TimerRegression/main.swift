import Foundation

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

func pump(for seconds: TimeInterval) {
    RunLoop.main.run(until: Date().addingTimeInterval(seconds))
}

final class Recorder: TimerDelegate {
    var values: [TimeInterval] = []
    var completions = 0
    func updateRemainingTime(remaining: TimeInterval) { values.append(remaining) }
    func TimerEndAction() { completions += 1 }
}

let timer = DDTimer()
let recorder = Recorder()
timer.delegate = recorder
var notifications = 0
let observation = NotificationCenter.default.addObserver(
    forName: Notification.Name(NotiTimerEndAction), object: nil, queue: nil) { _ in
        notifications += 1
    }
defer { NotificationCenter.default.removeObserver(observation) }

// Invalid input must not enter the running state.
for duration in [0.0, -1.0, Double.nan, Double.infinity] {
    timer.runSleepTimer(seconds: NSNumber(value: duration))
    require(!timer.isMainTimeInEffect, "Invalid duration started a timer")
}

// Pausing longer than the original deadline must preserve the remaining time.
timer.runSleepTimer(seconds: 0.3)
pump(for: 0.05)
timer.PauseTimer()
let paused = timer.remainingTime
pump(for: 0.4)
require(timer.isPaused && timer.isMainTimeInEffect, "Paused timer lost its state")
require(abs(timer.remainingTime - paused) < 0.001, "Pause consumed countdown time")
require(notifications == 0, "Timer completed while paused")
timer.ContinueTimer()
require(!timer.isPaused && timer.remainingTime > 0, "Resume did not restore the deadline")
pump(for: 0.6)
require(!timer.isMainTimeInEffect && timer.sleepTimer == nil, "Completion did not clear the timer")
require(notifications == 1 && recorder.completions == 1, "Completion must fire exactly once")
require(recorder.values.allSatisfy { $0 >= 0 }, "Timer published a negative countdown")
pump(for: 0.25)
require(notifications == 1, "Completion was delivered twice")

// Restart must invalidate the old timer, and ignore callbacks from it.
timer.runSleepTimer(seconds: 0.1)
let previous = timer.sleepTimer!
timer.runSleepTimer(seconds: 2)
require(!previous.isValid, "Restart left the old timer alive")
timer.updateTime(timer: previous)
pump(for: 0.25)
require(timer.isMainTimeInEffect && timer.remainingTime > 1, "A stale callback ended the new timer")
require(notifications == 1, "Restart triggered an early completion")

// Cancel must reset both running and paused state, without a completion alert.
timer.PauseTimer()
timer.abortSleepTimer()
require(!timer.isMainTimeInEffect && !timer.isPaused && timer.remainingTime == 0,
        "Cancel failed to reset state")
timer.ContinueTimer()
pump(for: 0.25)
require(timer.sleepTimer == nil && notifications == 1, "Cancel allowed the timer to resume")
require(recorder.values.last == 0, "Cancel failed to publish zero")

// These helpers previously force-unwrapped a nil timer.
timer.killSynstemActivityTimer()
timer.runSystemActivityTimer()
timer.runSystemActivityTimer()
timer.killSynstemActivityTimer()
require(timer.activityTimer == nil, "Activity timer cleanup failed")
print("PASS: invalid input, pause/resume, single completion, nonnegative countdown, restart, stale callback, cancel, activity cleanup")

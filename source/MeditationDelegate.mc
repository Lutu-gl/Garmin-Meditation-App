import Toybox.Application;
import Toybox.ActivityMonitor;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! Timer for meditation session (same pattern as ReadingApp)
class TimerModel {
    private var _totalSeconds as Float;
    private var _sessionStartTime as Number?;

    function initialize() {
        _totalSeconds = 0.0f;
        _sessionStartTime = null;
    }

    function stopSession() as Void {
        if (_sessionStartTime != null) {
            _totalSeconds += (System.getTimer() - _sessionStartTime) / 1000.0f;
        }
        _sessionStartTime = null;
    }

    function startSession() as Void {
        _sessionStartTime = System.getTimer();
    }

    function getTotalSeconds() as Float {
        if (_sessionStartTime != null) {
            return _totalSeconds + (System.getTimer() - _sessionStartTime) / 1000.0f;
        }
        return _totalSeconds;
    }

    function setTotalSeconds(sec as Float) as Void {
        _totalSeconds = sec;
    }
}

//! Collects heart rate samples during session for current + average
class HeartRateModel {
    private var _sum as Number;
    private var _count as Number;
    private var _lastHeartRate as Number?;

    function initialize() {
        _sum = 0;
        _count = 0;
        _lastHeartRate = null;
    }

    function addSample(hr as Number) as Void {
        _sum += hr;
        _count++;
        _lastHeartRate = hr;
    }

    function setLastHeartRate(hr as Number?) as Void {
        _lastHeartRate = hr;
    }

    function getLastHeartRate() as Number? {
        return _lastHeartRate;
    }

    function getAverageHeartRate() as Number? {
        if (_count > 0) {
            return (_sum + _count / 2) / _count;
        }
        return null;
    }

    function reset() as Void {
        _sum = 0;
        _count = 0;
        _lastHeartRate = null;
    }
}

//! Screen 1: Select = Start → push Screen 2
class Screen1Delegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onSelect() as Boolean {
        _goToScreen2();
        return true;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var k = keyEvent.getKey();
        var app = Application.getApp() as MeditationApp;
        if (k == WatchUi.KEY_UP) {
            app.increaseVibrationMinutes();
            WatchUi.requestUpdate();
            return true;
        }
        if (k == WatchUi.KEY_DOWN) {
            app.decreaseVibrationMinutes();
            WatchUi.requestUpdate();
            return true;
        }
        if (k == WatchUi.KEY_ENTER || k == WatchUi.KEY_START) {
            _goToScreen2();
            return true;
        }
        return false;
    }

    function _goToScreen2() as Void {
        var app = Application.getApp() as MeditationApp;
        _vibrateStart();
        app.getHeartRateModel().reset();
        app.resetVibrationTrigger();
        app.getTimerModel().setTotalSeconds(0.0f);
        app.getTimerModel().startSession();
        WatchUi.pushView(new Screen2View(), new Screen2Delegate(), WatchUi.SLIDE_UP);
    }

    private function _vibrateStart() as Void {
        try {
            Attention.vibrate([ new Attention.VibeProfile(100, 250) ]);
        } catch (e) {
            System.println("Start vibration failed: " + e.toString());
        }
    }
}

//! Screen 2: Timer + HR tracking. Select = Stop → push Screen 3
class Screen2Delegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onSelect() as Boolean {
        _goToScreen3();
        return true;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var k = keyEvent.getKey();
        if (k == WatchUi.KEY_ENTER || k == WatchUi.KEY_START) {
            _goToScreen3();
            return true;
        }
        if (k == WatchUi.KEY_ESC) {
            _goBack();
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        _goBack();
        return true;
    }

    function _goToScreen3() as Void {
        var app = Application.getApp() as MeditationApp;
        app.getTimerModel().stopSession();
        WatchUi.pushView(new Screen3View(), new Screen3Delegate(), WatchUi.SLIDE_UP);
    }

    function _goBack() as Void {
        var app = Application.getApp() as MeditationApp;
        app.getTimerModel().stopSession();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

//! Screen 3: Overview (Time + Avg HR). Select = Send → push Screen 4
class Screen3Delegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onSelect() as Boolean {
        var app = Application.getApp() as MeditationApp;
        app.getTimerModel().stopSession();
        WatchUi.pushView(new Screen4View(), new Screen4Delegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var k = keyEvent.getKey();
        if (k == WatchUi.KEY_ENTER || k == WatchUi.KEY_START) {
            var app = Application.getApp() as MeditationApp;
            app.getTimerModel().stopSession();
            WatchUi.pushView(new Screen4View(), new Screen4Delegate(), WatchUi.SLIDE_UP);
            return true;
        }
        if (k == WatchUi.KEY_ESC) {
            _goBack();
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        _goBack();
        return true;
    }

    function _goBack() as Void {
        var app = Application.getApp() as MeditationApp;
        app.getTimerModel().startSession();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

//! Screen 4: Sync result – Select or Back = return to Screen 1
class Screen4Delegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onSelect() as Boolean {
        _goHome();
        return true;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var k = keyEvent.getKey();
        if (k == WatchUi.KEY_ENTER || k == WatchUi.KEY_START) {
            _goHome();
            return true;
        }
        if (k == WatchUi.KEY_ESC) {
            _goBack();
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        _goBack();
        return true;
    }

    function _goBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function _goHome() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

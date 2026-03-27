import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! Sync status for Screen 4: 0=sending, 1=success, 2=error
class MeditationApp extends Application.AppBase {
    private var _timerModel as TimerModel;
    private var _heartRateModel as HeartRateModel;
    private var _syncStatus as Number;
    private var _syncError as String?;
    private var _vibrationMinutes as Number;
    private var _vibrationTriggered as Boolean;

    function initialize() {
        AppBase.initialize();
        _timerModel = new TimerModel();
        _heartRateModel = new HeartRateModel();
        _syncStatus = 0;
        _syncError = null;
        _vibrationMinutes = 5;
        _vibrationTriggered = false;
    }

    function setSyncSending() as Void {
        _syncStatus = 0;
        _syncError = null;
    }

    function setSyncResult(success as Boolean, errorMsg as String?) as Void {
        _syncStatus = success ? 1 : 2;
        _syncError = errorMsg;
    }

    function getSyncStatus() as Number {
        return _syncStatus;
    }

    function getSyncError() as String? {
        return _syncError;
    }

    function getInitialView() {
        return [ new Screen1View(), new Screen1Delegate() ];
    }

    function getTimerModel() as TimerModel {
        return _timerModel;
    }

    function getHeartRateModel() as HeartRateModel {
        return _heartRateModel;
    }

    function getVibrationMinutes() as Number {
        return _vibrationMinutes;
    }

    function increaseVibrationMinutes() as Void {
        if (_vibrationMinutes < 120) {
            _vibrationMinutes += 1;
        }
    }

    function decreaseVibrationMinutes() as Void {
        if (_vibrationMinutes > 1) {
            _vibrationMinutes -= 1;
        }
    }

    function resetVibrationTrigger() as Void {
        _vibrationTriggered = false;
    }

    function shouldTriggerVibration(elapsedSeconds as Float) as Boolean {
        if (_vibrationTriggered) {
            return false;
        }
        return elapsedSeconds >= (_vibrationMinutes * 60);
    }

    function markVibrationTriggered() as Void {
        _vibrationTriggered = true;
    }
}

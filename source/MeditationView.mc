import Toybox.Application;
import Toybox.ActivityMonitor;
import Toybox.Attention;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

//! Screen 1: Meditation Tracker – Press start to meditate
class Screen1View extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 15, Graphics.FONT_MEDIUM, "Meditation Tracker", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var app = Application.getApp() as MeditationApp;
        var vibrationMinutes = app.getVibrationMinutes();
        dc.drawText(centerX, centerY + 12, Graphics.FONT_SMALL, "Vibrate after: " + vibrationMinutes.toString() + " min", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, centerY + 36, Graphics.FONT_XTINY, "Up/Down set reminder", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, centerY + 56, Graphics.FONT_XTINY, "Press start to meditate", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

//! Screen 2: Timer + heart rate (live) while tracking
class Screen2View extends WatchUi.View {

    private var _app as MeditationApp;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _app = Application.getApp() as MeditationApp;
        _timer = null;
    }

    function onShow() as Void {
        _startTimer();
    }

    function onHide() as Void {
        _stopTimer();
    }

    private function _startTimer() as Void {
        _stopTimer();
        _timer = new Timer.Timer();
        _timer.start(method(:_onTick), 1000, true);
    }

    private function _stopTimer() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function _onTick() as Void {
        var app = Application.getApp() as MeditationApp;
        var hrModel = app.getHeartRateModel();
        var iter = ActivityMonitor.getHeartRateHistory(1, true);
        if (iter != null) {
            var sample = iter.next();
            if (sample != null && sample.heartRate != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                hrModel.addSample(sample.heartRate);
                hrModel.setLastHeartRate(sample.heartRate);
            }
        }
        var elapsed = app.getTimerModel().getTotalSeconds();
        if (app.shouldTriggerVibration(elapsed)) {
            _vibrateReminder();
            app.markVibrationTriggered();
        }
        WatchUi.requestUpdate();
    }

    private function _vibrateReminder() as Void {
        try {
            var pattern = [
                new Attention.VibeProfile(100, 500),
                new Attention.VibeProfile(0, 500),
                new Attention.VibeProfile(100, 500)
            ];
            Attention.vibrate(pattern);
        } catch (e) {
            System.println("Vibration failed: " + e.toString());
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var sec = _app.getTimerModel().getTotalSeconds();
        var secInt = sec.toNumber();
        var mins = secInt / 60;
        var secs = secInt % 60;
        var timeStr = Lang.format("$1$:$2$", [mins.format("%d"), secs.format("%02d")]);

        dc.drawText(centerX, 55, Graphics.FONT_NUMBER_HOT, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, 95, Graphics.FONT_XTINY, "timer", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var hr = _app.getHeartRateModel().getLastHeartRate();
        var hrStr = (hr != null) ? hr.toString() : "--";
        dc.drawText(centerX, height / 2 + 25, Graphics.FONT_NUMBER_MEDIUM, hrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var hrLabel = (hr != null) ? "heart rate (bpm)" : "heart rate (searching...)";
        dc.drawText(centerX, height / 2 + 55, Graphics.FONT_XTINY, hrLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

//! Screen 3: Overview – Time and average heart rate
class Screen3View extends WatchUi.View {

    private var _app as MeditationApp;

    function initialize() {
        View.initialize();
        _app = Application.getApp() as MeditationApp;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var sec = _app.getTimerModel().getTotalSeconds();
        var secInt = sec.toNumber();
        var mins = secInt / 60;
        var secs = secInt % 60;
        var timeStr = Lang.format("$1$:$2$", [mins.format("%d"), secs.format("%02d")]);
        var avgHr = _app.getHeartRateModel().getAverageHeartRate();

        dc.drawText(centerX, centerY - 75, Graphics.FONT_SMALL, "Time", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(centerX, centerY - 40, Graphics.FONT_NUMBER_HOT, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(centerX, centerY + 25, Graphics.FONT_SMALL, "Avg heart rate", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var avgHrStr = (avgHr != null) ? avgHr.toString() : "--";
        dc.drawText(centerX, centerY + 65, Graphics.FONT_NUMBER_MEDIUM, avgHrStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var avgHrLabel = (avgHr != null) ? "bpm" : "no heart rate data";
        dc.drawText(centerX, centerY + 95, Graphics.FONT_XTINY, avgHrLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

//! Screen 4: Sync to server – POST, then success or failure
class Screen4View extends WatchUi.View {

    private var _app as MeditationApp;

    function initialize() {
        View.initialize();
        _app = Application.getApp() as MeditationApp;
    }

    function onShow() as Void {
        _app.setSyncSending();
        _sendToServer();
    }

    private function _sendToServer() as Void {
        var totalSec = _app.getTimerModel().getTotalSeconds();
        var avgHr = _app.getHeartRateModel().getAverageHeartRate();
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var sessionDate = Lang.format("$1$-$2$-$3$", [
            info.year.format("%d"),
            info.month.format("%02d"),
            info.day.format("%02d")
        ]);
        var params = {
            "seconds_meditated" => totalSec.toNumber(),
            "average_heart_rate" => (avgHr != null) ? avgHr : 0,
            "session_date" => sessionDate
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "x-api-key" => ApiConfig.API_KEY
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(
            ApiConfig.API_URL,
            params,
            options,
            method(:onReceive)
        );
    }

    function onReceive(responseCode as Number, data as Dictionary or String or Null) as Void {
        var app = Application.getApp() as MeditationApp;
        if (responseCode == 200) {
            app.setSyncResult(true, null);
        } else {
            app.setSyncResult(false, "Error " + responseCode.toString());
            System.println("Sync failed: " + (data != null ? data.toString() : responseCode.toString()));
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var status = _app.getSyncStatus();
        if (status == 0) {
            dc.drawText(centerX, centerY - 20, Graphics.FONT_MEDIUM, "Sending...", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (status == 1) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 20, Graphics.FONT_MEDIUM, "Sent!", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, centerY - 30, Graphics.FONT_SMALL, "Failed", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            var err = _app.getSyncError();
            if (err != null && err.length() > 0) {
                dc.drawText(centerX, centerY + 15, Graphics.FONT_XTINY, err, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 30, Graphics.FONT_XTINY, "Select = Done", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

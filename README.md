# Meditation Tracker - Garmin Forerunner 255 Music

Monkey C **watch app** that tracks meditation time and heart rate, then syncs sessions to your backend (same API key as [GarminReadingApp](https://github.com/Lutu-gl/Garmin-Reading-App)).

## Features

- **Start**: "Meditation Tracker" – press **Select** to start a meditation session.
- **Reminder setup**: On start screen, set a vibration reminder in minutes with **Up/Down**.
- **Tracking**: Live **timer** (MM:SS) and **heart rate** (bpm). Press **Select** to stop.
- **Overview**: Session **time** and **average heart rate**. Press **Select** to send.
- **Send**: POST to your backend; shows "Sending...", "Sent!" or error.

---

## Storing API URL and API key (secrets)

The app needs `API_URL` and `API_KEY` at **build time** (they are compiled into the watch app). Use the **same API key** as your Garmin Reading App.

### .env file

1. Copy the example env file:
   ```bash
   cp .env.example .env
   ```
2. Edit `.env` and set your values (same `API_KEY` as Reading App; endpoint can be e.g. meditation-sessions):
   ```bash
   API_KEY=your_supabase_anon_or_service_role_key
   API_URL=https://YOUR_PROJECT_REF.supabase.co/functions/v1/meditation-sessions
   ```
3. Generate the config module (required before building):
   ```bash
   chmod +x scripts/generate_config.sh
   ./scripts/generate_config.sh
   ```
   This creates `source/ApiConfig.mc` from `.env`.

---

## Adding the app to your Garmin watch

### Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) installed (includes compiler and simulator).
- Your watch (e.g. Forerunner 255 Music) with heart rate sensor.

### 1. Configure secrets

Use the steps above so that `source/ApiConfig.mc` exists and contains your `API_KEY` and `API_URL`.

### 2. Launcher icon

The project uses `resources/drawables/launcher_icon.svg`. You can replace it with a PNG (e.g. 48×48) and reference it in `resources/drawables/drawables.xml` if needed.

### 3. Build the app

**From command line**

If you get **`command not found: monkeyc`**:

1. Install the [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and add its `bin` folder to your `PATH`. Typical macOS path:
   ```bash
   export PATH="$PATH:$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.1-2026-02-03-e9f77eeaa/bin"
   ```
2. Run the build script:
   ```bash
   ./scripts/build.sh
   ```
3. If the SDK requires a developer key:
   ```bash
   DEVELOPER_KEY=/path/to/your.der ./scripts/build.sh
   ```

Direct build:

```bash
mkdir -p bin
monkeyc -f monkey.jungle -o bin/MeditationTracker.prg -d fr255m
# With signing: add -y /path/to/developer_key.der
```

### 4. Run in the simulator

Open the Connect IQ Simulator, choose a device (e.g. Forerunner 255 Music), and use the IDE’s **Run** to build and load.

### 5. Install on your watch

After building, copy `bin/MeditationTracker.prg` to the watch’s `GARMIN/APPS` folder (e.g. via USB/MTP). The watch should be paired with Garmin Connect Mobile for HTTP sync to work.

---

## Project layout

```
GarminMeditationApp/
├── .env.example           # Example env vars (copy to .env; do not commit .env)
├── .gitignore             # .env, source/ApiConfig.mc, bin, etc.
├── manifest.xml           # App config, Communications permission
├── monkey.jungle           # Build manifest
├── source/
│   ├── MeditationApp.mc   # App entry, timer/HR state, sync status
│   ├── MeditationDelegate.mc  # TimerModel, HeartRateModel, Screen1–4 delegates
│   ├── MeditationView.mc  # Screen1–4 views (Start, Tracking, Overview, Send)
│   ├── ApiConfig.mc.template  # Template for API config
│   └── ApiConfig.mc       # Generated from .env; do not commit
├── scripts/
│   ├── build.sh           # Build for fr255m
│   └── generate_config.sh # Build ApiConfig.mc from .env
├── resources/
│   ├── drawables/
│   ├── strings/
│   └── layouts/
└── README.md
```

## App permissions

The app uses `Toybox.Communications.makeWebRequest`. The manifest includes:

```xml
<iq:permissions>
  <iq:uses-permission id="Communications"/>
  <iq:uses-permission id="Sensor"/>
  <iq:uses-permission id="SensorHistory"/>
</iq:permissions>
```

## Button mapping (Forerunner 255 Music)

- **Select** – Start session → Stop session → Confirm overview and send → Done (back to start).
- **Back** – Cancel from tracking (discard session) or from overview (back to tracking).

## Payload sent to backend

POST request with JSON body:

- `seconds_meditated` – total meditation time in seconds.
- `average_heart_rate` – average bpm during the session (0 if no HR data).
- `session_date` – date of the session in `YYYY-MM-DD` format (e.g. `"2026-03-04"`).

Headers: `Content-Type: application/json`, `x-api-key: <your API_KEY>` (same key as Garmin Reading App).

## Technical notes

- **Four phases**: Start (Screen1) → Tracking (Screen2, timer + live HR) → Overview (Screen3, time + avg HR) → Send (Screen4).
- **Vibration reminders**: configurable minute-based reminder on Screen1; single start vibration and double reminder vibration during tracking.
- **Heart rate**: `ActivityMonitor.getHeartRateHistory(1, true)` is polled every second during tracking; samples are summed for the average. Devices without HR or with no data show "— bpm".
- **Timer**: Same pattern as Garmin Reading App: `TimerModel` with `System.getTimer()`, 1 s refresh via `Timer.Timer` and `WatchUi.requestUpdate()`.

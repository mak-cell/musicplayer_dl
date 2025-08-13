# Read me file is AI generated content may slide varries
# 🎵 musicplayer_dl

A simple, hackable Flutter music player starter — focused on local audio playback with a clean baseline you can build on.

---


## Features
- ▶️ Play / ⏸ Pause / ⏩ Seek local audio
- Minimal UI you can extend
- Flutter-first architecture; easy to refactor into your pattern of choice

> **Note:** This is a starter template. Add or swap packages to match your needs (e.g.,  `audioplayers`, `file_picker`, state management, etc.).

---

## Demo (optional)
Add screenshots or a short GIF here later.

```
assets/readme/now_playing.png
assets/readme/library.png
```

---

## Requirements
- Flutter (stable channel) installed and on your `PATH`
- Android Studio or VS Code with Flutter/Dart extensions

Check your setup:
```bash
flutter doctor
```

---

## Quick Start (Step-by-Step)

**Step 1 — Clone**
```bash
git clone https://github.com/mak-cell/musicplayer_dl.git
cd musicplayer_dl
```

**Step 2 — Fetch dependencies**
```bash
flutter pub get
```

**Step 3 — (Optional) Add your audio files**  
Create an `assets/audio/` folder and configure it (see [Configure Assets](#configure-assets)).

**Step 4 — Run on a device/emulator**
```bash
flutter run
```

That’s it. You should land on the starter UI and be able to play local audio (after you wire in your preferred audio package and UI).

---

## Platform Setup

### Android
1. **Min SDK**: Ensure `minSdkVersion` is at least **21** in `android/app/build.gradle`.
2. **Permissions** (for reading device audio):
   - **Android 13+ (API 33+)** add to `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
     ```
   - **Android 12 and below** (if accessing external storage):
     ```xml
     <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
     ```
3. **Request runtime permission** in Dart when needed (for file/library access).

---

## Project Structure
```
musicplayer_dl/
├─ android/               # Android project
├─ lib/                   # Dart source (app code)
├─ test/                  # Tests
├─ pubspec.yaml           # App metadata & dependencies
├─ analysis_options.yaml  # Lints
└─ README.md
```

> Inside `lib/`, consider organizing as you grow:
> ```
> lib/
> ├─ main.dart
> ├─ features/
> │  ├─ player/
> │  └─ library/
> ├─ services/      # audio, storage, permissions
> ├─ widgets/
> └─ utils/
> ```

---

## Configure Assets

1. Create folders:
   ```
   mkdir -p assets/audio
   mkdir -p assets/images
   ```
2. Add your audio files to `assets/audio/`.
3. In `pubspec.yaml`, add:
   ```yaml
   flutter:
     assets:
       - assets/audio/
       # - assets/images/
   ```
4. Reload assets:
   ```bash
   flutter pub get
   ```

---

## Run, Build & Test

**Run (device/emulator)**
```bash
flutter run
```

**Hot reload**
- Press `r` in the terminal (or use your IDE button).

**Build APK (release)**
```bash
flutter build apk --release
```

**Build AppBundle (Play Store)**
```bash
flutter build appbundle --release
```

**Web release (if enabled)**
```bash
flutter build web
```

**Run tests**
```bash
flutter test
```

---

## Troubleshooting

- **App can’t see local audio on Android 13+**  
  Ensure `READ_MEDIA_AUDIO` is in the manifest and you handle runtime permission.

- **Gradle/AGP issues**  
  Run:
  ```bash
  flutter clean
  flutter pub get
  ```
  Then open `android/` in Android Studio to let it sync.

- **No sound / player errors**  
  Confirm the audio package is correctly added and initialized. Verify file paths and that assets are declared in `pubspec.yaml`.

---

## Roadmap / Ideas
- File picker / library browser
- Playlists & queue management
- Background playback & notification controls
- Simple equalizer / visualizer
- Persistence (recent, favorites)
- Theming (light/dark, dynamic color)

---

## Contributing
1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit: `git commit -m "feat: add my-feature"`
4. Push: `git push origin feat/my-feature`
5. Open a Pull Request

---

## License
No license is currently declared in this repository. Until a license is added, all rights are reserved by the author.  
If you are the owner, consider adding a `LICENSE` file (MIT/Apache-2.0/BSD-3-Clause are common choices).

# Agent instructions

## Cursor Cloud specific instructions

This repository contains a Flutter app in `q-reversi-app/`. In Cloud Agents, use **Flutter Web** for the edit → preview → verify loop.

### Dev server

- Flutter Web starts automatically on **port 8080** (see `.cursor/environment.json` → `terminals`).
- Preview URL: `http://localhost:8080`
- Open that URL in the VM browser (computer use or remote desktop) before relying on hot reload.
- After editing Dart files:
  - `r` — hot reload (requires a connected browser tab)
  - `R` — hot restart

### Common commands

```bash
cd q-reversi-app
flutter pub get
flutter test
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
flutter build web --base-href "/q-reversi/" --release
```

### Verification before PR

1. Confirm the Flutter Web terminal is running and serving on port 8080.
2. Open `http://localhost:8080` in Chrome inside the VM.
3. Click through the changed UI flows (menus, game board, tutorials, etc.).
4. Attach screenshots or a short screen recording to the PR when UI changes.

### Platform notes

- **Web vs mobile**: Most UI and game logic can be verified on Web. Native plugins (e.g. `sqflite`) may behave differently on Web, iOS, or Android.
- **iOS builds**: Require macOS and Xcode. Use [My Machines](https://cursor.com/docs/cloud-agent/my-machines.md) on a Mac for simulator or device testing.
- **Production Web deploy**: Pushes to `main` that touch `q-reversi-app/**` trigger GitHub Actions and deploy to https://qtechgaming.github.io/q-reversi/

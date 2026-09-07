# Frontend images

All image assets used by the UI live here. Reference them in code with
`Image.asset('assets/images/<filename>')` and make sure the folder stays
registered under `flutter > assets` in `pubspec.yaml`.

## Files
- `wristbands.png` — the L/R haptic wristband illustration shown on the login
  and "connecting" screens.
- `figure_left.png` — the "raise left hand" figure shown on the Left Wristband
  tile (Devices screen). Falls back to an "L" letter until added.
- `figure_right.png` — the "raise right hand" figure for the Right Wristband
  tile. Falls back to an "R" letter until added.

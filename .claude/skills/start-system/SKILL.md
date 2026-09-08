---
name: start-system
description: Start the Haptic Drive app locally (Flutter web on a stable port 8090). Use when the user says "start the system", "start the app", "run the app", "launch it", or wants to preview at localhost:8090.
---

Launch the Haptic Drive Flutter web app and serve it on a fixed port (8090) so the URL stays stable and no orphaned dev servers pile up.

Project dir: `c:\Users\USER\Desktop\Sense&Safe\app`

Steps:

1. **Free port 8090 first** (a previous dev server often still holds it; this also prevents orphaned `dart.exe` processes):
   ```
   powershell -NoProfile -Command "$c = Get-NetTCPConnection -State Listen -LocalPort 8090 -ErrorAction SilentlyContinue; if ($c) { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue }"
   ```

2. **Start the app in the background** from the project dir:
   ```
   cd "c:/Users/USER/Desktop/Sense&Safe/app" && flutter run -d web-server --web-port=8090
   ```
   Run it with `run_in_background: true` (it's long-running — do not block on it).

3. **Wait** until the run output contains `is being served at http://localhost:8090`.

4. **Verify reachability**:
   ```
   curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8090
   ```
   Expect `HTTP 200`.

5. **Tell the user** to open `http://localhost:8090` and hard-refresh (`Ctrl+Shift+R`) to clear any cached old build.

Notes / conventions:
- Always reuse **port 8090**; never hop to a new port — kill the holder (step 1) and reuse it.
- Use `-d web-server` (not `-d chrome`) so the user opens the URL in their own browser — easier than hunting for a Flutter-launched Chrome window.
- The dev server is terminated when a Claude Code session ends, so this skill is the normal way to bring it back up each session.
- After code changes, re-run this skill to rebuild (web-server doesn't hot-reload without a restart).

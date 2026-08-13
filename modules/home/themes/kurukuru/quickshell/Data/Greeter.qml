pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

import qs.Data as Dat

// Greetd session state for greeter.qml. Kept as a singleton (like
// Data/Launcher.qml) rather than inline in the surface, since the auth
// conversation (createSession -> authMessage* -> respond -> readyToLaunch
// -> launch) is stateful and only ever needs one instance regardless of
// how many monitors greeter.qml is showing wallpaper on.
Singleton {
  id: root

  // Set by scripts/test-greeter.sh (or by hand: `KURU_GREETER_MOCK=1
  // quickshell -p greeter.qml`) to run the whole UI flow without a real
  // greetd socket - lets you iterate on the look/feel from inside your
  // normal logged-in session instead of round-tripping through
  // greetd/niri restarts every time. See handoff.md's Greeter session.
  readonly property bool mockMode: Quickshell.env("KURU_GREETER_MOCK") === "1"

  property string username: Quickshell.env("USER") ?? ""
  property string password: ""
  property bool passwordVisible: false
  property bool busy: false
  property string errorMessage: ""
  property int sessionIndex: 0
  // Which output currently shows the login card - "" means "not decided
  // yet, fall back to screens[0]" (see Layers/Greeter.qml). Updated by a
  // HoverHandler on every output's surface, so moving the mouse to a
  // different monitor moves the card there too - deliberately global
  // singleton state rather than per-surface, since there's exactly one
  // login attempt in flight regardless of how many monitors are
  // connected (same one-`open`-pair reasoning as Data/Launcher.qml).
  property string focusedOutput: ""

  function focusOutput(name) {
    if (root.focusedOutput !== name)
      root.focusedOutput = name;
  }

  // [{name, exec: [string]}], populated from scripts/session.sh - see
  // sessionScan below
  property var sessions: []

  readonly property var selectedSession: (root.sessions.length > 0) ? root.sessions[root.sessionIndex % root.sessions.length] : null

  function cycleSession() {
    if (root.sessions.length === 0)
      return;
    root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length;
  }

  // Entry point from the Login button / Enter key. Real flow hands off to
  // Greetd (see the Connections block below); mock flow just fakes the
  // same busy -> settle round trip so the UI code path doesn't fork
  // between "testing" and "real" beyond this one function.
  function submit() {
    if (root.busy || root.username.length === 0)
      return;
    root.errorMessage = "";
    root.busy = true;

    if (root.mockMode) {
      mockTimer.restart();
      return;
    }

    if (!Greetd.available) {
      root.errorMessage = "greetd socket not available (is this running under greetd?)";
      root.busy = false;
      return;
    }

    Greetd.createSession(root.username);
  }

  Timer {
    id: mockTimer

    interval: 500

    onTriggered: {
      const exec = root.selectedSession?.exec?.join(" ") ?? "(no session found)";
      console.log("[MOCK] would launch \"" + exec + "\" for user " + root.username);
      root.busy = false;
      root.password = "";
    }
  }

  // Real greetd wiring. Only touches Greetd (respond/launch) when not in
  // mockMode - Greetd.available is false outside a real greetd session
  // anyway, so submit() above never gets this far in that case, but
  // gating the Connections target too means a stray authMessage from a
  // leftover socket can't clobber mock-mode UI state.
  Connections {
    target: (root.mockMode) ? null : Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (error) {
        // recoverable prompt-level error (e.g. a fingerprint misread) -
        // surface it but keep the conversation going, don't reset busy
        root.errorMessage = message;
        return;
      }
      if (responseRequired) {
        // This greeter only ever has one input field, so every prompt
        // greetd sends (whatever its wording) gets the password field's
        // contents. Fine for the standard pam_unix password prompt this
        // is built around; a greeter that wants to support e.g. a
        // separate PIN/fingerprint conversation would need to branch on
        // `message`/`echoResponse` here instead - not implemented.
        Greetd.respond(root.password);
      }
    }

    function onAuthFailure(message) {
      root.errorMessage = message || "Login failed";
      root.password = "";
      root.busy = false;
    }

    function onReadyToLaunch() {
      const cmd = root.selectedSession?.exec ?? ["niri", "--session"];
      Greetd.launch(cmd);
    }
  }

  // Scans /usr/share/wayland-sessions + /usr/share/xsessions with the
  // (previously unused) scripts/session.sh, which awk's `Name=`/`Exec=`
  // out of each *.desktop file and prints "filename,Name,Exec" per line.
  // X11 sessions are included for completeness even though this shell
  // targets niri/mangowc (see CLAUDE.md) - harmless to list, greetd just
  // won't be handed a working display if one's actually picked without
  // an X server around.
  Process {
    id: sessionScan

    // NixOS doesn't drop session .desktop files in /usr/share/* - it
    // aggregates services.displayManager.sessionPackages into
    // /run/current-system/sw/share/{wayland-sessions,xsessions}. Scanning
    // the FHS paths here always found nothing on NixOS, which is why the
    // picker showed "(none found)" even with a session package registered.
    command: ["bash", "-c", "bash " + Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/session.sh")) + " /run/current-system/sw/share/wayland-sessions 2>/dev/null; bash " + Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/session.sh")) + " /run/current-system/sw/share/xsessions 2>/dev/null"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        const parts = line.split(",");
        if (parts.length < 3)
          return;
        const name = parts[1];
        // Exec= can itself contain commas in field codes (rare) - rejoin
        // anything after the second comma rather than assuming exactly 3
        // fields
        const exec = parts.slice(2).join(",").trim();
        if (!name || !exec)
          return;
        root.sessions = root.sessions.concat([{
          "name": name,
          "exec": ["sh", "-c", exec]
        }]);
      }
    }
  }
}

pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

import qs.Data as Dat

// Greetd session state for greeter.qml. Singleton (like
// Data/Launcher.qml) since the auth conversation is stateful and only
// needs one instance regardless of monitor count.
Singleton {
  id: root

  // set via `KURU_GREETER_MOCK=1 quickshell -p greeter.qml` (or
  // scripts/test-greeter.sh) to run the UI without a real greetd
  // socket - see handoff.md's Greeter session
  readonly property bool mockMode: Quickshell.env("KURU_GREETER_MOCK") === "1"

  property string username: Quickshell.env("USER") ?? ""
  property string password: ""
  property bool passwordVisible: false
  property bool busy: false
  property string errorMessage: ""
  property int sessionIndex: 0
  // which output shows the login card - "" falls back to screens[0]
  // (Layers/Greeter.qml). Updated by a HoverHandler per output, global
  // since there's exactly one login attempt regardless of monitor count.
  property string focusedOutput: ""

  function focusOutput(name) {
    if (root.focusedOutput !== name)
      root.focusedOutput = name;
  }

  // [{name, exec: [string]}], from scripts/session.sh - see sessionScan
  property var sessions: []

  readonly property var selectedSession: (root.sessions.length > 0) ? root.sessions[root.sessionIndex % root.sessions.length] : null

  function cycleSession() {
    if (root.sessions.length === 0)
      return;
    root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length;
  }

  // Entry point from Login/Enter. Mock flow fakes the same
  // busy -> settle round trip so the UI doesn't fork between test/real.
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

  // gated so a stray authMessage from a leftover socket can't clobber
  // mock-mode UI state
  Connections {
    target: (root.mockMode) ? null : Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (error) {
        // recoverable (e.g. fingerprint misread) - surface, keep going
        root.errorMessage = message;
        return;
      }
      if (responseRequired) {
        // single input field, so every prompt gets the password field's
        // contents - fine for standard pam_unix, but a PIN/fingerprint
        // flow would need to branch on message/echoResponse here
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

  // Scans wayland-sessions + xsessions with scripts/session.sh, which
  // awks Name=/Exec= out of each .desktop file. X11 sessions listed
  // for completeness even though this shell targets niri/mangowc.
  Process {
    id: sessionScan

    // NixOS puts session .desktop files under
    // /run/current-system/sw/share/*, not /usr/share/* - scanning the
    // FHS paths found nothing here even with a session package registered.
    command: ["bash", "-c", "bash " + Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/session.sh")) + " /run/current-system/sw/share/wayland-sessions 2>/dev/null; bash " + Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/session.sh")) + " /run/current-system/sw/share/xsessions 2>/dev/null"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        const parts = line.split(",");
        if (parts.length < 3)
          return;
        const name = parts[1];
        // Exec= can contain commas in field codes (rare), so rejoin
        // everything after the second comma
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

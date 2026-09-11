pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

import qs.Data as Dat

Singleton {
  id: root

  readonly property bool mockMode: Quickshell.env("TEAKETTLER_GREETER_MOCK") === "1"

  property string username: Quickshell.env("USER") ?? ""
  property string password: ""
  property bool passwordVisible: false
  property bool busy: false
  property string errorMessage: ""
  property int sessionIndex: 0
  property string focusedOutput: ""

  function focusOutput(name) {
    if (root.focusedOutput !== name)
      root.focusedOutput = name;
  }

  property var sessions: []

  readonly property var selectedSession: (root.sessions.length > 0) ? root.sessions[root.sessionIndex % root.sessions.length] : null

  function cycleSession() {
    if (root.sessions.length === 0)
      return;
    root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length;
  }

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

  Connections {
    target: (root.mockMode) ? null : Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (error) {
        root.errorMessage = message;
        return;
      }
      if (responseRequired) {
        Greetd.respond(root.password);
      }
    }

    function onAuthFailure(message) {
      root.errorMessage = message || "Login failed";
      root.password = "";
      root.busy = false;
    }

    function onReadyToLaunch() {
      const cmd = root.selectedSession?.exec ?? ["mango"];
      Greetd.launch(cmd);
    }
  }

  Process {
    id: sessionScan

    command: ["bash", "-c", "bash " + Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/session.sh")) + " /run/current-system/sw/share/wayland-sessions; bash " + Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/session.sh")) + " /run/current-system/sw/share/xsessions"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        const tab = line.indexOf("\t");
        if (tab < 0)
          return;
        const name = line.slice(0, tab).trim();
        const exec = line.slice(tab + 1).trim();
        if (!name || !exec)
          return;
        root.sessions = root.sessions.concat([{
          "name": name,
          "exec": ["sh", "-c", exec]
        }]);
      }
    }

    stderr: SplitParser {
      onRead: line => console.log("[sessionScan] " + line)
    }
    onExited: (code) => {
      if (code !== 0)
        console.log("[sessionScan] exited with code " + code);
    }
  }
}

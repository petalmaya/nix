pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Themed polkit agent; only one system agent runs at a time (see README/handoff).
// Mirrors Data/Greeter.qml; requests arrive unsolicited, so no show()/toggle().
Singleton {
  id: root

  readonly property var flow: agent.flow
  property bool interactionAvailable: false
  property bool failed: false

  // true for the lifetime of a single auth request, not "is this
  // shell's agent registered" (that happens once, on startup)
  readonly property bool active: agent.isActive

  readonly property string message: root.flow ? root.flow.message : ""
  readonly property string cleanPrompt: {
    if (!root.flow)
      return "Password";
    let prompt = root.flow.inputPrompt.trim();
    if (prompt.endsWith(":"))
      prompt = prompt.slice(0, -1);
    return prompt || (root.flow.responseVisible ? "Input" : "Password");
  }

  function cancel() {
    if (root.flow)
      root.flow.cancelAuthenticationRequest();
  }

  function submit(response) {
    if (root.flow) {
      root.flow.submit(response);
      root.interactionAvailable = false;
    }
  }

  PolkitAgent {
    id: agent

    onAuthenticationRequestStarted: {
      root.interactionAvailable = true;
      root.failed = false;
    }
  }

  Connections {
    function onAuthenticationFailed() {
      root.interactionAvailable = true;
      root.failed = true;
    }

    target: root.flow
  }
}

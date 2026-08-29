pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Themed replacement for whatever generic polkit agent (pkexec's own,
// polkit-gnome) was answering "Authentication Required" prompts before -
// those don't pick up Colors.qml/matugen theming at all. Quickshell's
// PolkitAgent registers as THE system agent while this shell runs; see
// README/handoff for the one-agent-at-a-time caveat if a DE's own
// agent is still autostarting somewhere.
//
// Shape mirrors Data/Greeter.qml (own singleton, wraps the auth
// conversation) rather than Data/Launcher.qml's open/close bool -
// requests arrive unsolicited, there's no show()/toggle() call site.
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

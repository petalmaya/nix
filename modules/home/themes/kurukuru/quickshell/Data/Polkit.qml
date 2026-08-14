pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// Themed replacement for whatever generic polkit agent (pkexec's own,
// polkit-gnome, etc.) was previously answering "Authentication Required"
// prompts - those don't pick up Colors.qml/matugen theming at all, hence
// the "bullshit things that don't match" complaint this singleton exists
// to fix. Quickshell ships a real PolkitAgent (Quickshell.Services.Polkit)
// that registers as THE system polkit agent while this shell is running -
// once this is active there should be no other agent left to race it, but
// see README/handoff for the one-agent-at-a-time caveat if a DE's own
// agent is still being autostarted somewhere.
//
// Shape mirrors Data/Greeter.qml's request/respond pattern (own singleton,
// wraps the actual auth conversation, a Layers/*.qml surface just reads
// state off it) rather than Data/Launcher.qml's open/close bool - polkit
// requests arrive unsolicited from the system, there's no show()/toggle()
// call site anywhere in this shell.
Singleton {
  id: root

  readonly property var flow: agent.flow
  property bool interactionAvailable: false
  property bool failed: false

  // agent.isActive is true for the lifetime of a single auth request
  // (from the requesting process asking, to it being answered/cancelled),
  // NOT "is this shell's agent registered" - that registration happens
  // once, for as long as PolkitAgent exists at all.
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

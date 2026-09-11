//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma IconTheme Papirus-Dark

pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import qs.Layers as Lay
import qs.Data as Dat

// Shell entry point - which surfaces exist per monitor. Look/behavior lives under Layers/.
ShellRoot {
  // One Scope per monitor; unplugging one drops its Scope automatically.
  Variants {
    model: Quickshell.screens

    Scope {
      id: scopeRoot

      required property ShellScreen modelData

      // Only builds `component` while `activeAsync` holds, skipping its cost while off.
      LazyLoader {
        activeAsync: Dat.Config.data.reservedShell

        component: Lay.PseudoReserved {
          modelData: scopeRoot.modelData
        }
      }

      // Desktops are drawn by swaybg (scripts/wallpaper.sh), not here.
      // Lock/greeter backgrounds stay in-shell via Widgets/Wallpaper.

      // Core per-monitor surfaces, always present.
      Lay.Notch {
        modelData: scopeRoot.modelData
      }

      Lay.QuickOptions {
        modelData: scopeRoot.modelData
      }

      Lay.Dock {
        modelData: scopeRoot.modelData
      }

      Lay.Launcher {
        modelData: scopeRoot.modelData
      }

      Lay.VolumeOsd {
        modelData: scopeRoot.modelData
      }

      // Inhibit Quickshell's reload popup (noisy while editing config files).
      Connections {
        function onReloadCompleted() {
          Quickshell.inhibitReloadPopup();
        }

        function onReloadFailed() {
          Quickshell.inhibitReloadPopup();
        }

        target: Quickshell
      }
    }
  }

  // Single lock session for the whole system, not one per monitor.
  Lay.LockScreen {
  }

  // Same: one system-wide polkit conversation, picks its own screen internally.
  Lay.PolkitAgent {
  }
}

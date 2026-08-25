# Vendored source: Centaur Emacs

| | |
|---|---|
| **Source** | <https://github.com/seagle0128/.emacs.d> |
| **Author** | Vincent Zhang (seagle0128) |
| **Version** | 8.3.1 |
| **Retrieved** | 2026-08-25 |
| **License** | GNU GPL v3 or later (see `../LICENSE`) |

The `lisp/init-*.el` files in this directory are the Centaur Emacs
configuration modules, vendored wholesale into Flutter Emacs. All
original copyright headers are retained.

## Modifications

- **Renamed**: every `centaur-*` symbol renamed to `flutter-*`
  (mechanical `sed`, plus manual fixes). File and feature names
  (`init-*`) are unchanged.
- **init-custom.el**: dropped the `flutter-logo` defcustom and the
  theme-machinery defcustoms (`flutter-theme-alist`,
  `flutter-auto-themes`, `flutter-system-themes`, `flutter-theme`);
  `defgroup centaur` → `defgroup flutter`; `flutter-player` default
  flipped to `t` (MPD is enabled on the hosts); removed the
  `(eval-when-compile (require 'package))` header (it loaded package.el
  before Elpaca and tripped Elpaca's "Package.el loaded before Elpaca"
  warning).
- **init-funcs.el**: theme machinery functions
  (`flutter--theme-name`, `flutter-compatible-theme-p`,
  `flutter-theme-enable-p`, `flutter--load-theme`,
  `flutter--load-system-theme`, `flutter-load-random-theme`, the
  circadian/auto-dark `flutter-load-theme`, and the `consult-theme`
  advice) replaced with a simple `flutter-load-theme` that loads the
  `flutterice` theme. `flutter-dark-theme-p` kept (used by
  init-check.el). `update-packages` now prefers `elpaca-update-all`.
  `flutter-homepage` now points at the local Nix repo (`~/nix`).
- **init-package.el**: rewritten for Elpaca — removed package.el
  initialization, mirror selection, and the Windows "all packages in
  one dir" hacks; kept use-package setup, custom-file/custom-post
  loading, and the update machinery. The package-menu prettification
  is now guarded with `facep` — the faces only exist after package.el
  loads, which never happens under Elpaca, and an unguarded
  `set-face-attribute` was a fatal startup error.
- **init-ui.el**: removed the doom-themes block and the
  `fancy-splash-image` logo reference; frame title now
  "Flutter Emacs - %b".
- **init-dashboard.el**: banner title "Flutter Emacs"; the Centaur
  logo was dropped so `dashboard-startup-banner` is `'official`;
  footer reads "Powered by Flutter Emacs".
- **init-hydra.el**: the Theme section of the toggles hydra now has a
  single "flutterice" reload plus `consult-theme`; everything else
  (toggles, proxies, package archives) unchanged.
- **init-const.el**: `flutter-homepage` repointed at the local repo.
- **init-edit.el**: `elec-pair` marked `:ensure nil` — it is not a
  real package, just a config hook for the built-in
  `electric-pair-mode`; package.el swallowed the failed install
  silently, Elpaca fails loudly.

## Renaming

All user-facing "flutterice Emacs" branding (frame title, dashboard
banner/footer, hydra titles, docstrings) was renamed to **Flutter
Emacs**. The `flutterice` theme (matugen-generated, `themes/
flutterice-theme.el`) keeps its name.

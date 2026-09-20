# NOTICE — Nixtop licensing

The NixOS configuration in this repository (flake, hosts, modules,
assets) is licensed under the **Apache License, Version 2.0**
(see `LICENSE` at the repo root), **except** for the vendored
third-party subtrees below, which keep their own licenses:

- `modules/emacs/emacs/` — **GPL-3.0-or-later** (Centaur Emacs fork).
  See `modules/emacs/emacs/LICENSE` and `modules/emacs/emacs/NOTICE.md`.
  The GPL applies to that subtree, not to the rest of this repo.
- `modules/shell/quickshell/shell/` — derived from
  [Zaphkiel](https://github.com/Rexcrazy804/Zaphkiel) (**MIT**,
  © 2024-2026 Rexiel Scarlet). Full text in
  `modules/shell/quickshell/NOTICE-Zaphkiel.md`.
  One file, `shell/Generics/CircularProgress.qml`, is additionally
  **LGPL-3.0** (from
  [rafzby/circular-progressbar](https://github.com/rafzby/circular-progressbar));
  its header stays verbatim.
- `modules/shell/jes/{shell,config,go,jes-cli}` — vendored fork of
  [just_enough_shell](https://github.com/ORFLEM/just_enough_shell)
  (**BSD-3-Clause**, © 2026 ORFLEM), pinned at the commit in
  `modules/shell/jes/UPSTREAM`. Upstream license text is vendored as
  `modules/shell/jes/LICENSE.upstream`.

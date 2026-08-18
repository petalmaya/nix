;;; my-dev.el --- LSP, tree-sitter, git, project management -*- lexical-binding: t; -*-
;;; Commentary:
;; Uses built-in eglot (not lsp-mode) and built-in project.el (not
;; projectile) — both are first-party, actively developed, and need
;; zero extra packages. Language servers themselves come from the
;; Nix flake, not from elpaca.
;;; Code:

;; --- Tree-sitter -----------------------------------------------------
;; Emacs 29+ ships tree-sitter support; treesit-auto handles installing
;; grammars and remapping `foo-mode' -> `foo-ts-mode' transparently.
(use-package treesit-auto
  :custom (treesit-auto-install 'prompt)
  :config
  (global-treesit-auto-mode 1))

;; --- Eglot (built-in LSP client) --------------------------------------
(use-package eglot
  :ensure nil
  :hook ((python-ts-mode rust-ts-mode typescript-ts-mode
          js-ts-mode c-ts-mode c++-ts-mode nix-mode
          bash-ts-mode json-ts-mode) . eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0) ; skip logging for perf
  (eglot-extend-to-xref t)
  :config
  ;; nil / rust-analyzer / pyright etc. all come from PATH via the
  ;; flake devShell — eglot just needs to know the command names.
  (add-to-list 'eglot-server-programs '(nix-mode . ("nil"))))

(use-package consult-eglot :after (consult eglot))

;; --- Flymake (built-in linting, works with or without eglot) -----------
(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom (flymake-no-changes-timeout 0.5))

;; --- Terminal ---------------------------------------------------------
;; ghostel: in-Emacs terminal via libghostty-vt (Ghostty's VT engine).
;; Not on MELPA, pulled from GitHub; native module auto-downloads a
;; prebuilt binary on first `M-x ghostel', no Zig toolchain needed.
(use-package ghostel
  :ensure (:host github :repo "dakra/ghostel")
  :commands (ghostel ghostel-project ghostel-project-list-buffers)
  :config
  (add-to-list 'project-switch-commands '(ghostel-project "Ghostel") t))

;; --- Project management (built-in project.el) ---------------------------
(use-package project
  :ensure nil
  :custom
  (project-vc-extra-root-markers '(".project-root" "flake.nix" "Cargo.toml" "package.json" "pyproject.toml")))

;; --- Git -------------------------------------------------------------------
;; Explicit + :demand so Elpaca fully installs the real transient
;; before magit needs it (see the elpaca-ignored-dependencies note
;; in lisp/my-elpaca.el for why this is necessary on Emacs 30+).
(use-package transient
  :demand t
  :ensure (:host github :repo "magit/transient"))

(use-package magit
  :after transient
  :commands (magit-status magit-blame-addition magit-log-current
             magit-commit magit-push magit-pull magit-diff-buffer-file
             magit-stage-file)
  :custom (magit-diff-refine-hunks t))

(use-package git-timemachine :commands git-timemachine)

(use-package diff-hl
  :hook ((prog-mode . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh)))

;; --- Language-specific niceties (all lean on the flake's tools) ---------
(use-package nix-mode :mode "\\.nix\\'")
(use-package markdown-mode :mode "\\.md\\'")
(use-package yaml-mode :mode "\\.ya?ml\\'")
(use-package toml-mode :mode "\\.toml\\'")

;; --- Dired quality of life -------------------------------------------------
(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-alh --group-directories-first")
  (dired-dwim-target t)
  (dired-kill-when-opening-new-dired-buffer t))

(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map ("TAB" . dired-subtree-toggle)))

(provide 'my-dev)
;;; my-dev.el ends here

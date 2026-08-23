;;; init.el --- entry point -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Structure:
;;   early-init.el       startup perf / frame / transparency (loaded automatically first)
;;   init.el              this file: bootstraps Elpaca, loads lisp/*.el in order
;;   lisp/my-elpaca.el     package manager bootstrap + use-package integration
;;   lisp/my-core.el       sane Emacs defaults (no evil, no vim emulation)
;;   lisp/my-ui.el         fonts, theme loading, modeline, which-key, transparency, dashboard
;;   lisp/my-completion.el vertico/consult/embark/corfu minibuffer+in-buffer completion
;;   lisp/my-modal.el      god-mode "command mode" — stock Emacs binds, typed modally
;;   lisp/my-leader.el     general.el SPC leader menu, xah-fly-keys-inspired
;;   lisp/my-dev.el        eglot, treesit, magit, project.el, flymake, terminal
;;   lisp/my-qml.el        Quickshell/QML editing support (tree-sitter + qmlls)
;;   lisp/my-org.el        org-mode + org-modern
;;   lisp/my-media.el       empv/nov/elfeed/ement/elcord — media & comms
;;   themes/flutterice-theme.el   your matugen-generated theme, dropped in as-is
;;
;; Files are loaded in the exact order listed below — that order is
;; encoded here, not in the filenames, so nothing needs renumbering
;; when you insert a new module. Prefixed `my-' (rather than bare
;; `core', `ui', `org', etc.) on purpose: several of those short names
;; are also feature names real packages use (`org', `completion',
;; `elpaca' itself), and a same-named `(provide ...)` here would
;; shadow the real package and break everything that (require)s it.
;;
;;; Code:

(defvar my/lisp-dir (expand-file-name "lisp" user-emacs-directory))
(defvar my/theme-dir (expand-file-name "themes" user-emacs-directory))
(add-to-list 'load-path my/lisp-dir)
(add-to-list 'custom-theme-load-path my/theme-dir)

;; Keep `custom-set-variables' noise out of this file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

(require 'my-elpaca)     ; package manager, must load first
(require 'my-core)       ; editing defaults
(require 'my-ui)         ; theme, fonts, modeline, transparency, dashboard
(require 'my-completion) ; vertico/corfu/consult/embark
(require 'my-modal)      ; god-mode command-mode layout
(require 'my-leader)     ; general.el SPC leader + which-key
(require 'my-dev)        ; eglot/treesit/magit/project/terminal
(require 'my-qml)        ; Quickshell/QML editing
(require 'my-org)        ; org-mode
(require 'my-media)      ; empv/nov/elfeed/ement/elcord

;;; init.el ends here

;;; my-core.el --- sane Emacs defaults -*- lexical-binding: t; -*-
;;; Commentary:
;; Nothing modal lives here — just "make stock Emacs behave like a
;; modern editor" defaults every Spacemacs/Doom user expects.
;;; Code:

(use-package emacs
  :ensure nil
  :custom
  (user-full-name "You")
  (ring-bell-function #'ignore)
  (use-short-answers t)              ; y/n instead of yes/no
  (create-lockfiles nil)
  (make-backup-files nil)
  (auto-save-default t)
  (auto-save-interval 200)
  (delete-by-moving-to-trash t)
  (confirm-kill-emacs nil)
  (sentence-end-double-space nil)
  (require-final-newline t)
  (indent-tabs-mode nil)
  (tab-width 4)
  (fill-column 80)
  (scroll-margin 4)
  (scroll-conservatively 101)        ; never recenter on scroll
  (scroll-preserve-screen-position t)
  (mouse-wheel-progressive-speed nil)
  (kill-do-not-save-duplicates t)
  (help-window-select t)
  (echo-keystrokes 0.02)
  (uniquify-buffer-name-style 'forward)
  (native-comp-async-report-warnings-errors 'silent)
  (custom-safe-themes t)
  (large-file-warning-threshold (* 50 1024 1024))
  :init
  (global-auto-revert-mode 1)        ; buffers follow disk changes
  (setq global-auto-revert-non-file-buffers t)
  (delete-selection-mode 1)          ; typing over a selection replaces it
  (electric-pair-mode 1)             ; auto-close () [] {} ""
  (show-paren-mode 1)
  (setq show-paren-context-when-offscreen 'child-frame)
  (column-number-mode 1)
  (save-place-mode 1)                ; reopen files at last position
  (winner-mode 1)                    ; undo/redo window layout
  (windmove-default-keybindings 'meta) ; M-<arrows> switch windows
  :hook
  (prog-mode . display-line-numbers-mode)
  (prog-mode . hs-minor-mode)        ; code folding backend
  (before-save-hook . delete-trailing-whitespace))

;; --- History / persistence across restarts --------------------------
(use-package savehist
  :ensure nil
  :init (savehist-mode 1)
  :custom
  (history-length 1000)
  (savehist-additional-variables '(kill-ring search-ring regexp-search-ring)))

(use-package recentf
  :ensure nil
  :init (recentf-mode 1)
  :custom
  (recentf-max-saved-items 300)
  (recentf-exclude '("/elpaca/" "\\.gz\\'" "/tmp/")))

(use-package no-littering
  ;; keeps auto-saves/transient-history/eln-cache etc out of ~/.emacs.d root
  :demand t
  :config
  (setq no-littering-etc-directory (expand-file-name "etc/" user-emacs-directory)
        no-littering-var-directory (expand-file-name "var/" user-emacs-directory))
  (require 'no-littering)
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))

;; --- Undo -------------------------------------------------------------
(use-package undo-fu
  :custom
  (undo-limit (* 64 1024 1024))
  (undo-strong-limit (* 96 1024 1024))
  (undo-outer-limit (* 960 1024 1024)))

(use-package undo-fu-session
  :demand t
  :config (global-undo-fu-session-mode 1))

(use-package vundo
  :commands vundo
  :custom (vundo-glyph-alist vundo-unicode-symbols))

;; --- Editing helpers ---------------------------------------------------
(use-package expand-region :commands er/expand-region)

(use-package multiple-cursors
  :commands (mc/mark-next-like-this mc/mark-previous-like-this
             mc/mark-all-like-this mc/edit-lines))

(use-package avy
  :commands (avy-goto-char-timer avy-goto-line))

(use-package smartparens
  :hook (prog-mode . smartparens-mode)
  :custom (sp-escape-quotes-after-insert nil))

(use-package rainbow-delimiters :hook (prog-mode . rainbow-delimiters-mode))

;; helpful docs (used by both the leader "help" menu and describe-*)
(use-package helpful
  :commands (helpful-callable helpful-variable helpful-key helpful-command))

(provide 'my-core)
;;; my-core.el ends here

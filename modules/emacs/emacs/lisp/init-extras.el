;;; init-extras.el --- QML + media extras (carried from the old config) -*- lexical-binding: t -*-

;; Copyright (C) 2026 Alice (Flutter Emacs)

;; This file is part of Flutter Emacs, a fork of Centaur Emacs
;; (GPL-3.0, copyright Vincent Zhang — see vendor/centaur/NOTICE.md).
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; The handful of things the old config had that Centaur
;; simply doesn't cover, carried over and written in Centaur's style so
;; they don't feel bolted on:
;;
;;   qml-ts-mode + qmlls  editing Quickshell/QML (this repo's quickshell/)
;;   nix-mode + nil       the Nix language server (from the flake)
;;   empv / ement / elcord  mpv frontend, Matrix client, Discord presence
;;
;; Media commands live in a `pretty-hydra' (C-c m), matching the hydra
;; idiom the rest of the config uses.  The extra binaries (qmlls, nil,
;; mpv, ...) come from the Nix flake — see modules/home/apps/emacs/
;; default.nix.
;;
;;; Code:

;; --- Completion style ---------------------------------------------------
;; Minibuffer vertico/orderless is the default (see
;; `flutter-completion-style' in vendor/centaur/lisp/init-custom.el).
;; Flip it to 'childframe with M-x customize for Centaur's floating
;; posframe look.

;; --- Nix ---------------------------------------------------------------
;; nil comes from the flake; eglot auto-starts it because init-lsp.el
;; hooks eglot-ensure onto prog-mode and nix-mode derives from it.
(use-package nix-mode
  :mode "\\.nix\\'")

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(nix-mode . ("nil"))))

;; --- QML (Quickshell) ----------------------------------------------------
;; Grammar isn't on MELPA: registers the fetch source, actual install
;; happens on first .qml visit (or M-x treesit-install-language-grammar).
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(qmljs "https://github.com/yuja/tree-sitter-qmljs")))

;; qml-ts-mode isn't on MELPA either — pull it straight from its repo,
;; same as Quickshell's own docs point at.
(use-package qml-ts-mode
  :ensure (:host github :repo "xhcoding/qml-ts-mode")
  :mode ("\\.qml\\'" . qml-ts-mode)
  :hook (qml-ts-mode . (lambda ()
                         (setq-local electric-indent-chars
                                     '(?\n ?\( ?\) ?{ ?} ?\[ ?\] ?\; ?\,))
                         (eglot-ensure))))

;; qmlls comes from Qt6's declarative dev tools (see default.nix).
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(qml-ts-mode . ("qmlls"))))

;; --- Media: empv / ement / elcord ----------------------------------------
;; empv: mpv frontend — local files, YouTube, radio streams.  Needs the
;; `mpv' binary on PATH (flake).
(use-package empv
  :commands (empv-play-or-enqueue empv-youtube empv-play-radio
             empv-toggle empv-playlist-next empv-playlist-prev)
  :custom
  (empv-audio-dir "~/Music")
  (empv-video-dir "~/Videos")
  (empv-invidious-instance "https://invidious.nerdvpn.de/api/v1"))

;; ement: Matrix client (GNU ELPA). `ement-connect' prompts for
;; homeserver/user/password; repeat with C-u for a second account.
(use-package ement
  :commands (ement-connect ement-list-rooms))

;; elcord: Discord Rich Presence — broadcasts current buffer/mode.
;; Off by default since it's a per-session thing; flip it from the
;; media hydra (C-c m d).
(use-package elcord
  :commands elcord-mode
  :custom
  (elcord-display-buffer-details t)
  (elcord-use-major-mode-as-main-icon t))

;; Ghostel's project entries live in init-shell.el (loaded earlier);
;; not duplicated here.

;; --- Media hydra ----------------------------------------------------------
;; The config's idiom is hydras (see init-hydra.el); give the media
;; extras the same treatment so they feel native.
(use-package pretty-hydra
  :ensure nil
  ;; Skip (rather than break init) when the build is missing; the
  ;; `:pretty-hydra' fallback in my-elpaca.el already kept parsing safe.
  :if (or (featurep 'pretty-hydra) (locate-library "pretty-hydra"))
  ;; Same idiom as init-hydra.el: the hydra is defined when pretty-hydra
  ;; loads (first F6 or C-c m press), and every command it calls is
  ;; autoloaded via the :commands above, so nothing needs eager loading.
  :bind ("C-c m" . flutter-media-hydra/body)
  :config
  (pretty-hydra-define flutter-media-hydra
    (:title (pretty-hydra-title "Media" 'faicon "nf-fa-music")
     :color amaranth :quit-key ("q" "C-g"))
    ("Player"
     (("p" empv-play-or-enqueue "play/enqueue")
      ("y" empv-youtube "youtube search")
      ("r" empv-play-radio "radio")
      ("SPC" empv-toggle "play/pause")
      ("n" empv-playlist-next "next track")
      ("N" empv-playlist-prev "prev track"))
     "Feeds"
     (("e" elfeed "elfeed")
      ("u" (progn (require 'elfeed) (elfeed-update)) "update feeds"))
     "Matrix"
     (("m" ement-connect "connect")
      ("l" ement-list-rooms "rooms"))
     "Presence"
     (("d" elcord-mode "discord presence" :toggle t)))))

;; --- Cheatsheet -----------------------------------------------------------
;; M-x flutter-cheatsheet (also on the dashboard navigator): the daily
;; keys in one buffer.  Pure command — safe to load anywhere.
(defun flutter-cheatsheet ()
  "Open the Flutter Emacs key cheatsheet."
  (interactive)
  (with-current-buffer (get-buffer-create "*flutter-cheatsheet*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert "Flutter Emacs cheatsheet\n"
              "========================\n\n"
              "Terminal\n"
              "  C-c t    ghostel (terminal here)\n"
              "  C-`      popterm toggle (project scope)\n"
              "  F9       popterm window toggle\n"
              "  project m / M  ghostel here / elsewhere\n\n"
              "Hydras\n"
              "  F6       toggles hydra (theme, completion style, ...)\n"
              "  C-c m    media hydra (empv, elfeed, ement, elcord)\n"
              "  C-c w    windows hydra (splits, orientation)\n"
              "  C-c e    EWM hydra (compositor only)\n\n"
              "EWM compositor (Super keys, compositor only)\n"
              "  s-d / s-<return>  launcher / terminal\n"
              "  s-q / s-S-q       close buffer / frame\n"
              "  s-f / s-TAB       fullscreen / cycle apps\n"
              "  s-1..9            jump to frame (workspace)\n\n"
              "Search / jump\n"
              "  M-g g    go to line (consult)\n"
              "  M-g i    imenu (consult)\n"
              "  M-g m/k  mark / global mark (consult)\n"
              "  C-c r    ripgrep project (consult)\n"
              "  C-x C-r  recent files (recentf)\n\n"
              "Full list: modules/emacs/emacs/README.md § Cheatsheet.\n"))
    (special-mode)
    (pop-to-buffer "*flutter-cheatsheet*")))

(provide 'init-extras)

;;; init-extras.el ends here

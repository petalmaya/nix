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

;; --- Completion style: minibuffer, not childframe -----------------------
;; Centaur defaults `flutter-completion-style' to 'childframe: the
;; *-posframe packages (vertico-posframe, which-key-posframe,
;; transient-posframe, hydra-posframe) render the M-x prompt and popup
;; hints in floating childframes.  The vertico part only arms itself on
;; server-created frames (emacsclient), so a plain `emacs' session
;; looks normal — but the first client frame flips it on GLOBALLY and
;; every frame afterwards gets the floating prompt (the "M-x in the
;; middle of the screen" effect).  This fork prefers the classic
;; bottom-minibuffer look, so disable childframe completion entirely;
;; the defcustom gates all of the *-posframe packages.
(setq flutter-completion-style 'minibuffer)

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

;; --- Ghostel in the project menu -----------------------------------------
;; Centaur's init-shell.el brings ghostel (in-Emacs terminal via
;; Ghostty's VT engine); make it available from project.el's switch
;; menu like a first-class citizen.
(with-eval-after-load 'project
  (add-to-list 'project-switch-commands '(ghostel-project "Ghostel") t))

;; --- Media hydra ----------------------------------------------------------
;; The config's idiom is hydras (see init-hydra.el); give the media
;; extras the same treatment so they feel native.
(use-package pretty-hydra
  :ensure nil
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

(provide 'init-extras)

;;; init-extras.el ends here

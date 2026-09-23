;;; init-extras.el --- QML + media extras -*- lexical-binding: t -*-

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
;; Optional QML, Nix, and media integrations not provided by Centaur.
;; Their external tools are supplied by modules/emacs/default.nix.
;;
;;; Code:

;; Completion style remains customizable through `flutter-completion-style'.

;; nil comes from the flake; nix-mode derives from prog-mode, which starts eglot.
(use-package nix-mode
  :mode "\\.nix\\'")

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(nix-mode . ("nil"))))

;; QML's grammar is not on MELPA; install it from its source on first use.
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(qmljs "https://github.com/yuja/tree-sitter-qmljs")))

;; qml-ts-mode is not on MELPA; use its GitHub source directly.
(use-package qml-ts-mode
  :ensure (:host github :repo "xhcoding/qml-ts-mode")
  :mode ("\\.qml\\'" . qml-ts-mode)
  :hook (qml-ts-mode . (lambda ()
                         (setq-local electric-indent-chars
                                     '(?\n ?\( ?\) ?{ ?} ?\[ ?\] ?\; ?\,))
                         (eglot-ensure))))

;; qmlls comes from Qt6's declarative tools in modules/emacs/default.nix.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(qml-ts-mode . ("qmlls"))))

;; empv needs the `mpv' binary on PATH.
(use-package empv
  :commands (empv-play-or-enqueue empv-youtube empv-play-radio
             empv-toggle empv-playlist-next empv-playlist-prev)
  :custom
  (empv-audio-dir "~/Music")
  (empv-video-dir "~/Videos")
  (empv-invidious-instance "https://invidious.nerdvpn.de/api/v1"))

;; ement-connect prompts for the Matrix account details.
(use-package ement
  :commands (ement-connect ement-list-rooms))

;; elcord-mode is per-session; enable it from the media hydra when needed.
(use-package elcord
  :commands elcord-mode
  :custom
  (elcord-display-buffer-details t)
  (elcord-use-major-mode-as-main-icon t))

;; The media hydra follows the same lazy pretty-hydra pattern as init-hydra.el.
(use-package pretty-hydra
  :ensure nil
  :if (or (featurep 'pretty-hydra) (locate-library "pretty-hydra"))
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

;; M-x flutter-cheatsheet opens the key summary.
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
              "  s-c / s-v / s-a   copy / paste / select all\n"
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

;;; my-media.el --- media playback, epub, feeds, chat, presence -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; Everything that isn't "editing code" but you still want inside
;; Emacs: local/streaming media control, an epub reader, an RSS
;; reader, a Matrix client, and a Discord presence blip so people
;; know you're doing something in here.
;;
;;   empv    mpv frontend — local files, YouTube, radio streams
;;   nov     minor/major mode for reading .epub files
;;   elfeed  RSS/Atom/JSON feed reader
;;   ement   Matrix client (successor to the unmaintained
;;           matrix-client.el; pulled from GNU ELPA)
;;   elcord  Discord Rich Presence — broadcasts current buffer/mode
;;
;;; Code:

;; --- empv: mpv-based media player --------------------------------------
;; Requires the `mpv' binary on PATH (bring it in via the Nix flake
;; devShell, same as the LSP servers in my-dev.el).
(use-package empv
  :custom
  (empv-audio-dir "~/Music")
  (empv-video-dir "~/Videos")
  (empv-invidious-instance "https://invidious.nerdvpn.de/api/v1"))

;; --- nov: epub reader ---------------------------------------------------
(use-package nov
  :mode ("\\.epub\\'" . nov-mode)
  :custom
  (nov-text-width 80)
  (nov-variable-pitch t))

;; --- elfeed: RSS/Atom reader ---------------------------------------------
(use-package elfeed
  :custom
  (elfeed-db-directory (expand-file-name "elfeed" user-emacs-directory))
  (elfeed-search-filter "@2-week-ago +unread"))

(use-package elfeed-org
  :after elfeed
  :custom
  (rmh-elfeed-org-files (list (expand-file-name "elfeed.org" user-emacs-directory)))
  :config
  (elfeed-org))

;; --- ement: Matrix client -------------------------------------------------
;; GNU ELPA, not MELPA — nothing extra to enable, `package-archives'
;; already has gnu on by default. `ement-connect' prompts for
;; homeserver/user/password (or token); repeat with C-u for a second
;; account.
(use-package ement)

;; --- elcord: Discord Rich Presence ----------------------------------------
;; Talks to a locally running Discord client over IPC. Off by default
;; since it's the kind of thing you turn on per-session, not always —
;; flip it with `elcord-mode' or the leader binding below.
(use-package elcord
  :commands elcord-mode
  :custom
  (elcord-display-buffer-details t)
  (elcord-use-major-mode-as-main-icon t))

(provide 'my-media)
;;; my-media.el ends here

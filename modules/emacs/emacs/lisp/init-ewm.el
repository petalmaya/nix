;;; init-ewm.el --- EWM (Emacs Wayland Manager) overlay -*- lexical-binding: t -*-

;; Copyright (C) 2026 Alice (Flutter Emacs)

;; This file is part of Flutter Emacs, a fork of Centaur Emacs
;; (GPL-3.0, copyright Vincent Zhang — see vendor/centaur/NOTICE.md).
;;
;; EWM itself (https://codeberg.org/ezemtsov/ewm, GPL-3.0) runs the
;; Wayland compositor as an Emacs dynamic module: Wayland apps appear as
;; Emacs buffers, managed with the same keys as everything else.
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
;; Optional "live in Emacs" layer. Enabled per-user via nixtop.ewm.enable
;; (Nix: modules/ewm/ plus the `ewm` login session). Inert without ewm.el
;; on the load-path, so init.el loads it unconditionally.
;;
;; Upstream wiki in elisp form: consult launcher with XDG apps, C-c
;; intercept prefixes, s-c/v/a client translation, ctrl:nocaps xkb,
;; cursor/alpha/animation defaults, PiP + dialog window rules. Shell $PWD
;; tracking is wired in Nix (modules/ewm/home.nix).
;;
;; Entry points: M-x ewm-start-module, s-d launcher, s-<return> ghostel,
;; C-c e hydra (frames, float, fullscreen, lock, outputs).
;;
;;; Code:

;; From Nix (withPackages), never Elpaca — hence :ensure nil. :demand t
;; loads the elisp at startup; the compositor itself starts on demand.
(use-package ewm
  :ensure nil
  :demand t
  :if (locate-library "ewm")
  :custom
  ;; Same xkb as the OS (NixOS + sway + mango); EWM keeps its own
  ;; per-seat state, so the setting is repeated here.
  (ewm-input-config '((keyboard :repeat-delay 200 :repeat-rate 45
                               :xkb-layouts "us"
                               :xkb-options "ctrl:nocaps")
                      (touchpad :natural-scroll t :tap t :dwt t)
                      (mouse :accel-profile "flat")))
  ;; Auto by default. M-x ewm-list-outputs shows the names to pin here.
  (ewm-output-config nil)
  ;; --- Appearance wiki --------------------------------------------------
  (ewm-cursor-theme "capitaine-cursors")
  (ewm-cursor-size 24)
  (ewm-unfocused-alpha 1.0)
  (ewm-animations-enabled t)
  ;; Off; blanking and locking stay with swayidle + swaylock.
  (ewm-idle nil)
  :bind (:map ewm-mode-map
         ;; One launcher for buffers, files and desktop apps.
         ("s-d" . consult-buffer)
         ;; The in-Emacs terminal, not an external app.
         ("s-<return>" . ghostel))
  :init
  ;; Extra C-c prefix lets our hydras (media, windows, ghostel) work with
  ;; a surface focused. Client copy/paste still works via s-c/s-v below.
  (setq ewm-intercept-prefixes
        '("C-x" "C-u" "C-h" "M-x" "C-c"
          ("s-f" :fullscreen)
          ("<MonBrightnessUp>" :fullscreen)
          ("<MonBrightnessDown>" :fullscreen)
          ("<AudioRaiseVolume>" :fullscreen)
          ("<AudioLowerVolume>" :fullscreen)
          ("<AudioMute>" :fullscreen)
          ("<AudioMicMute>" :fullscreen)
          ("<Print>" :fullscreen)))
  ;; Familiar copy/paste/select-all inside clients.
  (setq ewm-surface-emulate-keys
        '((?\s-c . "ctrl")
          (?\s-v . "ctrl")
          (?\s-a . "ctrl")))
  :config
  ;; Desktop apps inside consult-buffer (narrow with `a SPC').
  (with-eval-after-load 'consult
    (defvar consult-source-xdg-apps
      `(:name "Apps"
        :narrow ?a
        :category app
        :items ,(lambda () (mapcar #'car (ewm-list-xdg-apps)))
        :action ,#'ewm-launch-xdg-command)
      "XDG desktop applications for `consult-buffer'. Narrow with `a SPC'.")
    (add-to-list 'consult-buffer-sources 'consult-source-xdg-apps t))

  ;; First match wins; add-to-list prepends, so general rules go first.
  (with-eval-after-load 'ewm
    ;; Firefox Picture-in-Picture floats.
    (add-to-list 'display-buffer-alist
                 `(,(ewm-surface-match :app "firefox" :title "^Picture-in-Picture$")
                   ewm-display-buffer-floating))
    ;; Keep dialogs tiled when they should behave like Emacs windows.
    (add-to-list 'display-buffer-alist
                 `(,(ewm-surface-match :app "zenity") display-buffer-same-window))))

;; Frame/float/session controls on C-c e, in this config's hydra idiom.
(use-package pretty-hydra
  :ensure nil
  :if (locate-library "ewm")
  :after ewm
  :bind ("C-c e" . flutter-ewm-hydra/body)
  :config
  (pretty-hydra-define flutter-ewm-hydra
    (:title (pretty-hydra-title "EWM" 'faicon "nf-fa-linux")
     :color amaranth :quit-key ("q" "C-g"))
    ("Frame"
     (("t" ewm-frame-new "new")
      ("w" ewm-frame-close "close")
      ("<left>" ewm-frame-left "prev")
      ("<right>" ewm-frame-right "next")
      ("1" ewm-frame-select "jump 1-9"))
     "Window"
     (("f" ewm-toggle-fullscreen "fullscreen")
      ("SPC" ewm-floating-toggle "float")
      ("TAB" ewm-next-surface-buffer "next surface"))
     "Session"
     (("d" consult-buffer "launch/app")
      ("l" ewm-lock-session "lock")
      ("o" ewm-list-outputs "outputs")))))

(provide 'init-ewm)

;;; init-ewm.el ends here

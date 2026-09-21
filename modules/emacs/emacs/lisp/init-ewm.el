;;; init-ewm.el --- EWM Wayland compositor config -*- lexical-binding: t -*-

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
;; Compositor-only config for the `ewm' login session (Nix:
;; modules/ewm/).  Everything side-effecting runs inside
;; `flutter-ewm--setup', after `ewm' loads — so a nested `emacs' stays a
;; plain editor: no EWM keys, no wallpaper handling, no app sources.
;;
;; Daily keys (compositor only): s-d launcher, s-<return> terminal, s-f
;; fullscreen, s-S-SPC float, s-TAB/s-S-TAB cycle surfaces, s-t/s-n new
;; frame, s-q close buffer, s-S-q close frame, s-w jump windows, s-l
;; lock, s-c/s-v copy/paste, s-arrows focus (crosses outputs), s-S-arrows
;; and s-1..9 move along the frame strip, C-s-arrows reorder frames,
;; media keys, C-c e compositor hydra.
;; F2 opens the dashboard.

;;; Code:

(declare-function ewm-list-xdg-apps "ewm")
(declare-function ewm-launch-app "ewm")
(declare-function ewm-launch-xdg-command "ewm")
(declare-function ewm-lock-session "ewm")
(declare-function ewm-toggle-fullscreen "ewm")
(declare-function ewm-next-surface-buffer "ewm")
(declare-function ewm-prev-surface-buffer "ewm")
(declare-function ewm-floating-toggle "ewm")
(declare-function ewm-focus-left "ewm")
(declare-function ewm-focus-right "ewm")
(declare-function ewm-focus-up "ewm")
(declare-function ewm-focus-down "ewm")
(declare-function ewm-frame-new "ewm")
(declare-function ewm-frame-close "ewm")
(declare-function ewm-frame-left "ewm")
(declare-function ewm-frame-right "ewm")
(declare-function ewm-frame-select "ewm")
(declare-function ewm-frame-move-left "ewm")
(declare-function ewm-frame-move-right "ewm")
(declare-function ewm-list-outputs "ewm")
(declare-function ewm-surface-match "ewm")
(declare-function open-dashboard "init-dashboard")

(defgroup flutter-ewm nil
  "EWM compositor session."
  :group 'flutter)

(defcustom flutter-ewm-wallpaper
  (expand-file-name "Pictures/Wallpapers/gothic_anime_girl_red_armchair.png"
                    (getenv "HOME"))
  "Image shown behind Emacs frames via swaybg."
  :type 'file
  :group 'flutter-ewm)

(defcustom flutter-ewm-wallpaper-directory
  (expand-file-name "Pictures/Wallpapers" (getenv "HOME"))
  "Directory offered by `flutter-ewm-set-wallpaper'.
Symlinked to the repo's assets/wallpaper (see modules/user/*/home.nix)."
  :type 'directory
  :group 'flutter-ewm)

(defun flutter-ewm--wallpaper-files ()
  "Image files in `flutter-ewm-wallpaper-directory'."
  (when (file-directory-p flutter-ewm-wallpaper-directory)
    (directory-files flutter-ewm-wallpaper-directory t
                     "\\.\\(png\\|jpe?g\\|webp\\|bmp\\)\\'")))

(defun flutter-ewm--start-wallpaper (image)
  "Show IMAGE behind frames with swaybg, replacing any old instance."
  (when (executable-find "swaybg")
    (ignore-errors (call-process "pkill" nil nil nil "-x" "swaybg"))
    (start-process "ewm-swaybg" nil "swaybg" "-i" image "-m" "fill")))

;;;###autoload
(defun flutter-ewm-set-wallpaper (image)
  "Pick a background from `flutter-ewm-wallpaper-directory' and apply it.
Restarts swaybg and saves the choice for future sessions."
  (interactive
   (list (completing-read "Wallpaper: " (flutter-ewm--wallpaper-files)
                          nil t nil nil flutter-ewm-wallpaper)))
  (setq flutter-ewm-wallpaper image)
  (if (file-exists-p image)
      (progn
        (flutter-ewm--start-wallpaper image)
        (customize-save-variable 'flutter-ewm-wallpaper image)
        (message "Wallpaper: %s" (file-name-nondirectory image)))
    (user-error "Wallpaper not found: %s" image)))

(defun flutter-ewm--xdg-app-names ()
  "Names of installed XDG applications, for `consult-buffer'."
  (mapcar #'car (ewm-list-xdg-apps)))

;; XDG desktop apps inside consult-buffer (narrow with `a SPC').
;; Inert data until `flutter-ewm--setup' adds it to the sources.
(defvar consult-source-xdg-apps
  '(:name "Apps"
    :narrow ?a
    :category app
    :items flutter-ewm--xdg-app-names
    :action ewm-launch-xdg-command)
  "XDG desktop applications for `consult-buffer'. Narrow with `a SPC'.")

(defvar flutter-ewm--dashboard-shown nil
  "Non-nil once the compositor has shown the dashboard on its first frame.")

;; Media keys run repo-standard CLI tools (this repo uses pamixer, like
;; sway; upstream uses wpctl). Bound in `ewm-mode-map' below, which the
;; compositor intercepts automatically.
(defun flutter-ewm--run-audio (args)
  "Run pamixer with ARGS, warning when it is missing."
  (if (executable-find "pamixer")
      (apply #'start-process "ewm-audio" nil "pamixer" args)
    (message "pamixer not found (add it to the EWM host packages)")))

(defun flutter-ewm-volume-up ()
  "Raise the volume 5%."
  (interactive)
  (flutter-ewm--run-audio '("-i" "5")))

(defun flutter-ewm-volume-down ()
  "Lower the volume 5%."
  (interactive)
  (flutter-ewm--run-audio '("-d" "5")))

(defun flutter-ewm-volume-mute ()
  "Toggle audio mute."
  (interactive)
  (flutter-ewm--run-audio '("-t")))

(defun flutter-ewm-mic-mute ()
  "Toggle microphone mute."
  (interactive)
  (flutter-ewm--run-audio '("--default-source" "-t")))

(defun flutter-ewm-brightness-up ()
  "Raise screen brightness 5%."
  (interactive)
  (start-process "ewm-bright" nil "brightnessctl" "set" "5%+"))

(defun flutter-ewm-brightness-down ()
  "Lower screen brightness 5%."
  (interactive)
  (start-process "ewm-bright" nil "brightnessctl" "set" "5%-"))

(defun flutter-ewm--trigger-server-hooks (frame)
  "Run `server-after-make-frame-hook' on the first compositor GUI FRAME.
EWM frames come from `make-frame', which never fires that hook, so
daemon-deferred setup (fonts, which-key, ...) would otherwise be
skipped (upstream Doom-Emacs wiki pattern)."
  (when (and (frame-live-p frame) (display-graphic-p frame))
    (remove-hook 'after-make-frame-functions #'flutter-ewm--trigger-server-hooks)
    (with-selected-frame frame
      (run-hooks 'server-after-make-frame-hook))))

(defun flutter-ewm--maybe-show-dashboard (frame)
  "Show the dashboard on the compositor's first GUI FRAME.
One-shot: later frames (e.g. emacsclient) are left alone."
  (when (and (not flutter-ewm--dashboard-shown)
             (frame-live-p frame)
             (display-graphic-p frame))
    (setq flutter-ewm--dashboard-shown t)
    (remove-hook 'after-make-frame-functions #'flutter-ewm--maybe-show-dashboard)
    (with-selected-frame frame
      (when (and (string= (buffer-name) "*scratch*")
                 (fboundp 'open-dashboard))
        (open-dashboard)))))

(defun flutter-ewm--setup ()
  "Configure EWM once the compositor module loads."
  ;; Keyboard/mouse. Same xkb as the OS (NixOS + sway + mango); EWM
  ;; keeps its own per-seat state, so the layout repeats here.
  (setq ewm-input-config '((keyboard :repeat-delay 200 :repeat-rate 45
                                     :xkb-layouts "us"
                                     :xkb-options "ctrl:nocaps")
                           (touchpad :natural-scroll t :tap t :dwt t)
                           (mouse :accel-profile "flat")))
  ;; Outputs. Mirrors mango (modules/mango/settings.conf): external
  ;; HDMI-A-1 left at (0,0), internal eDP-1 right of it.
  ;; M-x ewm-list-outputs shows live names when connectors differ.
  (setq ewm-output-config '(("HDMI-A-1" :width 1680 :height 1050 :x 0 :y 0)
                            ("eDP-1" :x 1680 :y 0)))
  ;; Look. Cursor matches the session env (modules/ewm/default.nix);
  ;; blanking and locking stay with swayidle + swaylock.
  (setq ewm-cursor-theme "capitaine-cursors"
        ewm-cursor-size 24
        ewm-unfocused-alpha 1.0
        ewm-animations-enabled t
        ewm-idle nil)

  ;; Pointer follows focus across surfaces (upstream default is off).
  (setq ewm-focus-follows-mouse t)

  ;; Daily compositor keys (upstream defaults, plus s-n/s-q/s-w/s-<return>
  ;; daily-driver extras). Plain Emacs/nested sessions never see these.
  (define-key ewm-mode-map (kbd "s-d") #'consult-buffer)
  (define-key ewm-mode-map (kbd "s-<return>") #'ghostel)
  (define-key ewm-mode-map (kbd "s-f") #'ewm-toggle-fullscreen)
  (define-key ewm-mode-map (kbd "s-S-SPC") #'ewm-floating-toggle)
  (define-key ewm-mode-map (kbd "s-TAB") #'ewm-next-surface-buffer)
  (define-key ewm-mode-map (kbd "s-S-TAB") #'ewm-prev-surface-buffer)
  (define-key ewm-mode-map (kbd "s-<iso-lefttab>") #'ewm-prev-surface-buffer)
  (define-key ewm-mode-map (kbd "s-t") #'ewm-frame-new)
  (define-key ewm-mode-map (kbd "s-n") #'ewm-frame-new)
  (define-key ewm-mode-map (kbd "s-q") #'kill-current-buffer)
  (define-key ewm-mode-map (kbd "s-S-q") #'ewm-frame-close)
  (define-key ewm-mode-map (kbd "s-w") #'ace-window)
  (define-key ewm-mode-map (kbd "s-l") #'ewm-lock-session)
  (define-key ewm-mode-map (kbd "s-c") #'kill-ring-save)
  (define-key ewm-mode-map (kbd "s-v") #'yank)
  ;; Window focus that crosses outputs at the frame edge (shadows the
  ;; global windmove s-arrows inside the compositor only).
  (define-key ewm-mode-map (kbd "s-<left>") #'ewm-focus-left)
  (define-key ewm-mode-map (kbd "s-<right>") #'ewm-focus-right)
  (define-key ewm-mode-map (kbd "s-<up>") #'ewm-focus-up)
  (define-key ewm-mode-map (kbd "s-<down>") #'ewm-focus-down)
  ;; Frame-strip navigation: slide along this output, or jump to Nth frame.
  (define-key ewm-mode-map (kbd "s-S-<left>") #'ewm-frame-left)
  (define-key ewm-mode-map (kbd "s-S-<right>") #'ewm-frame-right)
  (define-key ewm-mode-map (kbd "C-s-<left>") #'ewm-frame-move-left)
  (define-key ewm-mode-map (kbd "C-s-<right>") #'ewm-frame-move-right)
  (dotimes (i 9)
    (let ((n (1+ i)))
      (define-key ewm-mode-map (kbd (format "s-%d" n))
        (lambda () (interactive) (ewm-frame-select n)))))
  ;; Media keys (intercepted above, so they work with a surface focused).
  ;; Print stays intercepted but unbound — pick a screenshot tool later.
  (define-key ewm-mode-map (kbd "<AudioRaiseVolume>") #'flutter-ewm-volume-up)
  (define-key ewm-mode-map (kbd "<AudioLowerVolume>") #'flutter-ewm-volume-down)
  (define-key ewm-mode-map (kbd "<AudioMute>") #'flutter-ewm-volume-mute)
  (define-key ewm-mode-map (kbd "<AudioMicMute>") #'flutter-ewm-mic-mute)
  (define-key ewm-mode-map (kbd "<MonBrightnessUp>") #'flutter-ewm-brightness-up)
  (define-key ewm-mode-map (kbd "<MonBrightnessDown>") #'flutter-ewm-brightness-down)

  ;; Extra C-c prefix so hydras (media, windows, ghostel) work with a
  ;; surface focused. Client copy/paste still works via s-c/s-v below.
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

  ;; Desktop apps inside consult-buffer.
  (with-eval-after-load 'consult
    (add-to-list 'consult-buffer-sources 'consult-source-xdg-apps t))

  ;; Firefox Picture-in-Picture floats; zenity-style dialogs stay tiled.
  (add-to-list 'display-buffer-alist
               `(,(ewm-surface-match :app "firefox" :title "^Picture-in-Picture$")
                 ewm-display-buffer-floating))
  (add-to-list 'display-buffer-alist
               `(,(ewm-surface-match :app "zenity") display-buffer-same-window))

  ;; Wallpaper behind the frames.
  (if (file-exists-p flutter-ewm-wallpaper)
      (flutter-ewm--start-wallpaper flutter-ewm-wallpaper)
    (display-warning 'init-ewm (format "Wallpaper not found: %s"
                                       flutter-ewm-wallpaper)))

  ;; Compositor hydra (this config's hydra idiom). Bound here so nested
  ;; `emacs' never sees it.
  (when (require 'pretty-hydra nil t)
    (pretty-hydra-define flutter-ewm-hydra
      (:title (pretty-hydra-title "EWM" 'faicon "nf-fa-linux")
       :color amaranth :quit-key ("q" "C-g"))
      ("Launch"
       (("d" consult-buffer "buffer/app")
        ("t" ghostel "terminal")
        ("a" ewm-launch-app "launch app"))
       "Frame"
       (("n" ewm-frame-new "new")
        ("c" ewm-frame-close "close")
        ("<left>" ewm-frame-left "prev")
        ("<right>" ewm-frame-right "next")
        ("1" ewm-frame-select "jump 1-9"))
       "Window"
       (("f" ewm-toggle-fullscreen "fullscreen")
        ("SPC" ewm-floating-toggle "float")
        ("TAB" ewm-next-surface-buffer "next surface"))
       "Session"
       (("w" flutter-ewm-set-wallpaper "wallpaper" :exit t)
        ("l" ewm-lock-session "lock" :exit t)
        ("o" ewm-list-outputs "outputs" :exit t))))
    (global-set-key (kbd "C-c e") #'flutter-ewm-hydra/body))

  ;; Daemon-deferred setup first, then the dashboard — both one-shot on
  ;; the first GUI frame (later frames, e.g. emacsclient, are untouched).
  (add-hook 'after-make-frame-functions #'flutter-ewm--trigger-server-hooks)
  (add-hook 'after-make-frame-functions #'flutter-ewm--maybe-show-dashboard))

(with-eval-after-load 'ewm
  (flutter-ewm--setup))

(provide 'init-ewm)

;;; init-ewm.el ends here

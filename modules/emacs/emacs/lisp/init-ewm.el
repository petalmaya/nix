;;; init-ewm.el --- EWM Wayland compositor config -*- lexical-binding: t -*-

;; Copyright (C) 2026 Alice (Pinaceae Emacs)

;; This file is part of Pinaceae Emacs, a fork of Centaur Emacs
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
;; EWM is configured only after `ewm' loads, keeping nested Emacs sessions plain.
;; Screen locking uses EWM's idle protocol with foreground swaylock.

;;; Code:

(require 'subr-x)

(declare-function ewm-start-module "ewm")
(declare-function ewm-list-xdg-apps "ewm")
(declare-function ewm-launch-app "ewm")
(declare-function ewm-launch-xdg-command "ewm")
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

(defgroup pinaceae-ewm nil
  "EWM compositor session."
  :group 'pinaceae)

(defcustom pinaceae-ewm-wallpaper
  (expand-file-name "Pictures/Wallpapers/gothic_anime_girl_red_armchair.png"
                    (getenv "HOME"))
  "Image shown behind Emacs frames via swaybg."
  :type 'file
  :group 'pinaceae-ewm)

(defcustom pinaceae-ewm-wallpaper-directory
  (expand-file-name "Pictures/Wallpapers" (getenv "HOME"))
  "Directory offered by `pinaceae-ewm-set-wallpaper'.
Synced manually to ~/Pictures/Wallpapers; not tracked in this repo."
  :type 'directory
  :group 'pinaceae-ewm)

(defun pinaceae-ewm--wallpaper-files ()
  "Image files in `pinaceae-ewm-wallpaper-directory'."
  (when (file-directory-p pinaceae-ewm-wallpaper-directory)
    (directory-files pinaceae-ewm-wallpaper-directory t
                     "\\.\\(png\\|jpe?g\\|webp\\|bmp\\)\\'")))

(defvar pinaceae-ewm--wallpaper-process nil
  "swaybg process started by this EWM session.")

(defun pinaceae-ewm--wallpaper-sentinel (process event)
  "Clear the wallpaper process and report abnormal exits."
  (when (eq process pinaceae-ewm--wallpaper-process)
    (setq pinaceae-ewm--wallpaper-process nil)
    (when (string-match-p "abnormal" event)
      (message "swaybg failed (%s); see *ewm-swaybg*" (string-trim event)))))

(defun pinaceae-ewm--start-wallpaper (image)
  "Show IMAGE behind frames with swaybg, replacing this session's instance."
  (let ((file (expand-file-name image)))
    (cond ((not (getenv "WAYLAND_DISPLAY"))
           (user-error "WAYLAND_DISPLAY unset; swaybg needs the running compositor"))
          ((not (file-readable-p file))
           (user-error "Wallpaper not found: %s" file))
          ((null (executable-find "swaybg"))
           (user-error "swaybg not found in PATH"))
          (t
           (when (process-live-p pinaceae-ewm--wallpaper-process)
             (kill-process pinaceae-ewm--wallpaper-process))
           (setq pinaceae-ewm--wallpaper-process
                 (start-process "ewm-swaybg" (get-buffer-create "*ewm-swaybg*")
                                "swaybg" "-i" file "-m" "fill"))
           (set-process-sentinel pinaceae-ewm--wallpaper-process
                                 #'pinaceae-ewm--wallpaper-sentinel)
           pinaceae-ewm--wallpaper-process))))

(defun pinaceae-ewm--maybe-start-wallpaper (&rest _)
  "Start swaybg after the compositor creates its Wayland socket."
  (condition-case err
      (pinaceae-ewm--start-wallpaper pinaceae-ewm-wallpaper)
    (error (display-warning 'init-ewm (error-message-string err)))))

(defvar pinaceae-ewm--notif-process nil
  "mako process started by this EWM session.")

(defun pinaceae-ewm--notif-sentinel (process event)
  "Clear the notification process and report abnormal exits."
  (when (eq process pinaceae-ewm--notif-process)
    (setq pinaceae-ewm--notif-process nil)
    (when (string-match-p "abnormal" event)
      (message "mako failed (%s); see *ewm-mako*" (string-trim event)))))

(defun pinaceae-ewm--maybe-start-notifications (&rest _)
  "Start mako after the compositor creates its Wayland socket."
  (when (and (getenv "WAYLAND_DISPLAY") (executable-find "mako"))
    (unless (process-live-p pinaceae-ewm--notif-process)
      (setq pinaceae-ewm--notif-process
            (start-process "ewm-mako" (get-buffer-create "*ewm-mako*") "mako"))
      (set-process-sentinel pinaceae-ewm--notif-process
                            #'pinaceae-ewm--notif-sentinel))))

(defconst pinaceae-ewm-lock-command "swaylock -f"
  "Command used for manual and idle EWM screen locking.")

(defcustom pinaceae-ewm-output-config
  '(("HDMI-A-1" :width 1680 :height 1050 :x 0 :y 0)
    ("eDP-1" :x 1680 :y 0))
  "Output layout; check names with `M-x ewm-list-outputs'."
  :type 'sexp
  :group 'pinaceae-ewm)

(defcustom pinaceae-ewm-input-config
  '((keyboard :repeat-delay 200 :repeat-rate 45
              :xkb-layouts "us"
              :xkb-options "ctrl:nocaps")
    (touchpad :natural-scroll t :tap t :dwt t)
    (mouse :accel-profile "flat"))
  "Per-seat input config; Wayland shares one keymap across keyboards."
  :type 'sexp
  :group 'pinaceae-ewm)

(defcustom pinaceae-ewm-idle-timeout 300
  "Seconds of idleness before locking; nil disables idle locking."
  :type '(choice (const :tag "Disabled" nil) integer)
  :group 'pinaceae-ewm)

(defvar pinaceae-ewm--lock-process nil
  "Foreground swaylock process started by `pinaceae-ewm-lock-session'.")

(defun pinaceae-ewm--lock-sentinel (process event)
  "Clear the lock process and report abnormal exits."
  (when (eq process pinaceae-ewm--lock-process)
    (setq pinaceae-ewm--lock-process nil)
    (when (string-match-p "abnormal" event)
      (message "swaylock failed (%s); see *ewm-swaylock*" (string-trim event)))))

(defun pinaceae-ewm-lock-session ()
  "Lock the EWM session with foreground swaylock."
  (interactive)
  (cond ((process-live-p pinaceae-ewm--lock-process)
         (message "Screen is already locked"))
        ((null (executable-find "swaylock"))
         (user-error "swaylock not found in PATH"))
        (t
         (setq pinaceae-ewm--lock-process
               (start-process "ewm-swaylock" (get-buffer-create "*ewm-swaylock*")
                              "swaylock" "-f"))
         (set-process-sentinel pinaceae-ewm--lock-process
                               #'pinaceae-ewm--lock-sentinel)
         pinaceae-ewm--lock-process)))

(defun pinaceae-ewm--stop-process (process)
  "Stop PROCESS when it is still running."
  (when (and process (process-live-p process))
    (kill-process process)))

(defun pinaceae-ewm--cleanup-children ()
  "Stop helper processes started by this EWM session."
  ;; Leave swaylock running; killing it would unlock the screen on exit.
  (dolist (process (list pinaceae-ewm--wallpaper-process
                         pinaceae-ewm--notif-process))
    (pinaceae-ewm--stop-process process))
  (setq pinaceae-ewm--wallpaper-process nil
        pinaceae-ewm--notif-process nil))

;;;###autoload
(defun pinaceae-ewm-set-wallpaper (image)
  "Pick a background from `pinaceae-ewm-wallpaper-directory' and apply it.
Restarts swaybg and saves the choice for future sessions."
  (interactive
   (list (completing-read "Wallpaper: " (pinaceae-ewm--wallpaper-files)
                          nil t nil nil pinaceae-ewm-wallpaper)))
  (when (pinaceae-ewm--start-wallpaper image)
    (setq pinaceae-ewm-wallpaper image)
    (customize-save-variable 'pinaceae-ewm-wallpaper image)
    (message "Wallpaper: %s" (file-name-nondirectory image))))

(defun pinaceae-ewm--xdg-app-names ()
  "Names of installed XDG applications, for `consult-buffer'."
  (mapcar #'car (ewm-list-xdg-apps)))

;; Keep XDG app data inert until EWM setup adds it to consult-buffer.
(defvar consult-source-xdg-apps
  '(:name "Apps"
    :narrow ?a
    :category app
    :items pinaceae-ewm--xdg-app-names
    :action ewm-launch-xdg-command)
  "XDG desktop applications for `consult-buffer'. Narrow with `a SPC'.")

(defvar pinaceae-ewm--dashboard-shown nil
  "Non-nil once the compositor has shown the dashboard on its first frame.")

;; Use the repository's pamixer and brightnessctl tools for media keys.
(defun pinaceae-ewm--run-audio (args)
  "Run pamixer with ARGS, warning when it is missing."
  (if (executable-find "pamixer")
      (apply #'start-process "ewm-audio" nil "pamixer" args)
    (message "pamixer not found (add it to the EWM host packages)")))

(defun pinaceae-ewm-volume-up ()
  "Raise the volume 5%."
  (interactive)
  (pinaceae-ewm--run-audio '("-i" "5")))

(defun pinaceae-ewm-volume-down ()
  "Lower the volume 5%."
  (interactive)
  (pinaceae-ewm--run-audio '("-d" "5")))

(defun pinaceae-ewm-volume-mute ()
  "Toggle audio mute."
  (interactive)
  (pinaceae-ewm--run-audio '("-t")))

(defun pinaceae-ewm-mic-mute ()
  "Toggle microphone mute."
  (interactive)
  (pinaceae-ewm--run-audio '("--default-source" "-t")))

(defun pinaceae-ewm-brightness-up ()
  "Raise screen brightness 5%."
  (interactive)
  (start-process "ewm-bright" nil "brightnessctl" "set" "5%+"))

(defun pinaceae-ewm-brightness-down ()
  "Lower screen brightness 5%."
  (interactive)
  (start-process "ewm-bright" nil "brightnessctl" "set" "5%-"))

(defun pinaceae-ewm--trigger-server-hooks (frame)
  "Run `server-after-make-frame-hook' on the first compositor GUI FRAME.
EWM frames come from `make-frame', which never fires that hook, so
daemon-deferred setup (fonts, which-key, ...) would otherwise be
skipped (upstream Doom-Emacs wiki pattern)."
  (when (and (frame-live-p frame) (display-graphic-p frame))
    (remove-hook 'after-make-frame-functions #'pinaceae-ewm--trigger-server-hooks)
    (with-selected-frame frame
      (run-hooks 'server-after-make-frame-hook))))

(defun pinaceae-ewm--maybe-show-dashboard (frame)
  "Show the dashboard on the compositor's first GUI FRAME.
One-shot: later frames (e.g. emacsclient) are left alone."
  (when (and (not pinaceae-ewm--dashboard-shown)
             (frame-live-p frame)
             (display-graphic-p frame))
    (setq pinaceae-ewm--dashboard-shown t)
    (remove-hook 'after-make-frame-functions #'pinaceae-ewm--maybe-show-dashboard)
    (with-selected-frame frame
      (when (and (string= (buffer-name) "*scratch*")
                 (fboundp 'open-dashboard))
        (open-dashboard)))))

(defun pinaceae-ewm--setup ()
  "Configure EWM once the compositor module loads."
  (setq ewm-input-config pinaceae-ewm-input-config)
  (setq ewm-output-config pinaceae-ewm-output-config)
  ;; Cursor settings come from the session environment owned by modules/ewm/default.nix.
  (setq ewm-unfocused-alpha 1.0
        ewm-animations-enabled t
        ewm-idle (and pinaceae-ewm-idle-timeout
                      (cons pinaceae-ewm-idle-timeout pinaceae-ewm-lock-command)))

  (setq ewm-focus-follows-mouse t)
  ;; Do not warp the pointer when keyboard focus changes.
  (setq ewm-mouse-follows-focus nil)

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
  ;; ace-window manages Emacs splits; s-q and hydra k close Wayland clients.
  (define-key ewm-mode-map (kbd "s-w") #'ace-window)
  (define-key ewm-mode-map (kbd "s-l") #'pinaceae-ewm-lock-session)
  (define-key ewm-mode-map (kbd "s-c") #'kill-ring-save)
  (define-key ewm-mode-map (kbd "s-v") #'yank)
  (define-key ewm-mode-map (kbd "s-a") #'mark-whole-buffer)
  ;; Shadow windmove's global s-arrow bindings at compositor frame edges.
  (define-key ewm-mode-map (kbd "s-<left>") #'ewm-focus-left)
  (define-key ewm-mode-map (kbd "s-<right>") #'ewm-focus-right)
  (define-key ewm-mode-map (kbd "s-<up>") #'ewm-focus-up)
  (define-key ewm-mode-map (kbd "s-<down>") #'ewm-focus-down)
  ;; `ewm-frame-select' reads its number from the invoking key, so bind it directly.
  (define-key ewm-mode-map (kbd "s-S-<left>") #'ewm-frame-left)
  (define-key ewm-mode-map (kbd "s-S-<right>") #'ewm-frame-right)
  (define-key ewm-mode-map (kbd "C-s-<left>") #'ewm-frame-move-left)
  (define-key ewm-mode-map (kbd "C-s-<right>") #'ewm-frame-move-right)
  (dotimes (i 9)
    (define-key ewm-mode-map (kbd (format "s-%d" (1+ i))) #'ewm-frame-select))
  ;; EWM intercepts media keys even when a Wayland surface has focus.
  (define-key ewm-mode-map (kbd "<AudioRaiseVolume>") #'pinaceae-ewm-volume-up)
  (define-key ewm-mode-map (kbd "<AudioLowerVolume>") #'pinaceae-ewm-volume-down)
  (define-key ewm-mode-map (kbd "<AudioMute>") #'pinaceae-ewm-volume-mute)
  (define-key ewm-mode-map (kbd "<AudioMicMute>") #'pinaceae-ewm-mic-mute)
  (define-key ewm-mode-map (kbd "<MonBrightnessUp>") #'pinaceae-ewm-brightness-up)
  (define-key ewm-mode-map (kbd "<MonBrightnessDown>") #'pinaceae-ewm-brightness-down)

  ;; Intercept hydra prefixes and fullscreen media keys for focused surfaces.
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
  (setq ewm-surface-emulate-keys
        '((?\s-c . "ctrl")
          (?\s-v . "ctrl")
          (?\s-a . "ctrl")))

  (with-eval-after-load 'consult
    (add-to-list 'consult-buffer-sources 'consult-source-xdg-apps t))

  ;; Keep Firefox Picture-in-Picture floating; keep zenity dialogs tiled.
  (add-to-list 'display-buffer-alist
               `(,(ewm-surface-match :app "firefox" :title "^Picture-in-Picture$")
                 ewm-display-buffer-floating))
  (add-to-list 'display-buffer-alist
               `(,(ewm-surface-match :app "zenity") display-buffer-same-window))

  ;; Defer wallpaper and notification helpers until the Wayland socket exists.
  (when (fboundp 'ewm-start-module)
    (advice-add 'ewm-start-module :after #'pinaceae-ewm--maybe-start-wallpaper)
    (advice-add 'ewm-start-module :after #'pinaceae-ewm--maybe-start-notifications))
  (add-hook 'kill-emacs-hook #'pinaceae-ewm--cleanup-children)

  ;; Bind the compositor hydra only after EWM loads.
  (when (require 'pretty-hydra nil t)
    (pretty-hydra-define pinaceae-ewm-hydra
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
        ("TAB" ewm-next-surface-buffer "next surface")
        ("k" kill-current-buffer "kill client" :exit t))
       "Session"
       (("w" pinaceae-ewm-set-wallpaper "wallpaper" :exit t)
        ("l" pinaceae-ewm-lock-session "lock" :exit t)
        ("o" ewm-list-outputs "outputs" :exit t)
        ("x" save-buffers-kill-emacs "exit EWM" :exit t))))
    (global-set-key (kbd "C-c e") #'pinaceae-ewm-hydra/body))

  ;; Run daemon and dashboard setup only for the first compositor GUI frame.
  (add-hook 'after-make-frame-functions #'pinaceae-ewm--trigger-server-hooks)
  (add-hook 'after-make-frame-functions #'pinaceae-ewm--maybe-show-dashboard))

(with-eval-after-load 'ewm
  (pinaceae-ewm--setup))

(provide 'init-ewm)

;;; init-ewm.el ends here

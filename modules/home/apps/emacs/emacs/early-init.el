;;; early-init.el --- Runs before init.el, before UI is drawn -*- lexical-binding: t; -*-

;;; Commentary:
;; Keep this file FAST. Everything here runs before package
;; initialization and before the frame is even drawn.

;;; Code:

;; --- Startup performance -----------------------------------------
;; Raise GC threshold during startup, restore a sane value once idle.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024) ; 32mb
                  gc-cons-percentage 0.1)
            (message "Emacs ready in %s with %d garbage collections."
                     (format "%.2f seconds" (float-time (time-subtract after-init-time before-init-time)))
                     gcs-done)))

;; Don't let file-name-handler-alist slow down every `require'/`load'
;; during startup; restore it afterwards.
(defvar my/file-name-handler-alist-backup file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda () (setq file-name-handler-alist my/file-name-handler-alist-backup)))

;; --- Package management -------------------------------------------
;; We use Elpaca (see init.el), so fully disable package.el. Loading
;; it at all costs ~10-20ms and it'll fight with Elpaca otherwise.
(setq package-enable-at-startup nil)
(advice-add #'package--ensure-init-file :override #'ignore)

;; --- Native compilation --------------------------------------------
(when (featurep 'native-compile)
  (setq native-comp-async-report-warnings-errors 'silent
        native-comp-jit-compilation t
        native-comp-speed 2))
(setq native-compile-prune-cache t)

;; --- UI: get out of the way before the frame ever paints -----------
;; Doing this in early-init avoids the "flash of unstyled Emacs" you
;; get when tool-bar-mode etc. are disabled later in init.el.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(push '(horizontal-scroll-bars . nil) default-frame-alist)
(setq default-frame-alist
      (append '((width . 120) (height . 40)) default-frame-alist))

;; --- Alpha transparency ---------------------------------------------
;; alpha-background = real compositor transparency (needs pgtk/Wayland
;; or an X11 compositor). alpha = older whole-frame text-fade version.
(push '(alpha-background . 88) default-frame-alist) ; 0-100, 100 = opaque
(push '(alpha . (100 . 100)) default-frame-alist)

;; Avoid the default "package.el resizing frame" jank & the startup
;; screen/scratch buffer message.
(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

;; Resizing the Emacs frame can be costly; do it in pixels, not chars.
(setq frame-resize-pixelwise t
      window-resize-pixelwise t)

;;; early-init.el ends here

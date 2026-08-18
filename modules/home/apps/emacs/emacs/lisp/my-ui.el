;;; my-ui.el --- theme, fonts, modeline, transparency -*- lexical-binding: t; -*-
;;; Commentary:
;; Loads your `flutterice' theme (themes/flutterice-theme.el, generated
;; by matugen — regenerate it and this file picks the new colors up
;; automatically on next `load-theme'/restart).
;;; Code:

;; --- Theme --------------------------------------------------------
;; No :ensure — this is YOUR local theme file, not a package.
(load-theme 'flutterice t)

;; --- Fonts ----------------------------------------------------------
(defvar my/font-mono "JetBrainsMono Nerd Font")
(defvar my/font-variable "JetBrainsMono Nerd Font")
(defvar my/font-size 120) ; height is in 1/10 pt, so 120 = 12pt

(set-face-attribute 'default nil :family my/font-mono :height my/font-size)
(set-face-attribute 'fixed-pitch nil :family my/font-mono :height my/font-size)
(set-face-attribute 'variable-pitch nil :family my/font-variable :height my/font-size)

;; --- Alpha transparency toggle --------------------------------------
;; early-init.el sets the default frame's starting alpha; these let you
;; tune it live to match whatever your compositor/matugen wallpaper is
;; doing that day.
(defvar my/alpha-background 88)

(defun my/transparency-set (value)
  "Set frame alpha-background to VALUE (0-100) on all frames."
  (interactive "nAlpha (0-100): ")
  (setq my/alpha-background value)
  (dolist (frame (frame-list))
    (set-frame-parameter frame 'alpha-background value)))

(defun my/transparency-toggle ()
  "Toggle between opaque and `my/alpha-background'."
  (interactive)
  (let ((current (or (frame-parameter nil 'alpha-background) 100)))
    (my/transparency-set (if (= current 100) my/alpha-background 100))))

;; --- Modeline ---------------------------------------------------------
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 28)
  (doom-modeline-icon t)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-minor-modes nil)
  (doom-modeline-env-version t))

(use-package nerd-icons
  ;; Fetch the actual font glyphs once: M-x nerd-icons-install-fonts
  :if (display-graphic-p))

(use-package nerd-icons-dired :hook (dired-mode . nerd-icons-dired-mode))
(use-package nerd-icons-completion
  :after marginalia
  :config (nerd-icons-completion-mode 1))

;; --- Discoverability: which-key ----------------------------------------
;; This is what makes the SPC leader (my-leader.el) feel like
;; Spacemacs/Doom: press SPC and a menu of what's available pops up.
(use-package which-key
  :init (which-key-mode 1)
  :custom
  (which-key-idle-delay 0.4)
  (which-key-sort-order 'which-key-key-order-alpha)
  (which-key-add-column-padding 2)
  (which-key-max-description-length 40))

;; --- Dashboard (replaces the default *scratch* startup buffer) ----------
(use-package dashboard
  :demand t
  :custom
  (dashboard-startup-banner 'logo)     ; swap for a path string to use your own PNG/txt banner
  (dashboard-banner-logo-title "flutterice emacs")
  (dashboard-center-content t)
  (dashboard-vertically-center-content t)
  (dashboard-set-heading-icons t)
  (dashboard-set-file-icons t)
  (dashboard-icon-type 'nerd-icons)
  (dashboard-projects-backend 'project-el)
  (dashboard-items '((recents   . 8)
                      (projects  . 5)
                      (bookmarks . 5)
                      (agenda    . 5)))
  (dashboard-set-navigator t)
  (dashboard-navigator-buttons
   `(((,(when (fboundp 'nerd-icons-faicon) (nerd-icons-faicon "nf-fa-refresh"))
       "Reload config" "Reload init.el"
       (lambda (&rest _) (load-file user-init-file)))
      (,(when (fboundp 'nerd-icons-faicon) (nerd-icons-faicon "nf-fa-cog"))
       "Edit config" "Open init.el"
       (lambda (&rest _) (find-file user-init-file)))
      (,(when (fboundp 'nerd-icons-faicon) (nerd-icons-faicon "nf-fa-paint_brush"))
       "Edit theme" "Open flutterice-theme.el"
       (lambda (&rest _) (find-file (expand-file-name "themes/flutterice-theme.el" user-emacs-directory)))))))
  :config
  (dashboard-setup-startup-hook)
  ;; Standard Emacs startup: run the dashboard whenever Emacs opens with
  ;; no file argument, but a plain `emacs somefile.txt' still opens
  ;; straight into that file, not the dashboard.
  (setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name))))

;; --- Misc UI polish -----------------------------------------------------
(use-package rainbow-mode :commands rainbow-mode) ; colorize "#rrggbb" strings — handy while editing the theme itself
(use-package all-the-icons :if (display-graphic-p))
(use-package hl-todo :hook (prog-mode . hl-todo-mode))
(use-package golden-ratio :commands golden-ratio-mode)

;; A visible-bell that doesn't flash the whole frame.
(setq visible-bell nil)

(provide 'my-ui)
;;; my-ui.el ends here

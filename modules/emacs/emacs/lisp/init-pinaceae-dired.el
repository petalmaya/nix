;;; init-pinaceae-dired.el --- Pinaceae dired extras -*- lexical-binding: t -*-

;; Copyright (C) 2026 Alice (Pinaceae Emacs)

;; This file is part of Pinaceae Emacs, a fork of Centaur Emacs
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
;; Heks-inspired dired QoL on top of vendor init-dired.el.
;; Centaur's omit patterns and listing switches stay untouched.
;;
;;; Code:

;; Reuse the visited dired buffer instead of piling up one per directory.
(setopt dired-kill-when-opening-new-dired-buffer t)

;; Hide ownership details and refresh listings automatically.
(add-hook 'dired-mode-hook (lambda () (dired-hide-details-mode 1)))
(add-hook 'dired-mode-hook (lambda () (auto-revert-mode 1)))

(defun pinaceae/dired-refresh-icons (&rest _)
  "Refresh icons after subtree insertion when the backend provides it."
  (when (fboundp 'nerd-icons-dired--refresh)
    (nerd-icons-dired--refresh)))

;; Single subtle tone instead of the rainbow default; revert by setting
;; `nerd-icons-dired-file-icon-function' back to `nerd-icons-icon-for-file'.
(defface pinaceae-dired-icon-face
  '((t :inherit shadow))
  "Face for dired icons."
  :group 'pinaceae)

(defun pinaceae/dired-muted-file-icon (file &rest args)
  "Colorless icon for FILE in `pinaceae-dired-icon-face'."
  (apply #'nerd-icons-icon-for-file file :face 'pinaceae-dired-icon-face args))

(with-eval-after-load 'nerd-icons-dired
  (setq nerd-icons-dired-file-icon-function #'pinaceae/dired-muted-file-icon)
  (set-face-attribute 'nerd-icons-dired-dir-face nil
                      :inherit 'pinaceae-dired-icon-face))

;; Expandable subtrees; TAB keeps parity with heks-emacs.
(use-package dired-subtree
  :bind (:map dired-mode-map
          ("<tab>" . dired-subtree-toggle)
          ("C-<tab>" . dired-subtree-toggle))
  :config
  (add-hook 'dired-subtree-after-insert-hook #'pinaceae/dired-refresh-icons)
  ;; Unset depth backgrounds so subtrees blend into the pinaceae theme.
  (dolist (face '(dired-subtree-depth-1-face
                  dired-subtree-depth-2-face
                  dired-subtree-depth-3-face
                  dired-subtree-depth-4-face
                  dired-subtree-depth-5-face
                  dired-subtree-depth-6-face))
    (set-face-attribute face nil :background 'unspecified)))

;; Open files with external applications.
(use-package dired-open-with
  :bind (:map dired-mode-map
          ("W" . dired-open-with)))

(provide 'init-pinaceae-dired)

;;; init-pinaceae-dired.el ends here

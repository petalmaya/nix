;;; init-package.el --- Initialize package configurations.	-*- lexical-binding: t -*-

;; Copyright (C) 2006-2026 Vincent Zhang

;; Author: Vincent Zhang <seagle0128@gmail.com>
;; URL: https://github.com/seagle0128/.emacs.d

;; This file is not part of GNU Emacs.
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
;;

;;; Commentary:
;;
;; Emacs Package management configurations.
;;
;; Adapted for Flutter Emacs: packages are installed by Elpaca (see
;; lisp/my-elpaca.el for the bootstrap), not package.el.  The Centaur
;; machinery for package.el (mirror selection, package-initialize, the
;; Windows "all packages in one dir" hack) has been removed; the
;; package-archives defcustoms in init-custom.el are kept for
;; compatibility but are inert.  Updating packages is done with
;; `elpaca-update-all' (bound through the `update-packages' command in
;; init-funcs.el).
;;

;;; Code:

(eval-when-compile
  (require 'init-const)
  (require 'init-custom))

;; Suppress warnings
(defvar use-package-always-ensure)
(defvar use-package-always-defer)
(defvar use-package-expand-minimally)
(defvar use-package-enable-imenu-support)

;; At first startup, copy the example custom file so `customize' has
;; something to write into.
(when (and (not (file-exists-p custom-file))
           (file-exists-p flutter-custom-example-file))
  (copy-file flutter-custom-example-file custom-file))

;; Load `custom-file'
(load custom-file 'noerror)

;; Load custom-post file
(defun load-custom-post-file ()
  "Load custom-post file."
  (cond ((file-exists-p flutter-custom-post-org-file)
         (and (fboundp 'org-babel-load-file)
              (org-babel-load-file flutter-custom-post-org-file)))
        ((file-exists-p flutter-custom-post-file)
         (load flutter-custom-post-file))))
(add-hook 'after-init-hook #'load-custom-post-file)

;; HACK: DO NOT save `package-selected-packages' to `custom-file'
;; @see https://github.com/jwiegley/use-package/issues/383#issuecomment-247801751
;; (Inert under Elpaca, kept for package.el compatibility.)
(with-no-warnings
  (defun my/package--save-selected-packages (&optional value)
    "Set `package-selected-packages' to VALUE but don't save to custom.el."
    (when (or value after-init-time)
      ;; It is valid to set it to nil, for example when the last package
      ;; is uninstalled.  But it shouldn't be done at init time, to
      ;; avoid overwriting configurations that haven't yet been loaded.
      (setq package-selected-packages (sort value #'string<)))
    (unless after-init-time
      (add-hook 'after-init-hook #'my/package--save-selected-packages)))
  (advice-add #'package--save-selected-packages :override #'my/package--save-selected-packages))

;; Prettify package list.  The faces only exist once package.el has
;; been loaded, which never happens under Elpaca, so guard them — an
;; unguarded set-face-attribute here is a fatal error at startup.
(when (facep 'package-status-available)
  (set-face-attribute 'package-status-available nil :inherit 'font-lock-string-face))
(when (facep 'package-description)
  (set-face-attribute 'package-description nil :inherit 'font-lock-comment-face))

;; Should set before loading `use-package'
(setq use-package-always-ensure t
      use-package-always-defer t
      use-package-expand-minimally t
      use-package-enable-imenu-support t)

;; HACK: In 31+, the keyword ":custom-face" is incompatible with `doom-themes'
;; @see https://github.com/doomemacs/themes/issues/893
(with-no-warnings
  (when emacs/>=31p
    (defun my/use-package-handler/:custom-face (name _keyword args rest state)
      "Generate use-package custom-face keyword code."
      (use-package-concat
       (mapcar #'(lambda (def)
                   `(progn
                    (apply #'face-spec-set (append (backquote ,def)))
                    (put ',(car def) 'face-modified t)))
               args)
       (use-package-process-keywords name rest state)))
    (advice-add #'use-package-handler/:custom-face :override #'my/use-package-handler/:custom-face)))

;; Required by `use-package'
(use-package diminish)

;; Update GPG keyring for GNU ELPA
(use-package gnu-elpa-keyring-update)

;; Update packages (fallback for non-Elpaca builds)
(unless (fboundp 'package-upgrade-all)
  (use-package auto-package-update
    :autoload auto-package-update-now
    :custom
    (auto-package-update-delete-old-versions t)
    (auto-package-update-hide-results t)
    :init (defalias 'package-upgrade-all #'auto-package-update-now)))

(provide 'init-package)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-package.el ends here

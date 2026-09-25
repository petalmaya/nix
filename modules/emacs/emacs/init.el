;;; init.el --- entry point for Pinaceae Emacs. -*- lexical-binding: t no-byte-compile: t -*-

;; Pinaceae Emacs is a fork of Centaur Emacs
;; (https://github.com/seagle0128/.emacs.d, GPL-3.0, copyright Vincent
;; Zhang), re-themed and re-branded, managed inside a Nix flake.
;; See NOTICE.md and vendor/centaur/NOTICE.md for attribution.

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

;;; Commentary:
;;
;; Elpaca owns package installation; Nix supplies Emacs and external tools.
;; Runtime state is kept outside this checkout so live and store builds agree.
;;
;;; Code:

(when (version< emacs-version "28.1")
  (error "This requires Emacs 28.1 and above!"))

(setq auto-mode-case-fold nil)

(defun pinaceae/update-load-path (&rest _)
  "Prioritize the config's own load paths."
  (dolist (dir '("site-lisp" "lisp" "vendor/centaur/lisp"))
    (push (expand-file-name dir user-emacs-directory) load-path)))

(pinaceae/update-load-path)

;; Make the generated pinaceae theme findable before init-ui.el loads it.
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes" user-emacs-directory))

(defun pinaceae/add-subdirs-to-load-path (&rest _)
  "Recursively add subdirectories in `site-lisp' to `load-path'."
  (let ((default-directory (expand-file-name "site-lisp" user-emacs-directory)))
    (normal-top-level-add-subdirs-to-load-path)))

(advice-add #'package-initialize :after #'pinaceae/add-subdirs-to-load-path)

(require 'init-const)
(require 'init-custom)
(require 'init-funcs)

;; Keep mutable state outside the symlinked checkout so store and live builds agree.
(defvar pinaceae/state-directory
  (expand-file-name "emacs" (or (getenv "XDG_STATE_HOME")
                                (expand-file-name "~/.local/state")))
  "Directory for Emacs runtime state (custom.el, recentf, places, ...).")
(make-directory pinaceae/state-directory :parents)
(setq custom-file (expand-file-name "custom.el" pinaceae/state-directory)
      recentf-save-file (expand-file-name "recentf.eld" pinaceae/state-directory)
      save-place-file (expand-file-name "places.eld" pinaceae/state-directory)
      savehist-file (expand-file-name "history" pinaceae/state-directory)
      eshell-aliases-file (expand-file-name "eshell-alias" pinaceae/state-directory)
      eshell-history-file-name (expand-file-name "eshell-history" pinaceae/state-directory)
      tramp-persistency-file-name (expand-file-name "tramp" pinaceae/state-directory))

;; Bootstrap Elpaca before any use-package forms resolve `:ensure'.
(require 'my-elpaca)

(require 'init-package)

(require 'init-base)
(require 'init-hydra)

(require 'init-ui)
(require 'init-edit)
(require 'init-completion)
(require 'init-snippet)
(require 'init-check)

(require 'init-bookmark)
(require 'init-calendar)
(require 'init-dashboard)
(require 'init-dired)
(require 'init-highlight)
(require 'init-ibuffer)
(require 'init-kill-ring)
(require 'init-workspace)
(require 'init-window)
(require 'init-treemacs)

(require 'init-eshell)
(require 'init-shell)

(require 'init-markdown)
(require 'init-org)
(require 'init-reader)

(require 'init-dict)
(require 'init-docker)
(require 'init-player)
(require 'init-utils)

(require 'init-vc)
(require 'init-lsp)
(require 'init-dap)
(require 'init-ai)

(require 'init-prog)
(require 'init-elisp)
(require 'init-c)
(require 'init-go)
(require 'init-rust)
(require 'init-python)
(require 'init-ruby)
(require 'init-elixir)
(require 'init-web)

(require 'init-extras)

;; EWM setup is dormant until the compositor package loads.
(require 'init-ewm)

;;; init.el ends here

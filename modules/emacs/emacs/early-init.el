;;; early-init.el --- Early initialization. -*- lexical-binding: t -*-

;; Copyright (C) 2019-2026 Vincent Zhang (Centaur Emacs, GPL-3.0 —
;; see NOTICE.md), with Pinaceae Emacs additions (transparency).

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
;; Startup settings run before init.el; gcmh-mode restores garbage collection
;; after initialization.

;;; Code:

;; Defer garbage collection until gcmh-mode restores it.
(setq gc-cons-percentage 1.0)
(if noninteractive  ; in CLI sessions
    (setq gc-cons-threshold #x8000000)  ; 128MB
  (setq gc-cons-threshold most-positive-fixnum))

;; Increase process-output buffering for interactive processes.
(setq read-process-output-max #x10000)  ; 64kb

;; Avoid file-handler and compressed-file checks during startup; restore the
;; defaults after init. Keep .so because EWM must load ewm-core early.
(let ((default-file-name-handler-alist file-name-handler-alist)
      (default-load-suffixes load-suffixes)
      (default-load-file-rep-suffixes load-file-rep-suffixes))
  (setq file-name-handler-alist nil
        load-suffixes '(".elc" ".el" ".so")
        load-file-rep-suffixes '(""))
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq load-suffixes default-load-suffixes
                    load-file-rep-suffixes default-load-file-rep-suffixes
                    file-name-handler-alist default-file-name-handler-alist))
            101))

;; Emacs 31 can cache directory lookups during startup.
(when (boundp 'load-path-filter-function)
  (setq load-path-filter-function #'load-path-filter-cache-directory-files))

;; Avoid compiling packages while loading them during startup.
(setq native-comp-deferred-compilation nil
      native-comp-jit-compilation nil)

;; Keep the eln cache tidy and native-comp warnings out of the echo area.
(when (featurep 'native-compile)
  (setq native-comp-async-report-warnings-errors 'silent)
  (setq native-compile-prune-cache t))

;; Elpaca owns package initialization; disable Emacs's early pass.
(setq package-enable-at-startup nil)

;; Prefer source files in noninteractive sessions to avoid stale bytecode.
(setq load-prefer-newer noninteractive)

;; Prefer UTF-8 for newly opened files.
(prefer-coding-system 'utf-8)

;; `use-package' is built in since Emacs 29.
(setq use-package-enable-imenu-support t)

(setq frame-inhibit-implied-resize t)

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(when (featurep 'ns)
  (push '(ns-transparent-titlebar . t) default-frame-alist)
  (push '(ns-appearance . dark) default-frame-alist))

;; alpha-background requires a compositor; alpha is the legacy fallback.
(push '(alpha-background . 88) default-frame-alist) ; 0-100, 100 = opaque
(push '(alpha . (100 . 100)) default-frame-alist)
(push '(width . 120) default-frame-alist)
(push '(height . 40) default-frame-alist)
(setq frame-resize-pixelwise t
      window-resize-pixelwise t)

(setq-default mode-line-format nil)

;; Keep environment loading independent of exec-path-from-shell.
(when-let* ((env-file (expand-file-name "env.el" user-emacs-directory))
            (env-example-file (expand-file-name "env-example.el" user-emacs-directory)))
  (when (and (not (file-exists-p env-file))
             (file-exists-p env-example-file))
    (copy-file env-example-file env-file))
  (load env-file 'noerror))

;;; early-init.el ends here

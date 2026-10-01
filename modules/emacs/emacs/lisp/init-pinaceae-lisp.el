;;; init-pinaceae-lisp.el --- Pinaceae elisp eval keys -*- lexical-binding: t -*-

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
;; Global eval bindings so *scratch* quicktests never need M-x.
;; `eval-last-sexp' echoes instead of inserting, keeping it safe outside lisp buffers.
;;
;;; Code:

(global-set-key (kbd "C-c l e") #'eval-buffer)
(global-set-key (kbd "C-c l d") #'eval-defun)
(global-set-key (kbd "C-c l r") #'eval-region)
(global-set-key (kbd "C-c l s") #'eval-last-sexp)

;; The C-c l group also holds link-hint keys; label it for both.
(with-eval-after-load 'which-key
  (when (fboundp 'which-key-add-key-based-replacements)
    (which-key-add-key-based-replacements "C-c l" "link/eval")))

(provide 'init-pinaceae-lisp)

;;; init-pinaceae-lisp.el ends here

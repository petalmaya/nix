;;; my-org.el --- org-mode -*- lexical-binding: t; -*-
;;; Code:

(use-package org
  :ensure nil
  :custom
  (org-directory "~/org")
  (org-agenda-files (list org-directory))
  (org-hide-emphasis-markers t)
  (org-startup-indented t)
  (org-startup-folded 'content)
  (org-pretty-entities t)
  (org-ellipsis " ▾")
  (org-src-tab-acts-natively t)
  (org-src-fontify-natively t)
  (org-confirm-babel-evaluate nil)
  (org-log-done 'time)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "WAIT(w)" "|" "DONE(d)" "CANCELLED(c)"))))

;; org-modern gives you the pretty bullets/tables/checkboxes Doom's
;; org config is famous for, as a small standalone package instead of
;; a 2000-line doom module.
(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :custom
  (org-modern-star '("◉" "○" "✸" "✿" "✤" "✜" "◆"))
  (org-modern-hide-stars t)
  (org-modern-table t)
  (org-modern-checkbox
   '((?X . "☑") (?- . "◐") (?\s . "☐"))))

(use-package org-appear ; reveal markup when point enters it
  :hook (org-mode . org-appear-mode))

(use-package toc-org :hook (org-mode . toc-org-mode))

(provide 'my-org)
;;; my-org.el ends here

;;; my-modal.el --- god-mode command mode -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; god-mode instead of ryo-modal. No custom layout, no relearned
;; commands — it's stock Emacs bindings, just typed without holding
;; modifiers while active: "x f" is C-x C-f, "x s" is C-x C-s, "c g"
;; is C-c C-g, and so on. Anything you already know from vanilla
;; Emacs keybindings still works exactly the same, letter for letter.
;;
;; <escape> toggles god-local-mode on/off, same as <escape> toggled
;; ryo-modal-mode before.
;;
;;; Code:

(use-package god-mode
  :commands (god-local-mode god-mode-all)
  :bind ("<escape>" . god-local-mode)
  :init
  (add-hook 'prog-mode-hook #'god-local-mode)
  (add-hook 'text-mode-hook #'god-local-mode)
  (add-hook 'conf-mode-hook #'god-local-mode)
  :config
  ;; Cursor shape is the only visual cue you get (no mode-line
  ;; surgery here) — box while in god-mode, bar while inserting.
  (defun my/god-mode-cursor-update ()
    (setq cursor-type (if (or god-local-mode buffer-read-only) 'box 'bar)))
  (add-hook 'god-mode-enabled-hook #'my/god-mode-cursor-update)
  (add-hook 'god-mode-disabled-hook #'my/god-mode-cursor-update)

  ;; god-mode's own convention: "." repeats the last command, since
  ;; there's no modifier key free to spare for repeat-key otherwise.
  (define-key god-local-mode-map (kbd ".") #'repeat))

(provide 'my-modal)
;;; my-modal.el ends here

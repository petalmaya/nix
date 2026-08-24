;;; my-modal.el --- ryo-modal command mode -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; Custom layout, no vim/xah-fly-keys emulation. ryo-modal ships zero
;; default bindings, so every key below is picked, and freely
;; rebindable per-line.
;;
;;   home row (jkl;)      arrows       (j=left k=down l=right ;=eol)
;;   home row (asdf)      M-x / RET / kill-sexp / insert-mode
;;   top row (qwertyuiop) word/format/undo/movement
;;   bottom row (zxcvbnm) comment/cut/copy/paste/case/search/sexp-nav
;;   thumb (space)        leader (my-leader.el)
;;
;; f enters insert mode; <escape> always returns to command mode.
;;
;;; Code:

(use-package ryo-modal
  :commands (ryo-modal-mode ryo-modal-global-mode)
  :bind ("<escape>" . ryo-modal-mode)
  :init
  (require 'subword) ; subword-backward isn't autoloaded
  (add-hook 'prog-mode-hook #'ryo-modal-mode)
  (add-hook 'text-mode-hook #'ryo-modal-mode)
  (add-hook 'conf-mode-hook #'ryo-modal-mode)
  :config
  (setq ryo-modal-cursor-color nil) ; theme's cursor face already handles this
  (setq ryo-modal-default-cursor-color (face-attribute 'cursor :background))

  ;; q w e r t y u i o p
  (ryo-modal-keys
   ("q" indent-for-tab-command      :name "format")
   ("w" subword-backward            :name "sub-word ←")
   ("e" backward-kill-word          :name "kill word ←")
   ("r" kill-word                   :name "kill word →")
   ("t" set-mark-command            :name "mark")
   ("y" undo-fu-only-undo           :name "undo")
   ("u" backward-word               :name "word ←")
   ("i" previous-line               :name "↑")
   ("o" forward-word                :name "word →")
   ("p" just-one-space              :name "⌴"))

  ;; a s d f | j k l ;
  (ryo-modal-keys
   ("a" execute-extended-command    :name "M-x")
   ("s" newline                     :name "RET")
   ("d" kill-sexp                   :name "kill sexp")
   ("f" ryo-modal-mode              :name "insert" :exit t)
   ("g" er/expand-region            :name "select/expand")
   ("h" beginning-of-line           :name "⇤")
   ("j" backward-char               :name "←")
   ("k" next-line                   :name "↓")
   ("l" forward-char                :name "→")
   (";" end-of-line                 :name "⇥")
   ("'" delete-other-windows        :name "unsplit"))

  ;; z x c v b n m , . /
  (ryo-modal-keys
   ("z" comment-line                :name "comment")
   ("x" kill-region                 :name "cut")
   ("c" kill-ring-save              :name "copy")
   ("v" yank                        :name "paste")
   ("b" capitalize-dwim             :name "Case")
   ("n" isearch-forward             :name "search")
   ("m" backward-sexp               :name "sexp ←")
   ("," forward-word                :name "next word")
   ("." forward-sexp                :name "sexp →")
   ("/" mark-sexp                   :name "mark sexp"))

  ;; window splits
  (ryo-modal-keys
   ("-" split-window-below          :name "split —")
   ("=" split-window-right          :name "split │"))

  ;; shifted extras not on the diagram: select-all/redo/delete
  (ryo-modal-keys
   ("A" mark-whole-buffer           :name "select all")
   ("Y" undo-fu-only-redo           :name "redo")
   ("D" delete-char                 :name "delete →")
   ("X" backward-delete-char        :name "delete ←"))

  ;; digits stay digits; C-u prefix-arg still works normally
  (ryo-modal-keys
   ("0" digit-argument) ("1" digit-argument) ("2" digit-argument)
   ("3" digit-argument) ("4" digit-argument) ("5" digit-argument)
   ("6" digit-argument) ("7" digit-argument) ("8" digit-argument)
   ("9" digit-argument)))

;; which-key should pick up ryo-modal's own keymap too, not just the leader
(with-eval-after-load 'ryo-modal
  (with-eval-after-load 'which-key
    (which-key-mode 1)))

(provide 'my-modal)
;;; my-modal.el ends here

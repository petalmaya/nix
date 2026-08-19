;;; my-leader.el --- SPC leader menu -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; Spacemacs/Doom-style SPC leader via general.el, no evil. Groups
;; mirror Doom's SPC menu (f=files b=buffers p=project g=git s=search
;; w=windows o=open c=code); commands underneath are vanilla Emacs.
;;
;;; Code:

(use-package general
  :ensure (:wait t)
  :demand t
  :config
  (general-create-definer my/leader
    :states nil
    :keymaps '(ryo-modal-mode-map)
    :prefix "SPC"
    :global-prefix "M-SPC") ; also reachable from insert mode / non-modal buffers

  (my/leader
    "SPC" '(execute-extended-command :wk "M-x")
    "!"   '(shell-command :wk "shell command")
    ":"   '(eval-expression :wk "eval expr")
    "u"   '(universal-argument :wk "universal arg"))

  ;; --- f: files -------------------------------------------------------
  (my/leader
    "f"   '(:ignore t :wk "files")
    "f f" '(find-file :wk "find file")
    "f r" '(consult-recent-file :wk "recent file")
    "f s" '(save-buffer :wk "save")
    "f S" '(write-file :wk "save as")
    "f D" '(delete-file :wk "delete file")
    "f R" '(rename-file :wk "rename file")
    "f c" '((lambda () (interactive) (find-file user-init-file)) :wk "edit config")
    "f t" '((lambda () (interactive) (find-file (expand-file-name "themes/flutterice-theme.el" user-emacs-directory))) :wk "edit theme"))

  ;; --- b: buffers -------------------------------------------------------
  (my/leader
    "b"   '(:ignore t :wk "buffers")
    "b b" '(consult-buffer :wk "switch buffer")
    "b k" '(kill-current-buffer :wk "kill buffer")
    "b n" '(next-buffer :wk "next")
    "b p" '(previous-buffer :wk "prev")
    "b r" '(revert-buffer :wk "revert")
    "b s" '(scratch-buffer :wk "scratch"))

  ;; --- p: project (built-in project.el, no projectile needed) -----------
  (my/leader
    "p"   '(:ignore t :wk "project")
    "p p" '(project-switch-project :wk "switch project")
    "p f" '(project-find-file :wk "find file in project")
    "p b" '(consult-project-buffer :wk "project buffer")
    "p g" '(consult-ripgrep :wk "grep project")
    "p k" '(project-kill-buffers :wk "kill project buffers")
    "p c" '(project-compile :wk "compile")
    "p e" '(project-eshell :wk "eshell")
    "p d" '(project-find-dir :wk "find dir")
    "p r" '(project-query-replace-regexp :wk "replace in project"))

  ;; --- g: git / magit -----------------------------------------------------
  (my/leader
    "g"   '(:ignore t :wk "git")
    "g g" '(magit-status :wk "status")
    "g b" '(magit-blame-addition :wk "blame")
    "g l" '(magit-log-current :wk "log")
    "g c" '(magit-commit :wk "commit")
    "g p" '(magit-push :wk "push")
    "g f" '(magit-pull :wk "pull")
    "g d" '(magit-diff-buffer-file :wk "diff file")
    "g s" '(magit-stage-file :wk "stage file")
    "g t" '(git-timemachine :wk "time machine"))

  ;; --- s: search ------------------------------------------------------------
  (my/leader
    "s"   '(:ignore t :wk "search")
    "s s" '(consult-line :wk "in buffer")
    "s S" '(consult-line-multi :wk "in all buffers")
    "s p" '(consult-ripgrep :wk "in project")
    "s d" '(consult-find :wk "find file (name)")
    "s i" '(consult-imenu :wk "imenu")
    "s o" '(consult-outline :wk "outline")
    "s m" '(consult-mark :wk "marks")
    "s g" '(consult-goto-line :wk "goto line"))

  ;; --- w: windows -------------------------------------------------------
  (my/leader
    "w"   '(:ignore t :wk "windows")
    "w w" '(other-window :wk "other window")
    "w v" '(split-window-right :wk "split │")
    "w s" '(split-window-below :wk "split —")
    "w d" '(delete-window :wk "delete")
    "w o" '(delete-other-windows :wk "only this")
    "w =" '(balance-windows :wk "balance")
    "w u" '(winner-undo :wk "undo layout")
    "w r" '(winner-redo :wk "redo layout")
    "w h" '(windmove-left :wk "← window")
    "w l" '(windmove-right :wk "→ window")
    "w k" '(windmove-up :wk "↑ window")
    "w j" '(windmove-down :wk "↓ window"))

  ;; --- o: open / toggles -------------------------------------------------
  (my/leader
    "o"   '(:ignore t :wk "open")
    "o t" '(ghostel :wk "terminal")
    "o T" '(ghostel-project :wk "terminal (project root)")
    "o b" '(ghostel-project-list-buffers :wk "terminal buffers")
    "o e" '(eshell :wk "eshell")
    "o d" '(dired-jump :wk "dired here")
    "o a" '(org-agenda :wk "org agenda")
    "o h" '(dashboard-open :wk "dashboard")
    "o A" '(my/transparency-toggle :wk "toggle transparency")
    "o l" '(display-line-numbers-mode :wk "line numbers"))

  ;; --- c: code -----------------------------------------------------------
  (my/leader
    "c"   '(:ignore t :wk "code")
    "c a" '(eglot-code-actions :wk "code action")
    "c r" '(eglot-rename :wk "rename")
    "c f" '(eglot-format-buffer :wk "format buffer")
    "c d" '(eldoc :wk "doc at point")
    "c e" '(consult-flymake :wk "errors")
    "c i" '(eglot-find-implementation :wk "implementation")
    "c c" '(project-compile :wk "compile")
    "c x" '(embark-act :wk "act on thing"))

  ;; --- m: media / comms (empv, nov, elfeed, ement, elcord) -------
  (my/leader
    "m"   '(:ignore t :wk "media/comms")
    "m p" '(empv-play-or-enqueue :wk "play/enqueue")
    "m y" '(empv-youtube :wk "youtube search")
    "m r" '(empv-play-radio :wk "radio")
    "m SPC" '(empv-toggle :wk "play/pause")
    "m n" '(empv-playlist-next :wk "next track")
    "m N" '(empv-playlist-prev :wk "prev track")
    "m e" '(find-file :wk "open epub") ; nov-mode auto-activates on .epub
    "m F" '(elfeed :wk "rss feeds")
    "m u" '(elfeed-update :wk "update feeds")
    "m M" '(ement-connect :wk "matrix connect")
    "m l" '(ement-list-rooms :wk "matrix rooms")
    "m d" '(elcord-mode :wk "toggle discord presence"))

  ;; --- h: help (mirrors C-h, but reachable without Ctrl) ------------------
  (my/leader
    "h"   '(:ignore t :wk "help")
    "h f" '(helpful-callable :wk "function")
    "h v" '(helpful-variable :wk "variable")
    "h k" '(helpful-key :wk "key")
    "h m" '(describe-mode :wk "mode")
    "h b" '(embark-bindings :wk "bindings here"))

  ;; --- q: quit -------------------------------------------------------------
  (my/leader
    "q"   '(:ignore t :wk "quit")
    "q q" '(save-buffers-kill-terminal :wk "quit emacs")
    "q r" '(restart-emacs :wk "restart")))

(use-package restart-emacs :commands restart-emacs)

(provide 'my-leader)
;;; my-leader.el ends here

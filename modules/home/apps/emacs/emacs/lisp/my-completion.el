;;; my-completion.el --- minibuffer + in-buffer completion -*- lexical-binding: t; -*-
;;; Commentary:
;; The modern non-Doom-specific stack: vertico (minibuffer UI) +
;; orderless (fuzzy matching) + consult (search/navigation commands) +
;; embark (act-on-thing-at-point / right-click-via-keyboard) +
;; marginalia (annotations) for completion-at-point, and corfu + cape
;; for in-buffer (LSP/dabbrev/etc) completion. This is what Doom Emacs
;; itself uses under the hood now instead of ivy/helm.
;;; Code:

(use-package vertico
  :init (vertico-mode 1)
  :custom
  (vertico-cycle t)
  (vertico-resize t))

(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word)))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion))))
  (orderless-matching-styles '(orderless-literal orderless-regexp orderless-flex)))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package savehist :ensure nil :init (savehist-mode 1)) ; ranks recent picks higher

(use-package consult
  :commands (consult-buffer consult-find consult-ripgrep consult-line
             consult-imenu consult-outline consult-goto-line consult-yank-pop
             consult-recent-file consult-flymake consult-git-grep
             consult-project-buffer consult-bookmark consult-mark)
  :custom
  (consult-narrow-key "<")
  (xref-show-xrefs-function #'consult-xref)
  (xref-show-definitions-function #'consult-xref)
  :init
  ;; Use ripgrep/fd from the Nix flake's PATH automatically — no
  ;; extra config needed, `consult' just shells out to whatever
  ;; `executable-find' turns up.
  (setq consult-ripgrep-args
        "rg --null --line-buffered --color=never --max-columns=1000 \
         --path-separator / --smart-case --no-heading --line-number ."))

(use-package embark
  :commands (embark-act embark-dwim embark-export embark-bindings)
  :custom
  (prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect\\(Live\\|Completions\\)\\*"
                 nil (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; --- In-buffer / LSP completion ---------------------------------------
(use-package corfu
  :init (global-corfu-mode 1)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.15)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-popupinfo-delay '(0.3 . 0.15))
  :config
  (corfu-popupinfo-mode 1))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block))

(use-package kind-icon
  :after corfu
  :custom (kind-icon-default-face 'corfu-default)
  :config (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

;; Snippets — Doom/Spacemacs both wire these into completion.
(use-package yasnippet
  :init (yas-global-mode 1))
(use-package yasnippet-capf
  :after (cape yasnippet)
  :init (add-to-list 'completion-at-point-functions #'yasnippet-capf))
(use-package yasnippet-snippets :after yasnippet)

(provide 'my-completion)
;;; my-completion.el ends here

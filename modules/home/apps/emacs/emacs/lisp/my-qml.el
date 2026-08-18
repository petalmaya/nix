;;; my-qml.el --- Quickshell / QML editing support -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; Quickshell config is QML. Stack per Quickshell's own install docs:
;; yuja/tree-sitter-qmljs (grammar), xhcoding/qml-ts-mode (major mode),
;; qmlls (language server, from Qt Declarative — see flake.nix). Using
;; eglot as the client, same as everything else in my-dev.el.
;;
;;; Code:

;; grammar isn't on MELPA; registers the fetch source, actual install
;; happens on first .qml visit (or M-x treesit-install-language-grammar)
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(qmljs "https://github.com/yuja/tree-sitter-qmljs")))

;; qml-ts-mode isn't on MELPA either — pull it straight from its repo,
;; same as Quickshell's own docs point at.
(use-package qml-ts-mode
  :ensure (:host github :repo "xhcoding/qml-ts-mode")
  :mode ("\\.qml\\'" . qml-ts-mode)
  :hook (qml-ts-mode . (lambda ()
                          (setq-local electric-indent-chars
                                      '(?\n ?\( ?\) ?{ ?} ?\[ ?\] ?\; ?\,))
                          (eglot-ensure))))

;; Register qmlls with eglot the same way my-dev.el registers `nil' for
;; Nix — `qmlls' needs to be on PATH (it comes from Qt6's declarative
;; dev tools; see flake.nix's externalTools).
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(qml-ts-mode . ("qmlls"))))

;; Quickshell's docs flag a real caveat: qmlls gives up on malformed
;; QML (unbalanced braces mid-edit) and can't resolve Quickshell's own
;; types like PanelWindow — expect gaps, it's still useful for the
;; parts of QtQuick/QML it does know.

(provide 'my-qml)
;;; my-qml.el ends here

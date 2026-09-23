;;; my-elpaca.el --- package manager bootstrap -*- lexical-binding: t; -*-
;;; Commentary:
;; Elpaca bootstrap and compatibility shims for use-package.
;;; Code:

(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                               :ref nil :depth 1 :inherit ignore
                               :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                               :build (:not elpaca-activate)))
(let* ((repo (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                   ,@(when-let* ((depth (plist-get order :depth)))
                                                       (list (format "--depth=%d" depth) "--no-single-branch"))
                                                   ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                         (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                         "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Load Elpaca's bundled use-package extension directly; installing it as a
;; package resolves the same file through a menu path that failed at startup.
(load (expand-file-name "extensions/elpaca-use-package.el"
                        (expand-file-name "elpaca" elpaca-sources-directory)))

;; Hand use-package's `:ensure' keyword over to Elpaca.
(elpaca-use-package-mode)
(setq use-package-always-ensure t)

;; Explicit recipes avoid Elpaca menu lookups for shared dependencies.
;; Recipes belong inside the order list; trailing keyword arguments become body.
(elpaca (compat :repo "https://github.com/emacs-compat/compat"))

;; Emacs 30's bundled transient stub compares newer than MELPA transient;
;; ignore that version check and install the real package explicitly.
(with-eval-after-load 'elpaca
  (add-to-list 'elpaca-ignored-dependencies 'transient))

;; Install transient explicitly; Emacs 30's bundled stub is not sufficient.
(elpaca (transient :repo "https://github.com/magit/transient"))

;; Keep Emacs's matched built-ins; separately installing them races
;; global-eldoc-mode and reopens Elpaca's ignored-version checks.
(with-eval-after-load 'elpaca
  (dolist (dep '(eldoc flymake jsonrpc project xref))
    (add-to-list 'elpaca-ignored-dependencies dep)))

;; Queue hydra before pretty-hydra to avoid a duplicate dependency warning.
(elpaca (hydra :repo "https://github.com/abo-abo/hydra"))

;; pretty-hydra registers its use-package keyword when loaded; queue it
;; after its dependencies and wait before loading the remaining modules.
(elpaca (pretty-hydra :repo "https://github.com/jerrypnz/major-mode-hydra.el"
                      :files ("pretty-hydra.el")))

;; Wait for the queued packages before loading the remaining modules.
(elpaca-wait)

;; Keep this require failure loud; vendor modules depend on the keyword.
(require 'pretty-hydra)

;; Centaur's use-package forms assume package.el's built-in detection; teach
;; Elpaca to skip packages that resolve inside Emacs's own lisp tree.
(defun my/elpaca-built-in-p (name)
  "Return non-nil if NAME is a package built into Emacs."
  (or (and (fboundp 'package-built-in-p) (package-built-in-p name))
      (and (boundp 'package--builtin-versions)
           (assq name package--builtin-versions))
      (and (boundp 'package--builtins)
           (assq name package--builtins))
      (let* ((lib (and data-directory
                       (locate-library (symbol-name name))))
             ;; data-directory is .../etc/; lisp is .../lisp/.
             (lisp-dir (when data-directory
                         (file-name-as-directory
                          (expand-file-name "../lisp" data-directory))))
             ;; Fall back to a known built-in location if needed.
             (lisp-dir (or lisp-dir
                           (when-let* ((simple (locate-library "simple")))
                             (file-name-directory simple)))))
        (and lib lisp-dir
             (string-prefix-p (file-name-as-directory lisp-dir)
                              (file-name-as-directory lib))))))

(with-eval-after-load 'elpaca-use-package
  (defun my/elpaca-skip-builtin (orig name _keyword ensure rest state)
    "Run Elpaca's `:ensure' handler, skipping built-in packages."
    (if (and ensure
             (my/elpaca-built-in-p name)
             (not (eq name 'transient)))
        (use-package-process-keywords name rest state)
      (funcall orig name _keyword ensure rest state)))
  (when (fboundp 'elpaca-use-package--handler)
    (advice-add #'use-package-handler/:ensure :around #'my/elpaca-skip-builtin)))

;; Bind posframe settings before Elpaca can fail; init-hydra/init-ui read
;; them while defining their own posframe integrations.
(defvar posframe-border-width 2
  "Default posframe border width. Overridden by init-base.el.")
(defface posframe-border '((t (:inherit region)))
  "Fallback face for posframe border. Overridden by init-base.el."
  :group 'posframe)

(setq use-package-expand-minimally nil
      use-package-compute-statistics nil) ; flip to t to profile startup

(provide 'my-elpaca)
;;; my-elpaca.el ends here

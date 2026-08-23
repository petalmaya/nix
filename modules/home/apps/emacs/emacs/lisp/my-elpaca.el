;;; my-elpaca.el --- package manager bootstrap -*- lexical-binding: t; -*-
;;; Commentary:
;; Elpaca: async, git-based package manager. Chosen over package.el
;; because it can pull straight from GitHub (one-off forks, packages
;; not on MELPA, etc.) and over straight.el because it's faster and
;; has cleaner use-package integration in 2025/2026.
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

;; Hand use-package's `:ensure' keyword over to Elpaca.
(elpaca elpaca-use-package
  (elpaca-use-package-mode)
  (setq use-package-always-ensure t))

;; Block here so everything below can safely assume packages exist.
(elpaca-wait)

;; --- Emacs-30-era transient version footgun --------------------------
;; Recent Emacs bundles a stub `transient' internally stamped "0.13".
;; Elisp's version-list comparison reads that as NEWER than the real
;; MELPA release (e.g. 0.7.2.2), because it compares component-wise
;; and 13 > 7. That makes Elpaca think magit's real dependency is
;; "outdated" and refuse to install it. Telling Elpaca to skip
;; version-checking transient (while still installing the real one
;; explicitly, see lisp/my-dev.el) works around it.
(with-eval-after-load 'elpaca
  (add-to-list 'elpaca-ignored-dependencies 'transient))

;; Silence "assignment to free variable" for the handful of built-ins
;; we tweak with setq before their package is loaded.
(setq use-package-expand-minimally nil
      use-package-compute-statistics nil) ; flip to t to profile startup

(provide 'my-elpaca)
;;; my-elpaca.el ends here

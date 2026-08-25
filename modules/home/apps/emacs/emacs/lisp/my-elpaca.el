;;; my-elpaca.el --- package manager bootstrap -*- lexical-binding: t; -*-
;;; Commentary:
;; Elpaca: async, git-based package manager. Chosen over package.el
;; because it can pull straight from GitHub (needed for ryo-modal's
;; extra bindings, one-off forks, etc.) and over straight.el because
;; it's faster and has cleaner use-package integration in 2025/2026.
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

;; Elpaca's use-package support ships inside the elpaca checkout we
;; cloned above (extensions/elpaca-use-package.el).  Load it straight
;; from that checkout instead of asking Elpaca to install a second copy
;; of the repo as a "package": the package-install path resolves the
;; recipe through Elpaca's menu system and depends on its autoload
;; machinery, which broke at startup with a file-missing error for
;; "extensions/elpaca-use-package".  Loading the file directly is what
;; the simple Elpaca bootstrap does; it has no such failure mode.
(load (expand-file-name "extensions/elpaca-use-package.el"
                        (expand-file-name "elpaca" elpaca-sources-directory)))

;; Hand use-package's `:ensure' keyword over to Elpaca.
(elpaca-use-package-mode)
(setq use-package-always-ensure t)

;; --- compat / transient: explicit recipes, no menu lookup --------------
;; compat is a dependency of transient, vertico, marginalia, corfu and
;; most of the stack.  Elpaca resolves dependency recipes through its
;; menu system (MELPA/GNU ELPA fetches); that lookup failed and killed
;; every dependant ("Condition (finished . compat) failed").  Declaring
;; the recipe explicitly turns the install into a plain git clone.
;; Order matters: compat and transient must be queued BEFORE any package
;; that depends on them (e.g. pretty-hydra, magit), otherwise Elpaca
;; auto-queues them as dependencies first and later explicit queues warn
;; "compat previously queued as dependency of: (pretty-hydra)".
;; NOTE on syntax: the recipe goes INSIDE the order list —
;; (elpaca (pkg :repo ...)) — never as trailing args.  The `elpaca'
;; macro treats trailing args as config BODY, evaluated at
;; queue-finalize; `(elpaca eglot :repo ... :files (:defaults))' thus
;; evaluated the `(:defaults)' plist as a function call and died with
;; "Config Error eglot: (void-function :defaults)".
(elpaca (compat :repo "https://github.com/emacs-compat/compat"))

;; --- Emacs-30-era transient version footgun ---------------------------
;; Recent Emacs bundles a stub `transient' internally stamped "0.13".
;; Elisp's version-list comparison reads that as NEWER than the real
;; MELPA release (e.g. 0.7.2.2), because it compares component-wise
;; and 13 > 7. That makes Elpaca think magit's real dependency is
;; "outdated" and refuse to install it. Telling Elpaca to skip
;; version-checking transient works around it.
(with-eval-after-load 'elpaca
  (add-to-list 'elpaca-ignored-dependencies 'transient))

;; Install the real transient explicitly — Emacs 30's bundled stub
;; isn't enough for magit, and the ignored-dependencies entry above
;; keeps the version check from blocking it as magit's dependency.
(elpaca (transient :repo "https://github.com/magit/transient"))

;; --- Built-in support packages: keep Emacs's own ----------------------
;; eglot, eldoc, flymake, jsonrpc, project and xref are built into
;; Emacs 30 as a matched set (eglot 1.17 + eldoc 1.15 + flymake 1.3.x
;; + jsonrpc 1.0.25).  Upgrading pieces of that set through Elpaca is
;; a losing game: eldoc is force-loaded by global-eldoc-mode before
;; Elpaca's queue ever activates, so an Elpaca-installed eldoc cannot
;; take effect and merely warns "eldoc loaded before Elpaca activation"
;; at every startup.  Explicitly queueing any of them also re-opens the
;; version checks Elpaca skips for ignored deps ("Outdated dependency"
;; failures) and double-queues them ("flymake previously queued as
;; dependency of: (eglot)").  So: keep them on the ignored list — their
;; versions are never checked against the packages that require newer
;; numbers (e.g. eldoc-mouse, flymake-ruff) — and let Emacs's own
;; copies serve.  eglot is configured in init-lsp.el with `:ensure nil'
;; and resolves to the built-in too.
(with-eval-after-load 'elpaca
  (dolist (dep '(eldoc flymake jsonrpc project xref))
    (add-to-list 'elpaca-ignored-dependencies dep)))

;; hydra is a dependency of pretty-hydra. Queue it explicitly first so
;; the later `use-package hydra' in init-hydra.el does not trigger the
;; "hydra previously queued as dependency of: (pretty-hydra)" warning.
(elpaca hydra)

;; pretty-hydra registers the `:pretty-hydra' use-package keyword when
;; its file loads, and many modules use that keyword in their
;; `use-package' forms — so it must be loaded before any of them parse.
;; Install it now (after compat/transient/hydra so its dependencies
;; are already queued), block until it is ready, then load it.
(elpaca pretty-hydra)

;; Block here so everything below can safely assume packages exist.
(elpaca-wait)

;; Register the `:pretty-hydra' keyword for the rest of init.
(with-demoted-errors "pretty-hydra: %S"
  (require 'pretty-hydra))

;; --- Built-in packages under Elpaca ----------------------------------
;; Centaur's config was written for package.el, which treats Emacs's
;; built-in packages (server, recentf, savehist, saveplace, eglot,
;; flymake, eldoc, xref, time, newsticker, ibuffer, windmove, ...) as
;; "installed" and skips them. Elpaca has no recipe for those and
;; fails at startup with "Unable to determine recipe URL". Make
;; use-package's :ensure skip anything Emacs ships built-in.
;; `transient' is exempt: Emacs 30's bundled stub isn't the real package
;; (it is installed explicitly above).  eglot/eldoc/flymake/xref are
;; configured with `:ensure nil' (or skipped by this advice), so they
;; resolve to Emacs's own copies.
;; `package--builtin-versions' (part of the Emacs dump) only covers
;; built-ins with explicit version info; `package-built-in-p' itself
;; falls back to `package--builtins' (finder-inf) for the rest, and
;; some (server, saveplace, recentf, savehist, time, eww, css-mode,
;; the *-ts-mode modes, ...) aren't in either table.  So also check
;; whether the library resolves inside Emacs's own tree.
(defun my/elpaca-built-in-p (name)
  "Return non-nil if NAME is a package built into Emacs."
  (or (and (fboundp 'package-built-in-p) (package-built-in-p name))
      (and (boundp 'package--builtin-versions)
           (assq name package--builtin-versions))
      (and (boundp 'package--builtins)
           (assq name package--builtins))
      (let* ((lib (and data-directory
                       (locate-library (symbol-name name))))
             ;; data-directory is .../etc/; lisp is .../lisp/
             (lisp-dir (when data-directory
                         (file-name-as-directory
                          (expand-file-name "../lisp" data-directory))))
             ;; Fallback: derive lisp dir from a known built-in location
             ;; (e.g. simple.el.gz) if data-directory heuristic fails.
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
        ;; Treat as :ensure nil — process the remaining keywords only.
        (use-package-process-keywords name rest state)
      (funcall orig name _keyword ensure rest state)))
  (when (fboundp 'elpaca-use-package--handler)
    (advice-add #'use-package-handler/:ensure :around #'my/elpaca-skip-builtin)))

;; Early fallbacks for posframe.
;; `posframe-border-width' and `posframe-border' face are normally
;; defined in init-base.el's `use-package posframe' :init, but
;; init-hydra.el and init-ui.el (transient-posframe/hydra-posframe)
;; read them at load time via `posframe-border-width' in backquotes /
;; setqs and `:custom-face (posframe-border ...)'. If Elpaca's queue
;; fails early (e.g. compat void-variable) init-base never finishes, so
;; those reads void → "Symbol's value as variable is void:
;; posframe-border-width" / "Invalid face, posframe-border".
;; Define safe defaults here so they are always bound.
(defvar posframe-border-width 2
  "Default posframe border width. Overridden by init-base.el.")
(defface posframe-border '((t (:inherit region)))
  "Fallback face for posframe border. Overridden by init-base.el."
  :group 'posframe)

;; Silence "assignment to free variable" for the handful of built-ins
;; we tweak with setq before their package is loaded.
(setq use-package-expand-minimally nil
      use-package-compute-statistics nil) ; flip to t to profile startup

(provide 'my-elpaca)
;;; my-elpaca.el ends here

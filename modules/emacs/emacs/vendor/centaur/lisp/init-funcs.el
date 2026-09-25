;; init-funcs.el --- Define functions.	-*- lexical-binding: t -*-

;; Copyright (C) 2018-2026 Vincent Zhang

;; Author: Vincent Zhang <seagle0128@gmail.com>
;; URL: https://github.com/seagle0128/.emacs.d

;; This file is not part of GNU Emacs.
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
;;

;;; Commentary:
;;
;; Define some useful functions.
;;

;;; Code:

(require 'cl-lib)

;; Suppress warnings
(eval-when-compile
  (require 'init-const)
  (require 'init-custom))

(defvar socks-noproxy)
(defvar socks-server)

(declare-function apheleia-global-mode "apheleia")
(declare-function browse-url-file-url "browse-url")
(declare-function browse-url-interactive-arg "browse-url")
(declare-function chart-bar-quickie "chart")
(declare-function consult-theme "ext:consult")
(declare-function nerd-icons-install-fonts "ext:nerd-icons")
(declare-function winner-undo "winner")
(declare-function xwidget-buffer "xwidget")
(declare-function xwidget-webkit-current-session "xwidget")



;; Font
(defun font-available-p (font-name)
  "Check if font with FONT-NAME is available."
  (find-font (font-spec :name font-name)))

;; Dos2Unix/Unix2Dos
(defun dos2unix ()
  "Convert the current buffer to UNIX file format."
  (interactive)
  (set-buffer-file-coding-system 'undecided-unix nil))

(defun unix2dos ()
  "Convert the current buffer to DOS file format."
  (interactive)
  (set-buffer-file-coding-system 'undecided-dos nil))

(defun delete-dos-eol ()
  "Delete `^M' characters in current region or buffer.
Same as `replace-string' `C-q' `C-m' `RET' `RET'."
  (interactive)
  (save-excursion
    (save-restriction
      (when (region-active-p)
        (narrow-to-region (region-beginning) (region-end)))
      (goto-char (point-min))
      (let ((count 0))
        (while (search-forward "\r" nil t)
          (replace-match "" nil t)
          (setq count (1+ count)))
        (message "Removed %d carriage return characters." count)))))

;; File and buffer
(defun delete-this-file ()
  "Delete the current file, and kill the buffer."
  (interactive)
  (unless (buffer-file-name)
    (error "No file is currently being edited"))
  (when (yes-or-no-p (format "Really delete '%s'?"
                             (file-name-nondirectory buffer-file-name)))
    (delete-file (buffer-file-name))
    (kill-current-buffer)))

(defun rename-this-file (new-name)
  "Renames both current buffer and file it's visiting to NEW-NAME."
  (interactive "sNew name: ")
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (unless filename
      (error "Buffer '%s' is not visiting a file!" name))
    (progn
      (when (file-exists-p filename)
        (rename-file filename new-name 1))
      (set-visited-file-name new-name)
      (rename-buffer new-name))))

(defun browse-this-file ()
  "Open the current file as a URL using `browse-url'."
  (interactive)
  (require 'browse-url)
  (let ((file-name (buffer-file-name)))
    (unless file-name
      (user-error "Current buffer is not visiting a file"))
    (when (and (fboundp 'tramp-tramp-file-p)
               (tramp-tramp-file-p file-name))
      (error "Cannot open tramp file"))
    (browse-url (browse-url-file-url file-name))))

(defun create-scratch-buffer ()
  "Create a scratch buffer."
  (interactive)
  (switch-to-buffer (get-buffer-create "*scratch*"))
  (lisp-interaction-mode))

(defun revert-buffer-quick ()
  "Revert the current buffer without confirmation."
  (interactive)
  (revert-buffer nil t))

(defun save-buffer-as-utf8 (coding-system)
  "Revert a buffer with `CODING-SYSTEM' and save as UTF-8."
  (interactive "zCoding system for visited file (default nil):")
  (revert-buffer-with-coding-system coding-system)
  (set-buffer-file-coding-system 'utf-8)
  (save-buffer))

(defun save-buffer-gbk-as-utf8 ()
  "Revert a buffer with GBK and save as UTF-8."
  (interactive)
  (save-buffer-as-utf8 'gbk))

(defun selected-region-or-symbol-at-point ()
  "Return the selected region, otherwise return the symbol at point."
  (if (region-active-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    (thing-at-point 'symbol t)))

;; Browse URL
(defun xwidget-workable-p ()
  "Check whether xwidget is available."
  (and (display-graphic-p)
       (featurep 'xwidget-internal)))

(defun pinaceae-webkit-browse-url (url &optional pop-buffer new-session)
  "Browse URL with `xwidget-webkit' and switch or pop to the buffer.

POP-BUFFER specifies whether to pop to the buffer.
NEW-SESSION specifies whether to create a new xwidget-webkit session.
Interactively, URL defaults to the string looking like a url around point."
  (interactive (progn
                 (require 'browse-url)
                 (browse-url-interactive-arg "URL: ")))
  (xwidget-webkit-browse-url url new-session)
  (let ((buf (xwidget-buffer (xwidget-webkit-current-session))))
    (when (buffer-live-p buf)
      (and (eq buf (current-buffer)) (quit-window))
      (if pop-buffer
          (pop-to-buffer buf)
        (switch-to-buffer buf)))))

(defun pinaceae-browse-url (url)
  "Open URL using a configurable method.
See `browse-url' for more details."
  (interactive (progn
                 (require 'browse-url)
                 (browse-url-interactive-arg "URL: ")))
  (if (xwidget-workable-p)
      (pinaceae-webkit-browse-url url t)
    (browse-url url)))

(defun pinaceae-browse-url-of-file (&optional file)
  "Use a web browser to display FILE.
Display the current buffer's file if FILE is nil or if called
interactively.  Turn the filename into a URL with function
`browse-url-file-url'.  Pass the URL to a browser using the
`browse-url' function then run `browse-url-of-file-hook'."
  (interactive)
  (require 'browse-url)
  (setq file (or file (buffer-file-name)))
  (unless file
    (user-error "Current buffer is not visiting a file"))
  (if (xwidget-workable-p)
      (pinaceae-webkit-browse-url (browse-url-file-url file) t)
    (browse-url-of-file file)))

;; Reload configurations
(defun reload-init-file ()
  "Reload Emacs configurations."
  (interactive)
  (load user-init-file))
(defalias 'pinaceae-reload-init-file #'reload-init-file)

;; Browse the homepage
(defun browse-homepage ()
  "Browse the Github page of Pinaceae Emacs."
  (interactive)
  (browse-url pinaceae-homepage))

;; Open custom file
(defun find-custom-file ()
  "Open custom files.
If the custom file doesn't exist, copy the example file to create it.
Also opens the custom-post file in another window if it exists."
  (interactive)
  (unless (file-exists-p custom-file)
    (if (file-exists-p pinaceae-custom-example-file)
        (copy-file pinaceae-custom-example-file custom-file)
      (user-error "The file `%s' doesn't exist" pinaceae-custom-example-file)))
  (when (file-exists-p custom-file)
    (find-file custom-file))
  (when (file-exists-p pinaceae-custom-post-file)
    (find-file-other-window pinaceae-custom-post-file)))

;; Misc
(defun byte-compile-elpa ()
  "Compile packages in elpa directory. Useful if you switch Emacs versions."
  (interactive)
  (if (fboundp 'async-byte-recompile-directory)
      (async-byte-recompile-directory package-user-dir)
    (byte-recompile-directory package-user-dir 0 t)))

(defun byte-compile-site-lisp ()
  "Compile packages in site-lisp directory."
  (interactive)
  (let ((dir (locate-user-emacs-file "site-lisp")))
    (if (fboundp 'async-byte-recompile-directory)
        (async-byte-recompile-directory dir)
      (byte-recompile-directory dir 0 t))))

(defun native-compile-elpa ()
  "Native-compile packages in elpa directory."
  (interactive)
  (if (fboundp 'native-compile-async)
      (native-compile-async package-user-dir t)))

(defun native-compile-site-lisp ()
  "Native compile packages in site-lisp directory."
  (interactive)
  (let ((dir (locate-user-emacs-file "site-lisp")))
    (if (fboundp 'native-compile-async)
        (native-compile-async dir t))))

(defun icons-displayable-p ()
  "Return non-nil if icons are displayable."
  (and pinaceae-icon
       (or (featurep 'nerd-icons)
           (require 'nerd-icons nil t))))

(defun pinaceae-treesit-available-p ()
  "Check whether tree-sitter is available.

Native tree-sitter is built into 29.1+."
  (and pinaceae-tree-sitter
       (fboundp 'treesit-available-p)
       (treesit-available-p)))

(defun pinaceae-set-variable (variable value &optional no-save)
  "Set the VARIABLE to VALUE, and return VALUE.

If NO-SAVE is non-nil, don't save to the custom file.
This function both sets the variable in the current session and persists it to
the custom file."
  (customize-set-variable variable value)
  (when (and (not no-save)
             (file-writable-p custom-file))
    (with-temp-buffer
      (insert-file-contents custom-file)
      (goto-char (point-min))
      (while (re-search-forward
              (format "^[\t ]*[;]*[\t ]*(setq %s .*)" variable)
              nil t)
        (replace-match (format "(setq %s '%s)" variable value) nil nil))
      (write-region nil nil custom-file)
      (message "Saved %s (%s) to %s" variable value custom-file))))

(defun file-too-big-p ()
  "Check whether the file is too big.

Returns non-nil if the buffer size exceeds 999,999 bytes or has more than 10,000
lines, or more than 2,000 bytes in one line."
  (or (> (buffer-size) 999999)
      (and (fboundp 'buffer-line-statistics)
           (let ((statics (buffer-line-statistics)))
             (or (> (car statics) 10000)
                 (> (cadr statics) 2000))))))

(define-minor-mode pinaceae-read-mode
  "Minor Mode for better reading experience."
  :init-value nil
  :group pinaceae
  (if pinaceae-read-mode
      (progn
        (and (fboundp 'olivetti-mode) (olivetti-mode 1))
        (and (fboundp 'mixed-pitch-mode) (mixed-pitch-mode 1))
        (text-scale-set +1))
    (progn
      (and (fboundp 'olivetti-mode) (olivetti-mode -1))
      (and (fboundp 'mixed-pitch-mode) (mixed-pitch-mode -1))
      (text-scale-set 0))))

;; Package repository (ELPA)
(defun set-package-archives (archives &optional refresh async no-save)
  "Set the package ARCHIVES (ELPA).

If REFRESH is non-nil, refresh the package contents.  If ASYNC is non-nil,
perform the refresh in the background.  Save the setting to `custom-file'
if NO-SAVE is nil.  This function updates `pinaceae-package-archives'."
  (interactive
   (list
    (intern
     (completing-read "Select package archives: "
                      (mapcar #'car pinaceae-package-archives-alist)))))
  ;; Set option
  (pinaceae-set-variable 'pinaceae-package-archives archives no-save)

  ;; Refresh if need
  (and refresh (package-refresh-contents async))

  (message "Set package archives to `%s'" archives))
(defalias 'pinaceae-set-package-archives #'set-package-archives)

;; Refer to https://emacs-china.org/t/elpa/11192
(defun pinaceae-test-package-archives (&optional no-chart)
  "Test connection speed of all package archives and display on chart.

Not displaying the chart if NO-CHART is non-nil.
Return the fastest package archive."
  (interactive)

  (let* ((durations (mapcar
                     (lambda (pair)
                       (let ((url (concat (cdr (nth 2 (cdr pair)))
                                          "archive-contents"))
                             (start (current-time)))
                         (message "Fetching %s..." url)
                         (ignore-errors
                           (url-copy-file url null-device t))
                         (float-time (time-subtract (current-time) start))))
                     pinaceae-package-archives-alist))
         (fastest (car (nth (cl-position (apply #'min durations) durations)
                            pinaceae-package-archives-alist))))

    ;; Display on chart
    (when (and (not no-chart)
               (require 'chart nil t)
               (require 'url nil t))
      (chart-bar-quickie
       'vertical
       "Speed test for the ELPA mirrors"
       (mapcar (lambda (p) (symbol-name (car p))) pinaceae-package-archives-alist)
       "ELPA"
       (mapcar (lambda (d) (* 1e3 d)) durations) "ms"))

    (message "`%s' is the fastest package archive" fastest)

    ;; Return the fastest
    fastest))

(defun set-from-minibuffer (sym)
  "Set SYM value from minibuffer."
  (eval-expression
   (minibuffer-with-setup-hook
       (lambda ()
         (run-hooks 'eval-expression-minibuffer-setup-hook)
         (goto-char (minibuffer-prompt-end))
         (forward-char (length (format "(setq %S " sym))))
     (read-from-minibuffer
      "Eval: "
      (let ((sym-value (symbol-value sym)))
        (format
         (if (or (consp sym-value)
                 (and (symbolp sym-value)
                      (not (null sym-value))
                      (not (keywordp sym-value))))
             "(setq %s '%S)"
           "(setq %s %S)")
         sym sym-value))
      read-expression-map t
      'read-expression-history))))



;; Update
(defun update-config ()
  "Update Pinaceae Emacs configurations to the latest version."
  (interactive)
  (unless (file-exists-p pinaceae-homepage)
    (user-error "\"%s\" doesn't exist" pinaceae-homepage))
  (message "Updating configurations...")
  (cd pinaceae-homepage)
  (shell-command "git pull")
  (message "Updating configurations...done"))
(defalias 'pinaceae-update-config #'update-config)

(defun update-packages ()
  "Update all packages (via Elpaca when available)."
  (interactive)
  (message "Updating packages...")
  (and (fboundp 'apheleia-global-mode) (apheleia-global-mode -1))
  (if (fboundp 'elpaca-update-all)
      (elpaca-update-all)
    (package-upgrade-all))
  (and (fboundp 'apheleia-global-mode) (apheleia-global-mode 1))
  (message "Updating packages...done"))
(defalias 'pinaceae-update-packages #'update-packages)

(defun update-config-and-packages ()
  "Update configurations and packages."
  (interactive)
  (update-config)
  (update-packages))
(defalias 'pinaceae-update #'update-config-and-packages)

(defun update-dotfiles ()
  "Update the dotfiles to the latest version."
  (interactive)
  (let ((dir (or (getenv "DOTFILES")
                 (expand-file-name "~/.dotfiles/"))))
    (if (file-exists-p dir)
        (progn
          (message "Updating dotfiles...")
          (cd dir)
          (shell-command "git pull")
          (message "Updating dotfiles...done"))
      (message "\"%s\" doesn't exist" dir))))
(defalias 'pinaceae-update-dotfiles #'update-dotfiles)

(defun update-org ()
  "Update Org files to the latest version."
  (interactive)
  (let ((dir (expand-file-name "~/org/")))
    (if (file-exists-p dir)
        (progn
          (message "Updating org files...")
          (cd dir)
          (shell-command "git pull")
          (message "Updating org files...done"))
      (message "\"%s\" doesn't exist" dir))))
(defalias 'pinaceae-update-org #'update-org)

(defun update-all ()
  "Update dotfiles, org files, configurations and packages to the latest."
  (interactive)
  (update-org)
  (update-dotfiles)
  (update-config-and-packages))
(defalias 'pinaceae-update-all #'update-all)


;; Fonts
(defun pinaceae-install-fonts ()
  "Install necessary fonts."
  (interactive)
  (nerd-icons-install-fonts))



;; UI
(defvar after-load-theme-hook nil
  "Hook run after a color theme is loaded using `load-theme'.")
(defun run-after-load-theme-hook (&rest _)
  "Run `after-load-theme-hook'."
  (run-hooks 'after-load-theme-hook))

(if (boundp 'enable-theme-functions)    ; Introduced in 29.1
    (add-hook 'enable-theme-functions #'run-after-load-theme-hook)
  (advice-add #'load-theme :after #'run-after-load-theme-hook))

(defun childframe-workable-p ()
  "Whether childframe is workable."
  (and (>= emacs-major-version 26)
       (not noninteractive)
       (not emacs-basic-display)
       (or (display-graphic-p)
           (featurep 'tty-child-frames))
       (eq (frame-parameter (selected-frame) 'minibuffer) 't)))

(defun childframe-completion-workable-p ()
  "Whether childframe completion is workable."
  (and (eq pinaceae-completion-style 'childframe)
       (childframe-workable-p)))

(defun pinaceae-dark-theme-p ()
  "Check if the current theme is a dark theme."
  (eq (frame-parameter nil 'background-mode) 'dark))

(defun pinaceae-load-theme (&optional _theme _no-save)
  "Load the `pinaceae' theme.

THEME and NO-SAVE are accepted for compatibility with the old
Centaur API; Pinaceae Emacs has a single matugen-generated
theme (themes/pinaceae-theme.el), so they are ignored."
  (interactive)
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme 'pinaceae t))



;; Window

;; Rearrange split windows
(defun split-window-horizontally-instead ()
  "Split side-by-side, keeping the other window's buffer.
Kills other windows first, then splits left/right."
  (interactive)
  (let* ((next-window (next-window))
         (other-buffer (and next-window (window-buffer next-window)))
         (new-window nil))
    (delete-other-windows)
    (setq new-window (split-window-horizontally))
    (when other-buffer
      (set-window-buffer new-window other-buffer))))

(defun split-window-vertically-instead ()
  "Split stacked, keeping the other window's buffer.
Kills other windows first, then splits top/bottom."
  (interactive)
  (let* ((next-window (next-window))
         (other-buffer (and next-window (window-buffer next-window)))
         (new-window nil))
    (delete-other-windows)
    (setq new-window (split-window-vertically))
    (when other-buffer
      (set-window-buffer new-window other-buffer))))

(defun pinaceae-split-window-toggle ()
  "Toggle a two-window frame between side-by-side and stacked."
  (interactive)
  (unless (= (count-windows) 2)
    (user-error "Need exactly 2 windows to toggle"))
  (let* ((win1 (selected-window))
         (win2 (next-window win1))
         (buf1 (window-buffer win1))
         (buf2 (window-buffer win2))
         (edges2 (window-edges win2))
         ;; Same top edge means the windows sit next to each other.
         (side-by-side (= (nth 1 (window-edges win1)) (nth 1 edges2))))
    (delete-other-windows win1)
    (if side-by-side
        (split-window-vertically)
      (split-window-horizontally))
    (set-window-buffer (next-window win1) buf2)
    (select-window win1)
    (set-window-buffer win1 buf1)))



;; Frame
(defvar pinaceae-frame--geometry nil)
(defun pinaceae-frame--save-geometry ()
  "Save current frame's geometry."
  (setq pinaceae-frame--geometry
        `((left   . ,(frame-parameter nil 'left))
          (top    . ,(frame-parameter nil 'top))
          (width  . ,(frame-parameter nil 'width))
          (height . ,(frame-parameter nil 'height))
          (fullscreen . ,(frame-parameter nil 'fullscreen)))))

(defun pinaceae-frame--fullscreen-p ()
  "Return non-nil if the frame is fullscreen or maximized."
  (memq (frame-parameter nil 'fullscreen) '(fullscreen fullboth maximized)))

(defun pinaceae-frame-maximize ()
  "Maximize the frame."
  (interactive)
  (unless (eq (frame-parameter nil 'fullscreen) 'maximized)
    (pinaceae-frame--save-geometry)
    (set-frame-parameter nil 'fullscreen 'maximized)))

(defun pinaceae-frame-restore ()
  "Restore the frame's size and position."
  (interactive)
  (modify-frame-parameters nil pinaceae-frame--geometry))

(defun pinaceae-frame-left-half ()
  "Put the frame to the left-half."
  (interactive)
  (unless (pinaceae-frame--fullscreen-p)
    (pinaceae-frame--save-geometry)
    (let* ((attr (frame-monitor-workarea))
           (width (- (/ (nth 2 attr) 2) 20))
           (height (- (nth 3 attr) 30))
           (left (nth 0 attr))
           (top (nth 1 attr)))
      (set-frame-parameter nil 'fullscreen nil)
      (set-frame-position nil left top)
      (set-frame-size nil width height t))))

(defun pinaceae-frame-right-half ()
  "Put the frame to the right-half."
  (interactive)
  (unless (pinaceae-frame--fullscreen-p)
    (pinaceae-frame--save-geometry)
    (let* ((attr (frame-monitor-workarea))
           (width (- (/ (nth 2 attr) 2) 20))
           (height (- (nth 3 attr) 30))
           (left (+ (nth 0 attr) width 20))
           (top (nth 1 attr)))
      (set-frame-parameter nil 'fullscreen nil)
      (set-frame-position nil left top)
      (set-frame-size nil width height t))))

(defun pinaceae-frame-top-half ()
  "Put the frame to the top-half."
  (interactive)
  (unless (pinaceae-frame--fullscreen-p)
    (pinaceae-frame--save-geometry)
    (let* ((attr (frame-monitor-workarea))
           (width (- (nth 2 attr) 20))
           (height (- (/ (nth 3 attr) 2) 30))
           (left (nth 0 attr))
           (top (nth 1 attr)))
      (set-frame-parameter nil 'fullscreen nil)
      (set-frame-position nil left top)
      (set-frame-size nil width height t))))

(defun pinaceae-frame-bottom-half ()
  "Put the frame to the bottom-half."
  (interactive)
  (unless (pinaceae-frame--fullscreen-p)
    (pinaceae-frame--save-geometry)
    (let* ((attr (frame-monitor-workarea))
           (width (- (nth 2 attr) 20))
           (height (- (/ (nth 3 attr) 2) 30))
           (left (nth 0 attr))
           (top (+ (nth 1 attr) height 30)))
      (set-frame-parameter nil 'fullscreen nil)
      (set-frame-position nil left top)
      (set-frame-size nil width height t))))

(defun pinaceae-recover-layout ()
  "Recover window layout."
  (cond
   ((bound-and-true-p tab-bar-history-mode)
    (tab-bar-history-back))
   ((bound-and-true-p winner-mode)
    (winner-undo))
   (t (user-error "Unable to recover layout"))))



;; Network Proxy
(defun show-http-proxy ()
  "Show HTTP/HTTPS proxy."
  (interactive)
  (if url-proxy-services
      (message "Current HTTP proxy is `%s'" pinaceae-proxy)
    (message "No HTTP proxy")))

(defun enable-http-proxy ()
  "Enable HTTP/HTTPS proxy."
  (interactive)
  (setq url-proxy-services
        `(("http" . ,pinaceae-proxy)
          ("https" . ,pinaceae-proxy)
          ("no_proxy" . "^\\(localhost\\|192.168.*\\|10.*\\)")))
  (show-http-proxy))

(defun disable-http-proxy ()
  "Disable HTTP/HTTPS proxy."
  (interactive)
  (setq url-proxy-services nil)
  (show-http-proxy))

(defun toggle-http-proxy ()
  "Toggle HTTP/HTTPS proxy."
  (interactive)
  (if (bound-and-true-p url-proxy-services)
      (disable-http-proxy)
    (enable-http-proxy)))

(defun show-socks-proxy ()
  "Show SOCKS proxy."
  (interactive)
  (if (bound-and-true-p socks-noproxy)
      (message "Current SOCKS%d proxy is %s:%s"
               (cadddr socks-server) (cadr socks-server) (caddr socks-server))
    (message "No SOCKS proxy")))

(defun enable-socks-proxy ()
  "Enable SOCKS proxy."
  (interactive)
  (require 'socks)
  (setq url-gateway-method 'socks
        socks-noproxy '("localhost"))
  (let* ((proxy (split-string pinaceae-socks-proxy ":"))
         (host (car proxy))
         (port (string-to-number (cadr proxy))))
    (setq socks-server `("Default server" ,host ,port 5)))
  (setenv "all_proxy" (concat "socks5://" pinaceae-socks-proxy))
  (show-socks-proxy))

(defun disable-socks-proxy ()
  "Disable SOCKS proxy."
  (interactive)
  (setq url-gateway-method 'native
        socks-noproxy nil
        socks-server nil)
  (setenv "all_proxy" "")
  (show-socks-proxy))

(defun toggle-socks-proxy ()
  "Toggle SOCKS proxy."
  (interactive)
  (if (bound-and-true-p socks-server)
      (disable-socks-proxy)
    (enable-socks-proxy)))

(defun enable-proxy ()
  "Enable proxy."
  (interactive)
  (enable-http-proxy)
  (enable-socks-proxy))

(defun disable-proxy ()
  "Disable proxy."
  (interactive)
  (disable-http-proxy)
  (disable-socks-proxy))

(defun toggle-proxy ()
  "Toggle proxy."
  (interactive)
  (toggle-http-proxy)
  (toggle-socks-proxy))

(provide 'init-funcs)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-funcs.el ends here

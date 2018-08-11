;; package-stuff
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives '("gnu" . (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)

;; IMPORTANT binding on mac osx
(setq mac-command-modifier 'ctrl)
(setq mac-option-modifier 'meta)

;; backup path
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

;; org dir
(defvar org-dir "~/org/")
(defvar init-file nil  "init file")
(setq init-file "~/.emacs")
(setq initial-buffer-choice init-file)

;; setting the path env variable
(setenv "PATH"
	(concat (getenv "PATH") ":/usr/local/bin" ":/Library/TeX/texbin"))
(setq exec-path (append exec-path '("/usr/local/bin")))

;; yes or no -> y-or-n
(fset 'yes-or-no-p 'y-or-n-p)

;; load-path
(mapc #'(lambda (path)
            (add-to-list 'load-path
                         (expand-file-name path user-emacs-directory)))
        '("custom_lisp" "lib"))

(use-package diminish
  :ensure t)

(use-package ivy
  :ensure t
  :diminish ivy-mode
  :config
  (ivy-mode 1)
  (use-package swiper
    :ensure t
    :bind
    ("C-r" . swiper)
    ("C-s" . swiper)
    )
  (use-package counsel
    :ensure t
    :bind
    ("M-x" . counsel-M-x)
    )
  (setq ivy-re-builders-alist
	'((read-file-name-internal . ivy--regex-fuzzy)
	  (t . ivy--regex-plus)))
  
  ;; ("C-c C-r" . ivy-resume)
  )

(if (display-graphic-p)
    (progn
      (setq visible-bell nil)
      (setq ring-bell-function 'ignore)
      (tool-bar-mode 0)
      (menu-bar-mode 0)
      (scroll-bar-mode 0)
      (fringe-mode -1)

      ;; bigger frame at startup
     (add-to-list 'default-frame-alist '(height . 80))
;      (setq mac-allow-anti-aliasing nil)
      (add-to-list 'default-frame-alist '(font . "Menlo-13"))
      (add-to-list 'default-frame-alist '(width . 120))))

(use-package org
  :mode (("\\.txt$" . org-mode)
	 ("\\.org$" . org-mode)
	 (".*/[0-9]*$" . org-mode))
  :config
  (setq org-fontify-emphasized-text t)
  (use-package org-bullets
    :ensure t
    :config
    (org-bullets-mode t)
    )
  (setq org-agenda-files
;;	if a file doesn't exists it is deleted from the list
	;; (delq nil
	;;       (mapcar (lambda (x) (and (file-exists-p x) x))
	;; 	      '("~/org/tasks.org"))))
	(list "~/org/schedule.org"))
	
  (setq org-return-follows-link t)
  :bind
  (:map org-mode-map
	("C-c C-r" . org-capture)
	))

;; ibuffer 
(use-package ibuffer
  :config
  (add-hook 'ibuffer-mode-hook
	    (lambda () (hl-line-mode 1)))

  (require 'ibuf-ext)
;  (add-to-list 'ibuffer-never-show-predicates "^\\*[^iM]")
  
  (setq ibuffer-saved-filter-groups
	(quote (("default"
		 ("dired" (mode . dired-mode))
		 ("org" (mode . org-mode))
		 ("web" (or (mode . eww-mode) (mode . w3m-mode)))
		 ("shell" (or (mode . eshell-mode) (mode . shell-mode)))
		 ("elisp" (or (mode . emacs-lisp-mode) (mode . inferior-emacs-lisp-mode)))
		 ("Torrent" (mode . transmission-files-mode))
		 ("LaTeX" (mode . LaTeX/P))
		 ("Python" (mode . python-mode))
		 ("C/C++" (mode . cc-mode))
		 ("Doc" (mode . doc-view-mode))		 		 
		 ("man" (or (name . "*Man")
			    (mode . WoMan-mode)))
		 ))))
  (add-hook 'ibuffer-mode-hook
	    (lambda ()
	      (ibuffer-auto-mode 1)
	      (ibuffer-switch-to-saved-filter-groups "default")))
  ;; Don't show filter groups if there are no buffers in that group
  (setq ibuffer-show-empty-filter-groups nil)

  ;; Don't ask for confirmation to delete marked buffers
  (setq ibuffer-expert t)

  ; collapse default buffers
  (setq mp/ibuffer-collapsed-groups (list "Dired" "Default"))

  (defadvice ibuffer (after collapse-helm)
    (dolist (group mp/ibuffer-collapsed-groups)
      (progn
	(goto-char 1)
	(when (search-forward (concat "[ " group " ]") (point-max) t)
	  (progn
	    (move-beginning-of-line nil)
	    (ibuffer-toggle-filter-group)
	    )
	  )
	)
      )
    (goto-char 1)
    (search-forward "[ " (point-max) t)
    )

  (ad-activate 'ibuffer)

  (defun my-ibuffer-recent-buffer (old-ibuffer &rest arguments) ()
         "Open ibuffer with cursor pointed to most recent buffer name"
         (let ((recent-buffer-name (buffer-name)))
           (apply old-ibuffer arguments)
           (ibuffer-jump-to-buffer recent-buffer-name)))
  
  (advice-add #'ibuffer :around #'my-ibuffer-recent-buffer)
  
  :bind
  (("C-x C-b" . ibuffer))
  )
;; dired
(use-package dired  
  :preface
  (defun dired-show-hidden ()(dired-read-dir-and-switches "-la"))
  :config
  ;; (use-package dired-sort
  ;;   :ensure t
  ;;   )
  (use-package dired-collapse
    :ensure t
    )
  (add-hook 'dired-load-hook (lambda()("dired-x")))
  (add-hook 'dired-mode-hook (lambda()(hl-line-mode t)))
  (add-hook 'dired-mode-hook 'dired-collapse-mode)
  (setq dired-listing-switches "-l")
  (setq dired-guess-shell-alist-user
	(list
	 (list "\\.mp4$" "open -a vlc")
	 (list "\\.mkv$" "open -a vlc")
	 (list "\\.torrent$" "transmission-remote -a")
	 (list "\\.pdf$" "open -a pdfguru"))
	)
  :bind
  (:map dired-mode-map
	("M-u" . dired-up-directory)
	("M-t" . dired-show-hidden)
	("M-r" . dired-do-shell-command)
	("M-g" . dired-filter-group-mode))
  )

;; command tree
(use-package undo-tree
  :ensure t
  :diminish undo-tree-mode
  :config
  (global-undo-tree-mode)
  :bind
  (("C-c C-z" . undo-tree-visualize)))

(use-package guide-key
  :ensure t
  :diminish guide-key-mode
  :config
  (guide-key-mode 1)
  (add-to-list 'guide-key/guide-key-sequence '("C-c p" "C-x r"))
  (custom-set-faces
   '(guide-key/highlight-command-face ((t (:background "navy" :foreground "gold"))))
   '(guide-key/key-face ((t (:foreground "cyan4")))))
  )

(use-package projectile
  :ensure t
  :diminish projectile-mode
  :config
  (projectile-mode 1)
  )

;; keychord
(use-package key-chord
  :ensure t
  :preface
  :config
  (require 'key-chord)
  (key-chord-mode 1)
  
  (setq key-chord-two-keys-delay 0.1)
  (setq key-chord-one-key-delay 0.2)
  
  )

(use-package company
  :ensure t
  :diminish company-mode
  :init 
  (global-company-mode)
  :config
  (setq company-idle-delay              nil
	company-minimum-prefix-length   2
	company-show-numbers            t
	company-tooltip-limit           20
	company-dabbrev-downcase        nil
	company-backends                '((company-irony))
	)
  (use-package company-c-headers
    :ensure t
    :config
    (add-to-list 'company-backends 'company-c-headers)
    )
  (use-package semantic
    :ensure t
    :diminish semantic-mode
    :config
    (add-hook 'c++-mode-hook (lambda()(semantic-mode 1)))
    (semantic-add-system-include "/Library/Developer/CommandLineTools/usr/include" 'c++-mode)
    (semantic-add-system-include "/usr/local/Cellar/boost/1.64.0_1/include")
        (semantic-add-system-include "/usr/local/include/range/")
    (add-hook 'semantic-init-hooks
	      'semantic-reset-system-include)
    )
  )

(use-package irony
  :ensure t
  :diminish irony-mode
  :config
  (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
  (add-hook 'irony-mode-hook 'company-irony-setup-begin-commands)
  (add-to-list 'company-backends 'company-irony)
)

(use-package cc-mode
  :mode (("\\.h\\(h?\\|xx\\|pp\\)\\'" . c++-mode)
         ("\\.m\\'"                   . c-mode)
         ("\\.mm\\'"                  . c++-mode))
  :bind
  (("C-c C-c" . compile))
  )


;; (use-package rtags
;;   :ensure t
;;   :init
;;   (add-hook 'c-mode-hook 'rtags-start-process-unless-running)
;;   (add-hook 'c++-mode-hook 'rtags-start-process-unless-running))

(use-package magit
  :ensure t
  
  :bind
  ("C-x g" . magit-status))

(use-package perl
  :mode ("\\.\\([pP][Llm]\\|al\\)\\'" . cperl-mode)
  :interpreter (("perl" . cperl-mode)
		("perl5" . cperl-mode)
		("miniperl" . cperl-mode))
  )

(use-package beacon
  :ensure t
  :config
  (beacon-mode 1))


(use-package smartparens
  :ensure t
  :diminish smartparens-mode
  :config
  (require 'smartparens-config)
  (add-hook 'c++-mode-hook #'smartparens-mode)
  (add-hook 'emacs-lisp-mode-hook #'smartparens-mode)
  )

(use-package align
  :ensure t
  :bind (("M-["   . align-code)
         ("C-c [" . align-regexp))
  :commands align
  :preface
  (defun align-code (beg end &optional arg)
    (interactive "rP")
    (if (null arg)
        (align beg end)
      (let ((end-mark (copy-marker end)))
        (indent-region beg end-mark nil)
        (align beg end-mark)))))

(use-package auctex
  :ensure t
  :mode ("\\.tex\\'" . TeX-latex-mode)
  :preface
  :config
  
  (require 'key-chord)
  (key-chord-define TeX-mode-map "hh" (lambda()(progn (insert "{}")(backward-char))))
  (key-chord-define TeX-mode-map "qq" (lambda()(progn (insert "$$")(backward-char))))
  (key-chord-define TeX-mode-map "kk" (lambda()(progn (insert "\\{\\}")(backward-char))))
  
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq-default TeX-master nil)
  (add-hook 'TeX-mode-hook 'visual-line-mode)
  (add-hook 'TeX-mode-hook 'LaTeX-math-mode)
  (add-hook 'TeX-mode-hook 'abbrev-mode)
  (setq TeX-engine 'pdflatex)
  (setq TeX-PDF-mode t)
  (setq LaTeX-math-abbrev-prefix (kbd "'"))
  (add-hook 'LaTeX-mode-hook 'key-chord-latex)
  )

;; ;; misc
;; ;; initial files 
;; (mapc #'(lambda (file) 
;; 	  (if (file-exists-p file)
;; 	      (find-file file)))
;;       '("~/.emacs.d/init.el" "~/org/tasks.org"))
;; (if (file-exists-p user-init-file)
;;     (setq initial-buffer-choice "~/org/tasks.org"))

;; garbage collector every 100 MB to improve performance
(setq gc-cons-threshold 100000000)

(use-package ace-window
  :ensure t
  :diminish ace-window-mode
  :config
  (setq aw-ignore-on t)
  (setq aw-keys '(?c ?n ?p ?s ?d ?e ?j ?k ?l))
  (defvar aw-dispatch-alist
    '((?x aw-delete-window " Ace - Delete Window")
      (?m aw-swap-window " Ace - Swap Window")
      (?n aw-flip-window)
      (?v aw-split-window-vert " Ace - Split Vert Window")
      (?b aw-split-window-horz " Ace - Split Horz Window")
      (?i delete-other-windows " Ace - Maximize Window")
      (?o delete-other-windows))
    "List of actions for `aw-dispatch-default'.")
  :bind
  (("M-o" . ace-window)))

(use-package multiple-cursors
  :ensure t
  :diminish multiple-cursors-mode
  :bind
  (("C->" . mc/mark-next-like-this)
   ("C-<" . mc/mark-previous-like-this)
   ("C-c C-<" . mc/mark-all-like-this))
  )

(use-package flycheck
  :ensure t
  :diminish flycheck-mode
  :init
  (global-flycheck-mode)
  :config
  (setq flycheck-clang-language-standard "c++11")
  (use-package flycheck-irony
    :ensure t
    :config
    (add-hook 'flycheck-mode-hook #'flycheck-irony-setup)
    )
  )

(use-package flyspell
  :ensure t
  :diminish flyspell-mode
  :config
  (add-hook 'c++-mode-hook (lambda()(flyspell-prog-mode)))
  :bind
  ("M-<f8>" . flyspell-check-next-highlighted-word)
  )

(use-package auctex
  :load-path "elpa/auctex"
  :mode ("\\.tex\\'" . TeX-latex-mode)
  :config
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq-default TeX-master nil)

  (add-hook 'LaTeX-mode-hook 'visual-line-mode)
  (add-hook 'LaTeX-mode-hook 'flyspell-mode)
  (add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)
  (setq TeX-PDF-mode t)
  )

(use-package org-gcal
  :ensure t
  :config
  (require 'org-gcal)
  (setq org-gcal-client-id ""
	org-gcal-client-secret ""
	org-gcal-file-alist '(("" . "")
                              ))
  (add-hook 'org-agenda-mode-hook (lambda () (org-gcal-sync) ))
  (add-hook 'org-capture-after-finalize-hook (lambda () (org-gcal-sync) ))
  )

;; (use-package doc-view-mode
;;   :config
;;   (setq doc-view-ghostscript-program "/usr/local/bin/gs")
;;   )

(defun dired-home ()
  "open dired buffer in ~"
  (interactive)
  (split-window-vertically (/ (window-total-height) 2))
  (other-window 1)
  (dired "~")
  )

(defun eshell-here ()
  "open eshell"
  (interactive)
  (let* ((height (/ (window-total-height) 3)))
    (split-window-vertically (- height))
    (other-window 1)
    (eshell)
    ))

(defvar utility-mode-map nil
  "custom map for various uses")
(setq utility-mode-map
      (let ((map (make-sparse-keymap)))
	(define-key map "\C-q" #'delete-window)
	(define-key map "\C-s" 'eshell-here)
	(define-key map "\C-d" 'dired-home)
	(define-key map "\C-f" #'toggle-frame-fullscreen)
	map))

(global-set-key "\C-q" utility-mode-map)
(global-set-key "\M-o" 'ace-window)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(guide-key/highlight-command-face ((t (:background "navy" :foreground "gold"))))
 '(guide-key/key-face ((t (:foreground "cyan4"))))
 '(mode-line ((t (:background "grey75" :foreground "black")))))

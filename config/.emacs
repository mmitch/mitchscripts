;; set usable font (otherwise default Ubuntu install comes up with a Comic Sans lookalike - YUCK!)
(set-face-attribute 'default nil :font "-efont-fixed-medium-r-normal-*-14-140-75-75-c-70-iso10646-1")

;; don't show startup screen
(setq inhibit-startup-screen t)

;; don't show toolbar (only relevant for grpahical emacs; emacs-nox b0rks on this!)
(when (display-graphic-p)
  (tool-bar-mode -1))

;; don't show menubar
(menu-bar-mode -1)

;; light-on-dark-theme
(invert-face 'default)

;; don't show tooltips
(setq x-gtk-use-system-tooltips nil)

;; auto-modeselect for Markdown documents
(setq auto-mode-alist (cons '("\\.md\\'" . markdown-mode) auto-mode-alist))

;; try to find nice C identation/formatting
(setq c-default-style "linux"
      c-basic-offset 4)

;; org-mode keybindings
(require 'org)
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)

;; black on white
(invert-face 'default)

;; automatic mode selections
(setq auto-mode-alist
      (append
       '( (".*/mutt.*$" . auto-fill-mode)
	  (".*letter.*$" . auto-fill-mode)
	  (".*article.*$" . auto-fill-mode)
	  )
       auto-mode-alist))

;; build a unique "theme" just to fix some things in console mode
;; activate only in console mode
(unless (display-graphic-p)

  ;; this is a good base theme
  (load-theme 'manoj-dark)

  (custom-theme-set-faces
   'manoj-dark

   ;; bright bold red on medium gray is hard to read
   `(mode-line-buffer-id ((t (:foreground "Wheat" :background "grey30"))))
   ;; minor tweak
   `(mode-line ((t (:foreground "grey90" :background "grey20"))))

   ;; bright background is irritating
   `(diff-header ((t (:background "grey10"))))

   )
  )

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files (quote ("~/Cryptbox/TODO")))
 '(org-babel-load-languages (quote ((emacs-lisp . t) (perl . t))))
 '(org-confirm-babel-evaluate nil)
 '(org-html-doctype "html5"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

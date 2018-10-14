;;; .emacs --- personal Emacs configuration

;;; Commentary:
;; none, but I want to keep flycheck happy

;; TODO:
;; - iterate through all faces and change weight normal -> light and bold -> normal
;; - set-face:: '(mode-line ((t (:background "orange4" :foreground "black" :box (:line-width -1 :style released-button)))))
;; - look for TODO below

;;; Code:

;;;
;;; packages and repositores
;;;

;; use MELPA/ORG
(require 'package)
; (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
(package-initialize)

;; TODO: is this needed?
; (add-to-list 'load-path "~/.emacs.d/lisp/")

;;;
;;; global emacs configuration
;;;

;; don't show startup screen
(setq inhibit-startup-screen t)

;; don't show toolbar (only relevant for graphical emacs; emacs-nox b0rks on this!)
(when (display-graphic-p)
  (tool-bar-mode -1))

;; don't show menubar
(menu-bar-mode -1)

;; don't show tooltips
(setq x-gtk-use-system-tooltips nil)

;; Line numbering
;(require 'nlinum)
;(global-linum-mode 1)
;(setq linum-format "%4d\u2502")

;; Show line- and column-number in the mode line
(line-number-mode 1)
(column-number-mode 1)

;; highlight current line
;(global-hl-line-mode 1)
;(set-face-background 'hl-line "#033")

;; highlight matching parens
(show-paren-mode 1)

;;;
;;; mutt + tin integration
;;;

(setq auto-mode-alist
      (append
       '(("/mutt-" . mail-mode)
	 ("/\\.letter\\." . mail-mode)
	 ("/\\.article\\." . mail-mode))
       auto-mode-alist))

(add-hook 'mail-mode-hook 'turn-on-auto-fill)

;;;
;;; ido
;;;

(require 'ido)
(ido-mode t)

;;;
;;; flycheck
;;;

;; enable Flycheck when installed
(when (require 'flycheck nil :noerror)
  (add-hook 'after-init-hook #'global-flycheck-mode))

;;;
;;; use emacs to edit <textarea>s in Firefox
;;;

;; skip when not installed
(when (require 'atomic-chrome nil :noerror)
  (atomic-chrome-start-server)
  (setq atomic-chrome-buffer-open-style 'frame))

;;;
;;; org-mode
;;;

;; org-mode keybindings
(require 'org)
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)

;;;
;;; theme for both console and X11
;;;

(defvar my:theme-console-loaded nil)
(defvar my:theme-windowed-loaded nil)
(defun my:set-theme (windowed)
  "Set theme and font.
WINDOWED is t if running under X11"
  (if windowed
      ;; set theme for X
      (progn
	;; use Efont Fixed bitmap font
	;; - on Debian/Ubuntu, install xfonts-efont-unicode and xfonts-efont-unicode-ib
	;; - on Ubuntu, you need to enable bitmap fonts:
	;;   - either remove /etc/fonts/conf.d/70-no-bitmaps.conf
	;;   - or selectively enable only the efont font to minimize side effects,
	;;     see https://github.com/mmitch/vater/blob/master/README.md for an example
	(set-face-attribute 'default nil :family "BiWidth")
	
	(unless my:theme-windowed-loaded
	  (progn
	    ;; don't use Monospace for fixed-pitch, our default is already fixed-pitch
	    (set-face-attribute 'fixed-pitch nil :family 'unspecified)

	    ;; remember this and only change the weights once
	    (setq my:theme-windowed-loaded t))))
  
    ;; set console theme
    (if my:theme-console-loaded
	;; if theme is already defined, just use it
	(enable-theme 'manoj-dark)
      (progn
	;; build a unique "theme" just to fix some things in console mode
	
	;; this is a good base theme
	(load-theme 'manoj-dark)
	
	;; add own customizations on top
	(custom-theme-set-faces
	 'manoj-dark
	 
	 ;; bright bold red on medium gray is hard to read
	 `(mode-line-buffer-id ((t (:foreground "Wheat" :background "grey30"))))
	 ;; minor tweak
	 `(mode-line ((t (:foreground "grey90" :background "grey20"))))
	 
	 ;; bright background is irritating
	 `(diff-header ((t (:background "grey10"))))
	 )
	
	;; remember this and only define the theme once
	(setq my:theme-console-loaded t)))))

;; apply theme correctly both standalone and with daemon/emacsclient
(if (daemonp)
    (add-hook 'after-make-frame-functions(lambda (frame)
					   (select-frame frame)
					   (my:set-theme (window-system frame))))
  (add-hook 'after-init-hook (lambda () (my:set-theme (display-graphic-p)))))

;;;
;;; custom configuration
;;;

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(custom-safe-themes
   (quote
    ("f5b591870422cd28da334552aae915cdcae3edfcfedb6653a9f42ed84bbec69f" default)))
 '(ecb-options-version "2.40")
 '(inhibit-startup-screen t)
 '(menu-bar-mode nil)
 '(org-agenda-files (quote ("~/Cryptbox/TODO")))
 '(org-babel-load-languages (quote ((emacs-lisp . t) (perl . t))))
 '(org-confirm-babel-evaluate nil)
 '(org-html-doctype "html5")
 '(package-selected-packages
   (quote
    (atomic-chrome magit lua-mode vala-mode simpleclip scss-mode ox-reveal org-plus-contrib nlinum monokai-theme linum-relative flycheck markdown-mode htmlize)))
 '(safe-local-variable-values
   (quote
    ((eval require
	   (quote ox-reveal))
     (eval require
	   (quote ob-vala)))))
 '(scss-compile-at-save nil)
 '(c-default-style "bsd")
 '(c-basic-offset 3))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(mode-line ((t (:background "orange4" :foreground "black" :box (:line-width -1 :style released-button))))))

;;; .emacs ends here


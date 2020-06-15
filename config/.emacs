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

;; proper mouse selection handling in textmode emacs
(xterm-mouse-mode 1)

;;;
;;; mutt + tin integration
;;;

(setq auto-mode-alist
      (append
       '(("/mutt-" . mail-mode)
	 ("/neomutt-" . mail-mode)
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
;;; perl
;;;

;; use CPerlMode instead of PerlMode
;(require 'cperl-mode)
;(fset 'perl-mode 'cperl-mode)
;(setq cperl-indent-level 4
;      cperl-close-paren-offset -4
;      cperl-continued-statement-offset 4
;      cperl-indent-parens-as-block t
;      cperl-tab-always-indent t)

;;;
;;; flycheck
;;;

;; enable Flycheck when installed
(when (require 'flycheck nil :noerror)
  (add-hook 'after-init-hook #'global-flycheck-mode))

(when (require 'flycheck-yamllint nil :noerror)
  (add-hook 'flycheck-mode-hook 'flycheck-yamllint-setup))

;;;
;;; use emacs to edit <textarea>s in Firefox
;;;

;; skip when not installed
(when (require 'atomic-chrome nil :noerror)
  ;; don't throw an error if another emacs instance has the port
  (ignore-errors
    (atomic-chrome-start-server)
    (setq atomic-chrome-buffer-open-style 'frame)))

;;;
;;; org-mode
;;;

;; load ox-gfm.el if present
(eval-after-load "org"
  '(require 'ox-gfm nil :noerror))

;; org-mode keybindings
(require 'org)
;;(define-key global-map "\C-cl" 'org-store-link)
;;(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)

;; load ox-s9y.el if present
(when (file-directory-p "~/git/ox-s9y/")
  (add-to-list 'load-path "~/git/ox-s9y/")
  (require 'ox-s9y))

;; use smart link insertion
(defun my:string-match-perl-module-p (string)
  "Check STRING for a Perl module name.
Return non-nil if STRING looks like a Perl module name."
  (and string (string-match "\\(?:[A-Za-z0-9]+::\\)+[A-Za-z0-9]+" string)))

(defun my:org-insert-link-smart (&optional complete-file link-location default-description)
       "Insert a link with smart defaults.
Works like `org-insert-link', but when the active region in the
current buffer matches certain criteria, a link target is
automatically generated:

- Perl-Module names will expand to https://metacpan.net/pod/
  links.

Otherwise call `org-insert-link' with the original COMPLETE-FILE,
LINK-LOCATION and DEFAULT-DESCRIPTION."
       (interactive "p")
       (let* ((region (when (org-region-active-p)
			(buffer-substring (region-beginning) (region-end))))
	      (calculated-link (when (my:string-match-perl-module-p region)
				 (concat "https://metacpan.org/pod/" region))))
	 (if calculated-link
	     (org-insert-link complete-file calculated-link region)
	   (org-insert-link complete-file link-location default-description))))

(define-key org-mode-map (kbd "C-c C-l") 'my:org-insert-link-smart)

;; lualatex preview
(setq org-latex-pdf-process
  '("lualatex -shell-escape -interaction nonstopmode %f"
    "lualatex -shell-escape -interaction nonstopmode %f"))

(setq luamagick '(luamagick :programs ("lualatex" "convert")
       :description "pdf > png"
       :message "you need to install lualatex and imagemagick."
       :use-xcolor t
       :image-input-type "pdf"
       :image-output-type "png"
       :image-size-adjust (1.0 . 1.0)
       :latex-compiler ("lualatex -interaction nonstopmode -output-directory %o %f")
       :image-converter ("convert -density %D -trim -antialias %f -quality 100 %O")))

(add-to-list 'org-preview-latex-process-alist luamagick)

(setq org-preview-latex-default-process 'luamagick)

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
 '(c-basic-offset 3)
 '(c-default-style "bsd")
 '(column-number-mode t)
 '(custom-safe-themes
   (quote
    ("f5b591870422cd28da334552aae915cdcae3edfcfedb6653a9f42ed84bbec69f" default)))
 '(ecb-options-version "2.40")
 '(ecb-source-path (quote ("/home/mitch/git/gbsplay")))
 '(inhibit-startup-screen t)
 '(menu-bar-mode nil)
 '(org-agenda-files (quote ("~/Cryptbox/TODO")))
 '(org-babel-load-languages (quote ((emacs-lisp . t) (perl . t))))
 '(org-confirm-babel-evaluate nil)
 '(org-html-doctype "html5")
 '(package-selected-packages
   (quote
    (flycheck-yamllint groovy-mode bbcode-mode cobol-mode atomic-chrome magit lua-mode vala-mode simpleclip scss-mode ox-reveal org-plus-contrib nlinum monokai-theme linum-relative flycheck markdown-mode htmlize)))
 '(safe-local-variable-values
   (quote
    ((eval require
	   (quote ox-reveal))
     (eval require
	   (quote ob-vala)))))
 '(scss-compile-at-save nil))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(font-lock-function-name-face ((t (:foreground "deep sky blue" :height 1.0))))
 '(mode-line ((t (:background "orange4" :foreground "black" :box (:line-width -1 :style released-button))))))

;;; .emacs ends here


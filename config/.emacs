;; set usable font (otherwise default Ubuntu install comes up with a Comic Sans lookalike - YUCK!)
(set-face-attribute 'default nil :font "-efont-fixed-medium-r-normal-*-14-140-75-75-c-70-iso10646-1")

;; don't show startup screen
(setq inhibit-startup-screen t)

;; don't show toolbar
(tool-bar-mode -1)

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

;; black on white
(invert-face 'default)

;; build a unique "theme" just to fix some things in console mode
;; activate only in console mode
(unless (display-graphic-p)
  ;;
  ;; this is based on https://github.com/rexim/gruber-darker-theme/ with most things deleted
  ;;; gruber-darker-theme.el --- Gruber Darker color theme for Emacs 24.

  ;; Copyright (C) 2013 Alexey Kutepov a.k.a rexim

  ;; Author: Alexey Kutepov <reximkut@gmail.com>
  ;; URL: http://github.com/rexim/gruber-darker-theme
  ;; Version: 0.6

  ;; Permission is hereby granted, free of charge, to any person
  ;; obtaining a copy of this software and associated documentation
  ;; files (the "Software"), to deal in the Software without
  ;; restriction, including without limitation the rights to use, copy,
  ;; modify, merge, publish, distribute, sublicense, and/or sell copies
  ;; of the Software, and to permit persons to whom the Software is
  ;; furnished to do so, subject to the following conditions:

  ;; The above copyright notice and this permission notice shall be
  ;; included in all copies or substantial portions of the Software.

  ;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  ;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  ;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  ;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
  ;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
  ;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
  ;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  ;; SOFTWARE.

;;; Commentary:
  ;;
  ;; Gruber Darker color theme for Emacs by Jason Blevins. A darker
  ;; variant of the Gruber Dark theme for BBEdit by John Gruber. Adapted
  ;; for deftheme and extended by Alexey Kutepov a.k.a. rexim.
  ;;
  ;; stripped and renamed to mitch-dark-fixup by Christian Garbs 

  (deftheme mitch-dark-fixup
    "mitch dark color fixup theme for Emacs 24")

  ;; Please, install rainbow-mode.
  ;; Colors with +x are lighter. Colors with -x are darker.
  (let ((mitch-dark-fixup-fg        "#e4e4ef")
	(mitch-dark-fixup-fg+1      "#f4f4ff")
	(mitch-dark-fixup-fg+2      "#f5f5f5")
	(mitch-dark-fixup-white     "#ffffff")
	(mitch-dark-fixup-black     "#000000")
	(mitch-dark-fixup-bg-1      "#101010")
	(mitch-dark-fixup-bg        "#181818")
	(mitch-dark-fixup-bg+1      "#282828")
	(mitch-dark-fixup-bg+2      "#453d41")
	(mitch-dark-fixup-bg+3      "#484848")
	(mitch-dark-fixup-bg+4      "#52494e")
	(mitch-dark-fixup-red-1     "#c73c3f")
	(mitch-dark-fixup-red       "#f43841")
	(mitch-dark-fixup-red+1     "#ff4f58")
	(mitch-dark-fixup-green     "#73c936")
	(mitch-dark-fixup-yellow    "#ffdd33")
	(mitch-dark-fixup-brown     "#cc8c3c")
	(mitch-dark-fixup-quartz    "#95a99f")
	(mitch-dark-fixup-niagara-1 "#5f627f")
	(mitch-dark-fixup-niagara   "#96a6c8")
	(mitch-dark-fixup-wisteria  "#9e95c7")
	)
    (custom-theme-set-variables
     'mitch-dark-fixup
     '(frame-brackground-mode (quote dark)))

    (custom-theme-set-faces
     'mitch-dark-fixup

     ;; Basic Coloring (or Uncategorized)
     `(minibuffer-prompt ((t (:foreground ,mitch-dark-fixup-niagara))))
     `(region ((t (:background ,mitch-dark-fixup-bg+3 :foreground nil))))

     ;; Diff
     `(diff-removed ((t ,(list :foreground mitch-dark-fixup-red+1
			       :background nil))))
     `(diff-added ((t ,(list :foreground mitch-dark-fixup-green
			     :background nil))))

     ))
  )

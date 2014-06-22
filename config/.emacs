;; set usable font (otherwise default Ubuntu isntall comes up with a Comic Sans lookalike - YUCK!)
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


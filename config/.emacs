(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(inhibit-startup-screen t))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )

;; set usable font (otherwise default Ubuntu isntall comes up with a Comic Sans lookalike - YUCK!)
(set-face-attribute 'default nil :font "-efont-fixed-medium-r-normal-*-14-140-75-75-c-70-iso10646-1")

;; auto-modeselect for Markdown documents
(setq auto-mode-alist (cons '("\\.md\\'" . markdown-mode) auto-mode-alist))

;; try to find nice C identation/formatting
(setq c-default-style "linux"
      c-basic-offset 4)


# This is optimized for diff-so-fance in combination with my xterm-theme-changer.
# I somehow have to switch red and green, also most things are unreadable without this.

# include this in ~/.gitconfig like so:
# [include]
# path = ~/git/mitchscripts/config/git-colors.inc

[color "diff-highlight"]
	oldnormal = green bold
	oldhighlight = green bold 24
	newnormal = yellow bold
	newhighlight = yellow bold 24
[color "diff"]
	meta = blue
	commit = blue bold
	whitespace = red reverse
	frag = magenta bold
	old = green bold
	new = yellow bold

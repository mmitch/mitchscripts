# bash history:
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# setup path
source /home/mitch/git/mitchscripts/config/setup-PATH

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# prompt part for shell error code (show only when set)
LOC_PROMPT_ERRORCODE="\$(printf '%.*s%.*s' \$? \$? \$? ' ')"

# prompt part for git status
if [ -r /usr/lib/git-core/git-sh-prompt ]; then
    source /usr/lib/git-core/git-sh-prompt
    export GIT_PS1_SHOWDIRTYSTATE=1
    export GIT_PS1_SHOWSTASHSTATE=1
    export GIT_PS1_SHOWUNTRACKEDFILES=1
    export GIT_PS1_SHOWUPSTREAM='auto verbose git'
    export GIT_PS1_SHOWCOLORHINTS=1
    LOC_PROMPT_GIT='$(__git_ps1 " (%s) ")'
else
    LOC_PROMPT_GIT=''
fi

# boost colorfulness (experimental)
case "$TERM" in
    xterm*)
	# promote xterm to xterm-256color (and keep xterm-256color after that)
	TERM=xterm-256color
	export TERM
	export MC_SKIN=modarin256-defbg-thin.ini

	case $HOSTNAME in
	    zecora)
		color=53
		;;
	    yggdrasil)
		color=59
		;;
	    hasi)
		color=22
		;;
	    merlin)
		color=94
		;;
	    ks*)
		color=95
		;;
	    fluttershy)
		color=25
		;;
	    ms1067a1)
		color=77
		;;
		# reserve colors:
		# 23 33 26 32 58
	    *)
		color=237
		;;
	esac

	PS1="${LOC_PROMPT_ERRORCODE}${debian_chroot:+($debian_chroot)}\[\033[00;38;5;${color}m\]\u@\h\[\033[30m\]:\[\033[38;5;103m\]\w\[\033[38;5;108m\]${LOC_PROMPT_GIT}\[\033[38;5;65m\]\$\[\033[00m\] "
	unset color
	;;

    *)
	export MC_SKIN=~/git/mitchscripts/config/mitch-mc-skin.ini
	PS1="${LOC_PROMPT_ERRORCODE}${debian_chroot:+($debian_chroot)}\u@\h:\w${LOC_PROMPT_GIT}\$ "
	;;
esac

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

unset debian_chroot

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases (never used - remove?)
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# dwm-mitch
export DMENU_COLORS="-fn fixed -nb black -nf white"

# setup locale
LC_MESSAGES=C
LANG=de_DE.utf-8
LANGUAGE=de_DE.utf-8
export LC_MESSAGES LANG LANGUAGE

# http://java.sun.com/j2se/1.5.0/docs/guide/awt/1.5/xawt.html
# grey Java windows in dwm 
# export AWT_TOOLKIT=MToolkit (experimentally disabled 2016-02, check if still needed)

# use sane editor
export EDITOR=emacs
export VISUAL=$EDITOR

# disable history expansion !
set +H

# set more restrictive umask
umask 022

# set compression options
export BZIP2="-9v"

# enable globstar: ** matches dirs + files
shopt -s globstar

setopt PROMPT_SUBST
setopt PROMPT_PERCENT
setopt PROMPT_BANG
source /usr/lib/git-core/git-sh-prompt
export GIT_PS1_SHOWDIRTYSTATE=1
PROMPT="
%B%F{red}┍━━━⎧⦇ %F{white}!s:%?%F{red} ⦈━(%F{white}%j%F{red})━[ %F{white}%~:%F{yellow}$(__git_ps1 "%s")%F{red} ]
╘═══⎩%b%f "


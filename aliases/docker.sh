alias dockerkillall='docker kill $(docker ps -q)'
alias dockercleanc="printf 'Not actually going to run this for you\n' && printf 'docker rm $(docker ps -a -q)'"
alias dockercleani="printf 'Not actually going to run this for you\n' && printf 'docker rmi $(docker images -q -f dangling=true)'"
alias dockerclean='dockercleanc || true && dockercleani'

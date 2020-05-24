[ -n "$PS1" ] && source ~/.bash_profile

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
source /usr/share/nvm/init-nvm.sh

. ~/.bash.d/cht.sh

_git_checkout() {
    __git_has_doubledash && return

    case "$cur" in
    --conflict=*)
        __gitcomp "diff3 merge" "" "${cur##--conflict=}"
        ;;
    --*)
        __gitcomp_builtin checkout
        ;;
    *)
        # check if --track, --no-track, or --no-guess was specified
        # if so, disable DWIM mode
        local flags="--track --no-track --no-guess" track_opt="--track"
        if [ "$GIT_COMPLETION_CHECKOUT_NO_GUESS" = "1" ] ||
            [ -n "$(__git_find_on_cmdline "$flags")" ]; then
            track_opt=''
        fi
        if [ "$command" = "checkoutr" ]; then
            # echo $command
            __git_complete_refs $track_opt
        else
            # __gitcomp_direct "$(__git_heads "" "$cur" " ")"
            # echo $command
            __gitcomp_nl "$(__git_heads '' $track)"
        fi
        ;;
    esac
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/jimubao/.sdkman"
[[ -s "/home/jimubao/.sdkman/bin/sdkman-init.sh" ]] && source "/home/jimubao/.sdkman/bin/sdkman-init.sh"

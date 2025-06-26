#
# ~/.bash_profile
#

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";
export EDITOR="vim";
# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,bash_aliases,functions,extra,bash_sources}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

[[ -f ~/.bashrc ]] && . ~/.bashrc

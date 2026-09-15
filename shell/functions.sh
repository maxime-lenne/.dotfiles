# shellcheck shell=bash
# shell/functions.sh — was ~/.functions until 2026-09-15. Until then it was
# sourced by bash only; zsh never loaded it, which is the drift this move
# closes.

# zsh refuses to define a function whose name is already an alias — it is a
# parse error that aborts the rest of the file, not just that definition.
# oh-my-zsh's elixir plugin ships `alias ips='iex -S mix phx.server'`, which
# on 2026-09-15 silently cost zsh cp_p, extract and gifify until the
# fingerprint diff caught it. Clearing the names first is cheap, and keeps a
# future name collision from failing silently.
for _dotfiles_fn in server ips cp_p extract gifify; do
  unalias "$_dotfiles_fn" 2>/dev/null
done
unset _dotfiles_fn

# Start an HTTP server from a directory, optionally specifying the port.
# python3 since 2026-09-15: the body used SimpleHTTPServer, a Python 2
# module, and `python` no longer exists on macOS. The old version also
# forced Content-Type text/plain and a UTF-8 charset on every file;
# http.server guesses from the extension instead, which is more correct.
server() {
	local port="${1:-8000}"
	open "http://localhost:${port}/"
	python3 -m http.server "$port"
}

# Every IPv4 address the machine holds. A function, not an alias, since
# 2026-09-15: perl's $1 in an alias body is SC2142 ("Aliases can't use
# positional parameters"), and the alias form was broken anyway — the
# unescaped $1 was consumed as the sourcing file's empty positional
# parameter, so perl printed whole ifconfig lines instead of the address.
ips() {
	ifconfig -a | perl -nle 'print $1 if /(\d+\.\d+\.\d+\.\d+)/'
}

# Copy with a progress bar
cp_p() {
	rsync -WavP --human-readable --progress "$1" "$2"
}

# Extract archives - use: extract <file>
# Credits to http://dotfiles.org/~pseup/.bashrc
# Quoting added 2026-09-15 (SC2086): every path with a space used to fail.
extract() {
	if [ -f "$1" ] ; then
		case "$1" in
			*.tar.bz2) tar xjf "$1" ;;
			*.tar.gz) tar xzf "$1" ;;
			*.bz2) bunzip2 "$1" ;;
			*.rar) rar x "$1" ;;
			*.gz) gunzip "$1" ;;
			*.tar) tar xf "$1" ;;
			*.tbz2) tar xjf "$1" ;;
			*.tgz) tar xzf "$1" ;;
			*.zip) unzip "$1" ;;
			*.Z) uncompress "$1" ;;
			*.7z) 7z x "$1" ;;
			*) echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

# Animated gifs from any video
# from alex sexton   gist.github.com/SlexAxton/4989674
# `magick` since 2026-09-15: ImageMagick 7 deprecated the `convert` name.
gifify() {
	if [ -z "$1" ]; then
		echo "proper usage: gifify <input_movie.mov>. You DO need to include extension."
		return 1
	fi
	if [ "$2" = "--good" ]; then
		ffmpeg -i "$1" -r 10 -vcodec png out-static-%05d.png
		magick -verbose +dither -layers Optimize -resize '600x600>' out-static*.png GIF:- \
			| gifsicle --colors 128 --delay=5 --loop --optimize=3 --multifile - > "$1.gif"
		rm out-static*.png
	else
		ffmpeg -i "$1" -s 600x400 -pix_fmt rgb24 -r 10 -f gif - \
			| gifsicle --optimize=3 --delay=3 > "$1.gif"
	fi
}

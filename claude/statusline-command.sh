#!/bin/bash
# Converted from the PS1 in ~/.bash_profile
input=$(cat)

if [ "$USER" = "root" ]; then
  color="\033[01;35m"
elif [ -n "$SANDVAULT" ]; then
  color="\033[01;33m"
elif [ -n "$SSH_CONNECTION" ]; then
  color="\033[01;36m"
else
  color="\033[01;32m"
fi

dir=$(echo "$input" | jq -r '.workspace.current_dir')
branch=$(git -C "$dir" branch --show-current 2>/dev/null)

printf "${color}%s\033[01;34m %s\033[01;33m%s\033[01;34m #\033[00m %s" \
  "$(hostname -s)" \
  "$(basename "$dir")" \
  "${branch:+ ($branch)}" \
  "$(echo "$input" | jq -rj --arg e "$(printf '\033')" '
      def paint($code): $e + "[" + $code + "m";
      def gauge($label; $left): "\($label) \(paint(if $left >= 50 then "32" elif $left >= 20 then "33" else "31" end))\($left | round)%\(paint("0"))";
      ["\(paint("01;37"))\(.model.display_name)\(paint("0"))"]
      + (if .context_window.remaining_percentage then [gauge("ctx"; .context_window.remaining_percentage)] else [] end)
      + (if .rate_limits.five_hour then [gauge("5h"; 100 - .rate_limits.five_hour.used_percentage)] else [] end)
      + (if .rate_limits.seven_day then [gauge("wk"; 100 - .rate_limits.seven_day.used_percentage)] else [] end)
      | join("\(paint("90")) | \(paint("0"))")
    ')"

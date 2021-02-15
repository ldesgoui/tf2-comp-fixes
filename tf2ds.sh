#!/usr/bin/env nix-shell
#!nix-shell -i sh -p tmux steam-run

set -euo pipefail

cd $HOME/zzz/tmp/tf2ds

export LD_LIBRARY_PATH=".:bin:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

tmux attach -t tf2ds && exit

tmux new-s -ds tf2ds
tmux send-keys -t tf2ds "steam-run ./srcds_linux -ip 0.0.0.0 -game tf -sv_pure 2 +map itemtest +rcon_password a" Enter
tmux attach -t tf2ds

#!/usr/bin/env nix-shell
#!nix-shell -i sh -p steam-run

TF2DS="$HOME/zzz/tmp/tf2ds"
SM="$TF2DS/tf/addons/sourcemod"

steam-run "$SM/scripting/spcomp64" \
    scripting/tf2-comp-fixes.sp \
    -o "$SM/plugins/tf2-comp-fixes" \
    DEBUG=1

cp gamedata/tf2-comp-fixes.games.txt \
    "$SM/gamedata"

#!/usr/bin/env nix-shell
#!nix-shell -i bash -p busybox dotnet-sdk

set -euo pipefail

DEPOTDOWNLOADER="https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.3.6/depotdownloader-2.3.6.zip"

mkdir -p ~/zzz/tmp
cd ~/zzz/tmp

curl -Lo- $DEPOTDOWNLOADER | unzip -

chmod +x depotdownloader

cat > files.txt <<END
bin/\w+.so
hl2/hl2_misc_\w+.vpk
srcds_linux
srcds_run
steam_appid.txt
tf/bin/\w+.so
tf/cfg/pure_server_full.txt
tf/cfg/pure_server_minimal.txt
tf/cfg/trusted_keys_base.txt
tf/gameinfo.txt
tf/maps/itemtest.bsp
tf/scripts/items/items_game.txt
tf/scripts/items/items_game.txt.sig
tf/scripts/protodefs/proto_defs.vpd
tf/scripts/protodefs/proto_defs.vpd.sig
tf/steam.inf
tf/tf2_misc_\w+.vpk
END

./depotdownloader -app 232250 -dir tf2ds -filelist files.txt

chmod +x tf2ds/srcds_run tf2ds/srcds_linux

exit

# https://www.sourcemm.net/downloads.php?branch=stable
curl -Lo mmsource.tar.gz "https://mms.alliedmods.net/mmsdrop/1.10/mmsource-1.10.7-git971-linux.tar.gz" &

# https://www.sourcemod.net/downloads.php?branch=stable
curl -Lo sourcemod.tar.gz "https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6497-linux.tar.gz" &

# https://tftrue.esport-tools.net/
curl -LO "http://tftrue.esport-tools.net/TFTrue.zip" &

# https://github.com/peace-maker/DHooks2/releases
curl -Lo dhooks.zip "https://github.com/peace-maker/DHooks2/releases/download/v2.2.0-detours14a/dhooks-2.2.0-detours14-sm110.zip" &

for job in $(jobs -p); do
    wait \$job
done

cd tf2ds/tf
tar -xzf ../../mmsource.tar.gz
tar -xzf ../../sourcemod.tar.gz
unzip ../../TFTrue.zip
unzip ../../dhooks.zip

tee cfg/server.cfg <<END
alias pl "sm plugins list"
alias pr "sm plugins reload"
END

#pragma semicolon 1
#pragma newdecls required

#include "tf2-comp-fixes/fix-projectiles-colliding-teammates.sp"
#include "tf2-comp-fixes/fix-sticky-delay.sp"
#include "tf2-comp-fixes/remove-halloween-souls.sp"
#include "tf2-comp-fixes/remove-medic-attach-speed.sp"

public Plugin myinfo = {
	name = "TF2 Competitive Fixes",
	author = "ldesgoui",
	description = "Various technical or gameplay altering changes catered towards competitive play",
	version = "1.1.0",
	url = "https://github.com/ldesgoui/tf2-comp-fixes"
};

public void OnPluginStart() {
    Handle game_config = LoadGameConfigFile("tf2-comp-fixes.games");

    if (game_config == INVALID_HANDLE) {
        SetFailState("Failed to load addons/sourcemod/gamedata/tf2-comp-fixes.games.txt");
    }

    RemoveBonusRoundTimeUpperBound();
    SetupFixStickyDelay(game_config);
    SetupRemoveHalloweenSouls(game_config);
    SetupRemoveMedicAttachSpeed(game_config);
    SetupRemoveProjectilesHittingTeammates(game_config);
}

public void OnMapStart() {
    RemoveBonusRoundTimeUpperBound();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse,
        float vel[3], float angles[3], int &currWeapon, int &subtype,
        int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
    FixStickyDelay(client, buttons);

    return Plugin_Continue;
}

void RemoveBonusRoundTimeUpperBound() {
    SetConVarBounds(FindConVar("mp_bonusroundtime"), ConVarBound_Upper, false);
}

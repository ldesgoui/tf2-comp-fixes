#pragma semicolon 1
#pragma newdecls required

Handle g_hook_CBaseProjectile_CanCollideWithTeammates = INVALID_HANDLE;

#include "tf2-comp-fixes/common.sp"
#include "tf2-comp-fixes/deterministic-fall-damage.sp"
#include "tf2-comp-fixes/fix-ghost-crossbow-bolts.sp"
#include "tf2-comp-fixes/fix-slope-bug.sp"
#include "tf2-comp-fixes/fix-sticky-delay.sp"
#include "tf2-comp-fixes/ghostify-soldier-statue.sp"
#include "tf2-comp-fixes/gunboats-always-apply.sp"
#include "tf2-comp-fixes/projectiles-ignore-teammates.sp"
#include "tf2-comp-fixes/remove-halloween-souls.sp"
#include "tf2-comp-fixes/remove-medic-attach-speed.sp"

// clang-format off
public
Plugin myinfo = {
    name = "TF2 Competitive Fixes",
    author = "ldesgoui",
    description = "Various technical or gameplay changes catered towards competitive play",
    version = "1.5.0",
    url = "https://github.com/ldesgoui/tf2-comp-fixes"
};
// clang-format on

public
void OnPluginStart() {
    Handle game_config = LoadGameConfigFile("tf2-comp-fixes.games");

    if (game_config == INVALID_HANDLE) {
        SetFailState("Failed to load addons/sourcemod/gamedata/tf2-comp-fixes.games.txt");
    }

    RegAdminCmd("sm_cf", CfCommand, ADMFLAG_CONVARS, "Batch update of TF2 Competitive Fixes cvars");

    DeterministicFallDamage_Setup(game_config);
    FixGhostCrossbowBolts_Setup(game_config);
    FixSlopeBug_Setup(game_config);
    FixStickDelay_Setup(game_config);
    GhostifySoldierStatue_Setup();
    GunboatsAlwaysApply_Setup(game_config);
    ProjectilesIgnoreTeammates_Setup(game_config);
    RemoveHalloweenSouls_Setup(game_config);
    RemoveMedicAttachSpeed_Setup(game_config);
}

Action CfCommand(int client, int args) {
    char full[256];
    bool everything = false;
    bool fixes      = false;

    GetCmdArgString(full, sizeof(full));

    if (StrEqual(full, "all")) {
        everything = true;
    } else if (StrEqual(full, "fixes")) {
        fixes = true;
    } else if (StrEqual(full, "none")) {
    } else {
        ReplyToCommand(client, "usage: sm_cf (all | fixes | none)");
        return Plugin_Handled;
    }

    FindConVar("sm_deterministic_fall_damage").SetBool(everything || fixes);
    FindConVar("sm_fix_ghost_crossbow_bolts").SetBool(everything || fixes);
    FindConVar("sm_fix_slope_bug").SetBool(everything || fixes);
    FindConVar("sm_fix_sticky_delay").SetBool(everything || fixes);
    FindConVar("sm_projectiles_ignore_teammates").SetBool(everything || fixes);
    FindConVar("sm_remove_halloween_souls").SetBool(everything || fixes);
    FindConVar("sm_rest_in_peace_rick_may").SetInt(everything || fixes ? 128 : 0);

    FindConVar("sm_gunboats_always_apply").SetBool(everything);
    FindConVar("sm_remove_medic_attach_speed").SetBool(everything);

    return Plugin_Handled;
}

#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>
#include "utils.sp"

Address g_healingbolt_vtable;
ConVar g_fix_ghost_crossbow_bolts;
ConVar g_projectiles_ignore_teammates;

void SetupRemoveProjectilesHittingTeammates(Handle game_config) {
    g_fix_ghost_crossbow_bolts = CreateBoolConVar("sm_fix_ghost_crossbow_bolts");
    g_projectiles_ignore_teammates = CreateBoolConVar("sm_projectiles_ignore_teammates");

    g_healingbolt_vtable = GameConfGetAddress(game_config,
            "CTFProjectile_HealingBolt::vtable");

    if (g_healingbolt_vtable == Address_Null) {
        SetFailState("Failed to load CTFProjectile_HealingBolt::vtable "
                ... "signature from gamedata");
    }

    Handle detour = DHookCreateFromConf(game_config,
            "CBaseProjectile::CanCollideWithTeammates");

    if (detour == INVALID_HANDLE) {
        SetFailState("Failed to create detour for "
                ... "CBaseProjectile::CanCollideWithTeammates");
    }

    if (!DHookEnableDetour(detour, false, DetourCanCollideWithTeammates)) {
        SetFailState("Failed to enable detour CBaseProjectile::CanCollideWithTeammates.");
    }
}

MRESReturn DetourCanCollideWithTeammates(Address self, Handle ret, Handle params) {
    if (g_fix_ghost_crossbow_bolts.BoolValue) {
        int vtable = LoadFromAddress(self, NumberType_Int32);

        if ((vtable - 8) == view_as<int>(g_healingbolt_vtable)) {
            DHookSetReturn(ret, 1);
            return MRES_Supercede;
        }
    }

    if (g_projectiles_ignore_teammates.BoolValue) {
        DHookSetReturn(ret, 0);
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sdktools>

Address g_healingbolt_vtable;
ConVar g_fix_ghost_crossbow_bolts;
ConVar g_projectiles_ignore_teammates;

void SetupRemoveProjectilesHittingTeammates(Handle game_config) {
    g_fix_ghost_crossbow_bolts = CreateConVar(
            "sm_fix_ghost_crossbow_bolts", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    g_projectiles_ignore_teammates = CreateConVar(
            "sm_projectiles_ignore_teammates", "0", "", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    g_healingbolt_vtable = GameConfGetAddress(game_config, "CTFProjectile_HealingBolt::vtable");

    if (g_healingbolt_vtable == Address_Null) {
        SetFailState("Failed to load CTFProjectile_HealingBolt::vtable signature from gamedata");
    }

    Handle detour = DHookCreateDetour(
            Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_Address);

    if (detour == INVALID_HANDLE) {
        SetFailState("Failed to create detour for CBaseProjectile::CanCollideWithTeammates");
    }

    if (!DHookSetFromConf(detour, game_config, SDKConf_Signature,
                "CBaseProjectile::CanCollideWithTeammates")) {
        SetFailState("Failed to load CBaseProjectile::CanCollideWithTeammates signature from gamedata");
    }

    if (!DHookEnableDetour(detour, false, DetourCanCollideWithTeammates)) {
        SetFailState("Failed to detour CBaseProjectile::CanCollideWithTeammates.");
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

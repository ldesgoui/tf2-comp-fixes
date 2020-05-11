#if defined _TF2_COMP_FIXES_PROJECTILES_IGNORE_TEAMMATES
#endinput
#endif
#define _TF2_COMP_FIXES_PROJECTILES_IGNORE_TEAMMATES

#include "common.sp"
#include <dhooks>
#include <sdktools>

void ProjectilesIgnoreTeammates_Setup() {
    CreateBoolConVar("sm_projectiles_ignore_teammates", OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    DHookToggleEntityListener(ListenType_Created, OnEntityCreated, cvar.BoolValue);
}

static void OnEntityCreated(int entity, const char[] classname) {
    if (StrContains(classname, "tf_projectile_") != -1 &&
        !StrEqual(classname, "tf_projectile_healing_bolt")) {
        if (INVALID_HOOK_ID == DHookEntity(g_hook_CBaseProjectile_CanCollideWithTeammates, HOOK_PRE,
                                           entity, _,
                                           Hook_CBaseProjectile_CanCollideWithTeammates)) {
            SetFailState("Failed to hook CBaseProjectile::CanCollideWithTeammates");
        }
    }
}

static MRESReturn Hook_CBaseProjectile_CanCollideWithTeammates(int self, Handle ret) {
    DHookSetReturn(ret, false);
    return MRES_Supercede;
}

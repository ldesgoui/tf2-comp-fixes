#if defined _TF2_COMP_FIXES_FIX_SPLASH_BUG
#endinput
#endif
#define _TF2_COMP_FIXES_FIX_SPLASH_BUG

#include "common.sp"
#include <dhooks>

static Handle g_detour_CTFBaseRocket_Explode;

void FixSplashBug_Setup(Handle game_config) {
    g_detour_CTFBaseRocket_Explode =
        CheckedDHookCreateFromConf(game_config, "CTFBaseRocket::Explode");

    CreateBoolConVar("sm_fix_splash_bug", OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFBaseRocket_Explode, HOOK_PRE, Detour_Pre, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFBaseRocket::Explode");
    }
}

static MRESReturn Detour_Pre(int self, Handle params) {
    float endpos[3], normal[3];

    DHookGetParamObjectPtrVarVector(params, 1, 12, ObjectValueType_Vector, endpos);
    DHookGetParamObjectPtrVarVector(params, 1, 24, ObjectValueType_Vector, normal);

    ScaleVector(normal, 2.0);
    AddVectors(endpos, normal, endpos);

    DHookSetParamObjectPtrVarVector(params, 1, 12, ObjectValueType_Vector, endpos);
    return MRES_Override;
}

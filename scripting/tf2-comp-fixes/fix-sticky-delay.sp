#if defined _TF2_COMP_FIXES_FIX_STICKY_DELAY
#endinput
#endif
#define _TF2_COMP_FIXES_FIX_STICKY_DELAY

#include "common.sp"
#include <dhooks>
#include <sdktools>
#include <tf2_stocks>

static Handle g_call_CTFWeaponBase_SecondaryAttack;
static Handle g_detour_CTFWeaponBase_ItemBusyFrame;

void FixStickDelay_Setup(Handle game_config) {
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(game_config, SDKConf_Virtual, "CTFWeaponBase::SecondaryAttack");
    if ((g_call_CTFWeaponBase_SecondaryAttack = EndPrepSDKCall()) == INVALID_HANDLE) {
        SetFailState("Failed to finalize SDK call to CTFWeaponBase::SecondaryAttack");
    }

    g_detour_CTFWeaponBase_ItemBusyFrame =
        CheckedDHookCreateFromConf(game_config, "CTFWeaponBase::ItemBusyFrame");

    CreateBoolConVar("sm_fix_sticky_delay", OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFWeaponBase_ItemBusyFrame, HOOK_PRE,
                           Detour_CTFWeaponBase_ItemBusyFrame, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFWeaponBase::ItemBusyFrame");
    }
}

static MRESReturn Detour_CTFWeaponBase_ItemBusyFrame(int self, Handle ret) {
    int owner = GetEntPropEnt(self, Prop_Data, "m_hOwnerEntity");

    if (GetClientButtons(owner) & IN_ATTACK2 != IN_ATTACK2) {
        return MRES_Ignored;
    }

    int secondary = GetPlayerWeaponSlot(owner, TFWeaponSlot_Secondary);
    if (secondary == -1) {
        return MRES_Ignored;
    }

    // XXX: perf?
    char classname[64];
    if (!GetEntityClassname(secondary, classname, sizeof(classname))) {
        return MRES_Ignored;
    }

    if (!StrEqual(classname, "tf_weapon_pipebomblauncher")) {
        return MRES_Ignored;
    }

    SDKCall(g_call_CTFWeaponBase_SecondaryAttack, self);

    return MRES_Handled;
}

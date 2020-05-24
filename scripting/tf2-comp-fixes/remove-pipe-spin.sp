#if defined _TF2_COMP_FIXES_REMOVE_PIPE_SPIN
#endinput
#endif
#define _TF2_COMP_FIXES_REMOVE_PIPE_SPIN

#include "common.sp"
#include <dhooks>
#include <sdkhooks>
#include <sdktools>

#define ATTR_GRENADE_NO_SPIN      (681)
#define WEAPON_ID_THE_LOCH_N_LOAD (308)

static ConVar g_convar;

void RemovePipeSpin_Setup() { g_convar = CreateBoolConVar("sm_remove_pipe_spin", OnConVarChange); }

void RemovePipeSpin_OnClientPutInServer(int client) {
    if (!g_convar.BoolValue) {
        return;
    }

    SDKHook(client, SDKHook_WeaponCanUsePost, Hook_WeaponCanUsePost);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "tf_weapon_grenadelauncher")) != -1) {
        if (GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == WEAPON_ID_THE_LOCH_N_LOAD) {
            continue;
        }

        SetAttribute(entity, ATTR_GRENADE_NO_SPIN, cvar.BoolValue ? 1.0 : 0.0);
    }

    entity = -1;
    while ((entity = FindEntityByClassname(entity, "tf_weapon_cannon")) != -1) {
        SetAttribute(entity, ATTR_GRENADE_NO_SPIN, cvar.BoolValue ? 1.0 : 0.0);
    }

    for (entity = 1; entity <= MaxClients; entity++) {
        if (!IsClientInGame(entity)) {
            continue;
        }

        if (cvar.BoolValue) {
            SDKHook(entity, SDKHook_WeaponCanUsePost, Hook_WeaponCanUsePost);
        } else {
            SDKUnhook(entity, SDKHook_WeaponCanUsePost, Hook_WeaponCanUsePost);
        }
    }
}

static void Hook_WeaponCanUsePost(int client, int weapon) {
    if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == WEAPON_ID_THE_LOCH_N_LOAD) {
        return;
    }

    char classname[64];

    GetEntityClassname(weapon, classname, sizeof(classname));

    if (StrEqual(classname, "tf_weapon_grenadelauncher") ||
        StrEqual(classname, "tf_weapon_cannon")) {
        SetAttribute(weapon, ATTR_GRENADE_NO_SPIN, 1.0);
    }
}

#if defined _TF2_COMP_FIXES_WINGER_JUMP_BONUS_WHEN_FULLY_DEPLOYED
#endinput
#endif
#define _TF2_COMP_FIXES_WINGER_JUMP_BONUS_WHEN_FULLY_DEPLOYED

#include "common.sp"
#include <dhooks>
#include <sdkhooks>
#include <sdktools>

#define ATTR_MOD_JUMP_HEIGHT_FROM_WEAPON (524)
#define WEAPON_ID_THE_WINGER             (449)

static ConVar g_convar;
static Handle g_call_CAttributeList_SetRuntimeAttributeValue;
static Handle g_call_CEconItemSchema_GetAttributeDefinition;
static Handle g_call_GEconItemSchema;
static Handle g_hook_CBaseCombatWeapon_Deploy;
static Handle g_timers[MAXENTITIES + 1] = {INVALID_HANDLE, ...};

void WingerJumpBonusWhenFullyDeployed_Setup(Handle game_config) {
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(game_config, SDKConf_Signature,
                            "CAttributeList::SetRuntimeAttributeValue");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
    if ((g_call_CAttributeList_SetRuntimeAttributeValue = EndPrepSDKCall()) == INVALID_HANDLE) {
        SetFailState("Failed to finalize SDK call to CAttributeList::SetRuntimeAttributeValue");
    }

    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(game_config, SDKConf_Signature,
                            "CEconItemSchema::GetAttributeDefinition");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    if ((g_call_CEconItemSchema_GetAttributeDefinition = EndPrepSDKCall()) == INVALID_HANDLE) {
        SetFailState("Failed to finalize SDK call to CEconItemSchema::GetAttributeDefinition");
    }

    StartPrepSDKCall(SDKCall_Static);
    PrepSDKCall_SetFromConf(game_config, SDKConf_Signature, "GEconItemSchema");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    if ((g_call_GEconItemSchema = EndPrepSDKCall()) == INVALID_HANDLE) {
        SetFailState("Failed to finalize SDK call to GEconItemSchema");
    }

    g_hook_CBaseCombatWeapon_Deploy =
        CheckedDHookCreateFromConf(game_config, "CBaseCombatWeapon::Deploy");

    g_convar = CreateBoolConVar("sm_winger_jump_bonus_when_fully_deployed", OnConVarChange);
}

void WingerJumpBonusWhenFullyDeployed_OnClientPutInServer(int client) {
    if (!g_convar.BoolValue) {
        return;
    }

    SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i)) {
            continue;
        }

        if (cvar.BoolValue) {
            SDKHook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
        } else {
            SDKUnhook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
        }
    }
}

static Action Hook_WeaponCanUse(int client, int weapon) {
    int weapon_id = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

    if (weapon_id != WEAPON_ID_THE_WINGER) {
        return Plugin_Continue;
    }

    DHookEntity(g_hook_CBaseCombatWeapon_Deploy, HOOK_PRE, weapon, _,
                Hook_CBaseCombatWeapon_Deploy);

    return Plugin_Continue;
}

static MRESReturn Hook_CBaseCombatWeapon_Deploy(int weapon, Handle ret) {
    if (!g_convar.BoolValue) {
        return MRES_Ignored;
    }

    if (g_timers[weapon] != INVALID_HANDLE) {
        KillTimer(g_timers[weapon]);
    }

    SetAttribute(weapon, ATTR_MOD_JUMP_HEIGHT_FROM_WEAPON, 1.0);

    g_timers[weapon] = CreateTimer(0.2, TimerFinished, weapon);

    return MRES_Handled;
}

static Action TimerFinished(Handle timer, int weapon) {
    if (!IsValidEntity(weapon)) {
        return Plugin_Continue;
    }

    SetAttribute(weapon, ATTR_MOD_JUMP_HEIGHT_FROM_WEAPON, 1.25);

    g_timers[weapon] = INVALID_HANDLE;

    return Plugin_Continue;
}

static void SetAttribute(int entity, int attribute, float value) {
    int     offset         = GetEntSendPropOffs(entity, "m_AttributeList", true);
    Address entity_pointer = GetEntityAddress(entity);
    Address schema         = SDKCall(g_call_GEconItemSchema);
    Address attribute_definition =
        SDKCall(g_call_CEconItemSchema_GetAttributeDefinition, schema, attribute);

    SDKCall(g_call_CAttributeList_SetRuntimeAttributeValue,
            entity_pointer + view_as<Address>(offset), attribute_definition, value);
}

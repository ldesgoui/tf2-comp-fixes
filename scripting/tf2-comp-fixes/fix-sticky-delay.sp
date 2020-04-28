#pragma semicolon 1
#pragma newdecls required

#include <tf2_stocks>
#include "utils.sp"

#define WEAPONSLOT_SECONDARY 1

ConVar g_fix_sticky_delay;
Handle g_secondary_attack;

void SetupFixStickyDelay(Handle game_config) {
    g_fix_sticky_delay = CreateBoolConVar("sm_fix_sticky_delay");

    StartPrepSDKCall(SDKCall_Entity);

    if (!PrepSDKCall_SetFromConf(game_config, SDKConf_Virtual,
                "CTFWeaponBase::SecondaryAttack")) {
        SetFailState("Failed to load CTFWeaponBase::SecondaryAttack offset "
                ... "from gamedata");
    }

    g_secondary_attack = EndPrepSDKCall();

    if (g_secondary_attack == INVALID_HANDLE) {
        SetFailState("Failed to finalize SDK call to CTFWeaponBase::SecondaryAttack");
    }
}

void FixStickyDelay(int client, int &buttons) {
    int weapon, item_id;

    if (g_fix_sticky_delay.BoolValue
            && buttons & IN_ATTACK2
            && IsPlayerAlive(client)
            && TF2_GetPlayerClass(client) == TFClass_DemoMan
            && (weapon = GetPlayerWeaponSlot(client, WEAPONSLOT_SECONDARY))
            && weapon != -1
            && (item_id = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
            && item_id != -1
            && item_id != 131   // The Chargin' Targe
            && item_id != 406   // The Splendid Screen
            && item_id != 1099  // The Tide Turner
            && item_id != 1144  // Festive Targe
       ) {
        SDKCall(g_secondary_attack, weapon);
    }
}

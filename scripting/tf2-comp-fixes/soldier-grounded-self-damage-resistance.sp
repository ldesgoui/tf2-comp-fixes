static Handle g_detour_CTFPlayer_OnTakeDamage_Alive;

static int g_offset_CTakeDamageInfo_m_hAttacker;
static int g_offset_CTakeDamageInfo_m_flDamage;
static int g_offset_CTakeDamageInfo_m_bitsDamageType;

void SoldierGroundedSelfDamageResistance_Setup(Handle game_config) {
    g_detour_CTFPlayer_OnTakeDamage_Alive = 
        CheckedDHookCreateFromConf(game_config, "CTFPlayer::OnTakeDamage_Alive");

    g_offset_CTakeDamageInfo_m_hAttacker = 
        CheckedGameConfGetKeyValueInt(game_config, "CTakeDamageInfo::m_hAttacker");
    g_offset_CTakeDamageInfo_m_flDamage = 
        CheckedGameConfGetKeyValueInt(game_config, "CTakeDamageInfo::m_flDamage");
    g_offset_CTakeDamageInfo_m_bitsDamageType = 
        CheckedGameConfGetKeyValueInt(game_config, "CTakeDamageInfo::m_bitsDamageType");

    CreateBoolConVar("sm_soldier_grounded_self_damage_resistance", WhenConVarChange);
}

static void WhenConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) return;
    
    if (!DHookToggleDetour(g_detour_CTFPlayer_OnTakeDamage_Alive, HOOK_PRE,
                           Detour_CTFPlayer_OnTakeDamage_Alive, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFPlayer_OnTakeDamage_Alive");
    }
}

static MRESReturn Detour_CTFPlayer_OnTakeDamage_Alive(int pVictim, Handle hReturn, DHookParam hParams) {
    int pAttacker = DHookGetParamObjectPtrVar(hParams, 1, g_offset_CTakeDamageInfo_m_hAttacker,
                                              ObjectValueType_Ehandle);

    if (pVictim != pAttacker || TF2_GetPlayerClass(pAttacker) != TFClass_Soldier ||
        !(GetEntityFlags(pAttacker) & FL_ONGROUND)) return MRES_Ignored;
    
    int damage_type = DHookGetParamObjectPtrVar(hParams, 1, g_offset_CTakeDamageInfo_m_bitsDamageType,
                                                ObjectValueType_Int);
    if (!(damage_type & DMG_BLAST)) return MRES_Ignored;

    LogDebug("Applying self-damage resistance");

    float damage = DHookGetParamObjectPtrVar(hParams, 1, g_offset_CTakeDamageInfo_m_flDamage,
                                             ObjectValueType_Float);

    damage *= FindConVar("tf_damagescale_self_soldier").FloatValue;                                                       
    DHookSetParamObjectPtrVar(hParams, 1, g_offset_CTakeDamageInfo_m_flDamage,
                              ObjectValueType_Float, damage);

    return MRES_Handled;
}

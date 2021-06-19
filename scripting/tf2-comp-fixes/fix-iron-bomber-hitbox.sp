#define PIPE_SIZE 2.0

static Handle g_call_CBaseEntity_SetCollisionBounds;
static Handle g_detour_CTFWeaponBaseGun_FirePipeBomb;

void FixIronBomberHitbox_Setup(Handle game_config) {
    StartPrepSDKCall(SDKCall_Entity);

    if (!PrepSDKCall_SetFromConf(game_config, SDKConf_Signature, "CBaseEntity::SetCollisionBounds")) {
        SetFailState("Failed to finalize SDK call to BaseEntity::SetCollisionBounds");
    }

    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
    PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);

    g_call_CBaseEntity_SetCollisionBounds = EndPrepSDKCall();
    g_detour_CTFWeaponBaseGun_FirePipeBomb = CheckedDHookCreateFromConf(game_config, "CTFWeaponBaseGun::FirePipeBomb");

    CreateBoolConVar("sm_fix_iron_bomber_hitbox", OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFWeaponBaseGun_FirePipeBomb, HOOK_POST,
                           Detour_CTFWeaponBaseGun_FirePipeBomb, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFWeaponBaseGun::FirePipeBomb");
    }
}

static MRESReturn Detour_CTFWeaponBaseGun_FirePipeBomb(Handle hReturn, Handle hParams) {
    int entity = DHookGetReturn(hReturn);
    
    if (entity == -1) {
        return MRES_Ignored;
    }

    float vec[3];
    GetEntPropVector(entity, Prop_Data, "m_vecMaxs", vec);

    if (vec[0] == PIPE_SIZE) {
        return MRES_Ignored;
    }

    //PrintToServer("before %f", vec[0]);

    float vecMins[3] = { -PIPE_SIZE, -PIPE_SIZE, -PIPE_SIZE };
    float vecMaxs[3] = { PIPE_SIZE, PIPE_SIZE, PIPE_SIZE };

    SDKCall(g_call_CBaseEntity_SetCollisionBounds, entity, vecMins, vecMaxs);

    //GetEntPropVector(entity, Prop_Data, "m_vecMaxs", vec);
    //PrintToServer("after %f", vec[0]);

    return MRES_Handled;
}

Handle g_detour_CTFBaseRocket_RocketTouch;

void ProjectilesCollideOnCylinders_Setup(Handle game_config) {
    g_detour_CTFBaseRocket_RocketTouch =
        CheckedDHookCreateFromConf(game_config, "CTFBaseRocket::RocketTouch");

    CreateBoolConVar("sm_projectiles_collide_on_cylinders", WhenConVarChange);
}

static void WhenConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    DHookToggleEntityListener(ListenType_Created, WhenEntityCreated, cvar.BoolValue);
}

static void WhenEntityCreated(int entity, const char[] classname) {
    if (StrContains(classname, "tf_projectile_") != 0) {
        return;
    }

    if (StrEqual(classname[14], "rocket")) {
        if (INVALID_HOOK_ID == DHookEntity(g_detour_CTFBaseRocket_RocketTouch,
                                           HOOK_PRE, entity, _,
                                           Hook_Touch)) {
            SetFailState("Failed to hook CTFBaseRocket::RocketTouch");
        }
    }

    // ArrowTouch
    // PipebombTouch
    // ProjectileTouch
    // RocketTouch

    /*
    if (INVALID_HOOK_ID == DHookEntity(g_detour_CTFGrenadePipebombProjectile_PipebombTouch,
                                       HOOK_PRE, entity, _,
                                       Hook_Touch)) {
        SetFailState("Failed to hook CTFGrenadePipebombProjectile::PipebombTouch");
    }
    */
}

static MRESReturn Hook_Touch(int self, Handle params) {
    int other = DHookGetParam(params, 1);

    if (other <= 0 || other > MaxClients) {
        return MRES_Ignored;
    }

    float self_pos[3], other_pos[3], other_mins[3], other_maxs[3];

    GetEntPropVector(self, Prop_Send, "m_vecOrigin", self_pos);
    GetEntPropVector(other, Prop_Send, "m_vecOrigin", other_pos);
    GetEntPropVector(other, Prop_Send, "m_vecMins", other_mins);
    GetEntPropVector(other, Prop_Send, "m_vecMaxs", other_maxs);

    float width = other_maxs[X] - other_mins[X],
          depth = other_maxs[Z] - other_mins[Z],
          radius = (width < depth ? width : depth) / 2.0,
          dx = self_pos[X] - other_pos[X],
          dz = self_pos[Z] - other_pos[Z];

    if (dx*dx + dz*dz > radius*radius) {
        LogDebug("Projectile is in AABB but not cylinder");
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

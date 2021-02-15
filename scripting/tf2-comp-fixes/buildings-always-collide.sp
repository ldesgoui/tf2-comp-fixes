void BuildingsAlwaysCollide_Setup() {
    CreateBoolConVar("sm_buildings_always_collide", OnConVarChange);
}

static void OnConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    DHookToggleEntityListener(ListenType_Created, OnEntityCreated, cvar.BoolValue);
}

static void OnEntityCreated(int entity, const char[] classname) {
    if (!StrEqual(classname, "obj_sentrygun") && !StrEqual(classname, "obj_dispenser")) {
        return;
    }

    LogDebug("hooking %d", entity);

    SDKHook(entity, SDKHook_ShouldCollide, Hook_ShouldCollide); 
}

static bool Hook_ShouldCollide(int entity, int collisiongroup, int contentsmask, bool result) {
    LogDebug("hooked %d hitting", entity);
    return true;
}

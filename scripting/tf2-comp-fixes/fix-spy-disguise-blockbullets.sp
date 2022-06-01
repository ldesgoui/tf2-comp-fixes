static ConVar g_convar;

void SpyBlockbulletFix_Setup() {
    g_convar = CreateBoolConVar("sm_fix_spy_disguise_blockbullets", WhenConVarChange);
}

static void WhenConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }   

    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "tf_weapon_*")) != -1) {      
        if (cvar.BoolValue) {
            SpyBlockbulletFix_ReqFrame(entity);
        } else {
            //
        }   
    }
}


void SpyBlockbulletFix_OnEntityCreated(int entity, const char[] classname)
{
    if (!g_convar.BoolValue) {
        return;
    }
    if (StrContains(classname, "tf_weapon_", false) == -1) {
        return;
    }

    // wait a frame so ownerid is valid
    RequestFrame(SpyBlockbulletFix_ReqFrame, entity);
}

void SpyBlockbulletFix_ReqFrame(int entity)
{
    // make sure actual entity itself is still valid
    if (entity < 1 || !IsValidEntity(entity))
    {
        return;
    }

    // grab the weapon's owner entity's id
    int ownerid = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    // if it's -1, it's almost certainly a spy ghost weapon
    // todo: whatabout m_bDisguiseWeapon?
    if (ownerid == -1)
    {
        // yeet it.
        TeleportEntity(entity, view_as<float>({0.0, 0.0, -5000.0}), NULL_VECTOR, NULL_VECTOR);
        // we could set the collision here but it's finnicky and depends on sm1.11 technology -
        // SetEntityCollisionGroup()
    }
}

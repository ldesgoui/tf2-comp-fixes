public 
void OnEntityCreated(int entity, const char[] classname)
{
    // wait a frame so ownerid is valid
    RequestFrame(waitFrame, entity, classname);
}

void waitFrame(int entity, const char[] classname)
{
    // make sure actual entity itself is still valid
    if (entity < 1 || !IsValidEntity(entity))
    {
        return;
    }

    // check if entity is a tf_weapon
    if (StrContains(classname, "tf_weapon_", false) != -1)
    {
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
}

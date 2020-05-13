# Internals

These may get out of date.

## Reverse Engineering

I use [NSA's Ghidra](https://ghidra-sre.org) to analyse the following files:

- `steam/steamapps/common/Team Fortress 2 Dedicated Server/tf/bin/server_srv.so`
- `steam/steamapps/common/Team Fortress 2 Dedicated Server/tf/bin/server.dll`

The process requires some knowledge of C and C++.

The auto-analysis will take in the range of half an hour to a couple hours.
If it results in lots of errors on Ghidra 9.1.2, try downgrading to 9.1 temporarily.

The Linux binary (`server_srv.so`) is unstripped, which means it contains the symbols unmodified.
This is particularly helpful to research and prototype.
The Windows binary does not contain any debugging information.

[DepotDownloader](https://github.com/SteamRE/DepotDownloader)
can be used to download previous versions of the binaries alongside
[steamdb.info](https://steamdb.info/app/232250).

## Remove Medic Attach Speed

The method `CTFPlayer::TeamFortress_CalculateMaxSpeed(this, bool)` contains the behavior
we are trying to change, consider the following pseudocode:

```cpp
float CTFPlayer::TeamFortress_CalculateMaxSpeed(CTFPlayer *this, param) {
    // ..

    float max_speed = 0.0;
    auto active_weapon = CBaseCombatCharacter::GetActiveWeapon(this);

    // ..

    if (this->class == Medic) {
        max_speed = MEDIC_MAX_SPEED;

        if (active_weapon != NULL
                && (medigun = dynamic_cast<CTFWeaponMedigun *>(active_weapon) )
                && medigun != NULL
                && medigun->target_id != INVALID_TARGET) {

            auto medigun_type = CWeaponMedigun::GetMedigunType(medigun);
            auto medigun_target = g_players[medigun->target_id];

            if (medigun_type == 2 // Quick-Fix
                    && CTFPlayerShared::InCond(medigun_target, COND_SHIELD_CHARGING)) {
                max_speed = g_tf_max_charge_speed;
            } else {
                float medigun_target_speed =
                    CTFPlayer::TeamFortress_CalculateMaxSpeed(medigun_target, true),

                // -- WE DON'T WANT THIS
                if (medigun_target_speed > max_speed) {
                    max_speed = medigun_target_speed;
                }
                // -- WE DON'T WANT THIS
            }
        }
    }

    // ..

    return max_speed;
}
```

In this, we see that `CTFPlayer::TeamFortress_CalculateMaxSpeed` is called to get the speed of
the medigun target.
The boolean parameter is set to true, and that is the only occurence in the binary.
This parameter probably exists to ignore the max speed achieved when a demoman is charging with a shield,
and instead fetches the max speed while not charging.

We can easily patch this behavior by hooking `CTFPlayer::TeamFortress_CalculateMaxSpeed` itself
and returning `0.0` when this parameter is set to true.
Obviously, this applies to all mediguns, the Quick-Fix included.
The Quick-Fix still benefits from the speed boost while a demoman is charging.

## Fix Ghost Crossbow Bolts & Projectiles Ignore Teammates

The method `bool CBaseProjectile::CanCollideWithTeammates(*this)` simply returns a field (TODO: find name),
this field is initialized to false and is set to true after some time, depending on what
`float CBaseProjectile::GetCollideWithTeammatesDelay()` returns (250ms by default).
`CTFProjectile_HealingBolt` overrides `GetCollideWithTeammatesDelay` to always return 0ms.
`CTFProjectile_GrapplingHook` overrides `CanCollideWithTeammates` to always return false.

Considering we're given the `this` pointer, we can dereference it once to find the address
of the current instance's virtual function table.
This lets us compare it to the (I believe called) RTTI symbol for `CTFProjectile_HealingBolt`,
`_ZTV25CTFProjectile_HealingBolt`, which is 8 bytes earlier in memory.
If they match, it is a crossbow bolt, and we can return true, which will cause the projectile to hit
teammates at a very close range.

Otherwise, we can just return false in order to have projectiles ignore teammates.


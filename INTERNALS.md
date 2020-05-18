# Internals

These may get out of date.

## Reverse Engineering

I use [NSA's Ghidra](https://ghidra-sre.org) to analyse the following files:

- `steam/steamapps/common/Team Fortress 2 Dedicated Server/tf/bin/server_srv.so`
- `steam/steamapps/common/Team Fortress 2 Dedicated Server/tf/bin/server.dll`

The process requires some knowledge of C and C++.

The auto-analysis will take in the range of half an hour to a couple hours. If
it results in lots of errors on Ghidra 9.1.2, try downgrading to 9.1
temporarily.

The Linux binary (`server_srv.so`) is unstripped, which means it contains the
symbols unmodified. This is particularly helpful to research and prototype. The
Windows binary does not contain any debugging information.

[DepotDownloader](https://github.com/SteamRE/DepotDownloader) can be used to
download previous versions of the binaries alongside
[steamdb.info](https://steamdb.info/app/232250).

## Leaks

Some leak of the source code before Jungle Inferno can easily be found online,
the search term `hl2_src` should give you succesful results.

## Remove Medic Attach Speed

The method `CTFPlayer::TeamFortress_CalculateMaxSpeed(this, bool)` contains the
behavior we are trying to change, consider the following pseudocode:

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

In this, we see that `CTFPlayer::TeamFortress_CalculateMaxSpeed` is called to
get the speed of the medigun target. The boolean parameter is set to true, and
that is the only occurence in the binary. This parameter probably exists to
ignore the max speed achieved when a demoman is charging with a shield, and
instead fetches the max speed while not charging.

We can easily patch this behavior by hooking
`CTFPlayer::TeamFortress_CalculateMaxSpeed` itself and returning `0.0` when this
parameter is set to true. Obviously, this applies to all mediguns, the Quick-Fix
included. The Quick-Fix still benefits from the speed boost while a demoman is
charging.

## Fix Ghost Crossbow Bolts & Projectiles Ignore Teammates

The virtual method `bool CBaseProjectile::CanCollideWithTeammates(*this)`
returns the field `m_bCanCollideWithTeammates` which is initialized to false and
updated to true during `CollideWithTeammatesThink`. `CBaseProjectile::Spawn()`
schedules this `Think` to execute after
`gpGlobals->curtime + GetCollideWithTeammatesDelay()`, the latter returning
250ms by default. The file concerned is `game/shared/baseprojectile.cpp`.

`CTFProjectile_HealingBolt` overrides `GetCollideWithTeammatesDelay` to always
return 0ms, however the projectile obviously doesn't collide with teammates as
soon as it spawns. I believe this behavior to not be expected, the intent seems
to want it collide as soon as possible but it seems that `Think`s are only
precise over a few server ticks.

One could argue that developers were aware of the effects of both methods as
`CTFProjectile_GrapplingHook`, which is just below and shares its mother class
with `CTFProjectile_HealingBolt`, and simply overrides `CanCollideWithTeammates`
to always return false. I don't believe this to be a fair assessment. Grappling
hooks were added later on, and the only way to implement the logic to ignore
teammates would have been by overriding `CanCollideWithTeammates` (or
`CollideWithTeammatesThink`), possibly creating the need for a virtual method
altogether. In this case, as the behaviors are different and as the Crossbow's
current implementation was probably not known to be an issue, it was overlooked
and was not updated. The file concerned is
`game/server/tf/tf_projectile_arrow.cpp`.

On entity creation, we can simply hook this virtual method to always return true
when the classname is `tf_projectile_healing_bolt`, or otherwise false if it
starts with `tf_projectile_`.

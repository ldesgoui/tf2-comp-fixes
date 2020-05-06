# TF2 Competitive Fixes

Various technical or gameplay changes catered towards competitive play


### Usage

The `sm_cf` command is available to users with the SourceMod admin level `cvar` (flag `h`), or via RCON.

`sm_cf list` lists all available cvars.

`sm_cf all` enables everything.

`sm_cf none` disables everything.

`sm_cf fixes` enables 
`sm_deterministic_fall_damage 1`, 
`sm_fix_ghost_crossbow_bolts 1`, 
`sm_fix_slope_bug 1`, 
`sm_fix_sticky_delay 1`, 
`sm_projectiles_ignore_teammates 1`, 
`sm_remove_halloween_souls 1`,
`sm_rest_in_peace_rick_may 128`.


### Features

#### Fixes

- **Deterministic Fall Damage**

    When enabled with `sm_deterministic_fall_damage 1`,
    the random variable in fall damage calculation will be removed. 

    Credits to the existing plugin https://github.com/stephanieLGBT/tf2-FallDamageFixer

- **Fixes Ghost Crossbow Bolts**

    When enabled with `sm_fix_ghost_crossbow_bolts 1`,
    crossbow bolts will no longer pass through teammates when in close range.

- **Fixes Slope Bugs**

    When enabled with `sm_fix_slope_bug 1`,
    players won't stop while sliding on slopes anymore.

    Credits to the existing plugin https://github.com/laurirasanen/groundfix

- **Fixes Sticky Delay**

    When enabled with `sm_fix_sticky_delay 1`,
    stickies will no longer fail to detonate when swapping weapons.

- **Ghostify Soldier Statues**

    When enabled with `sm_rest_in_peace_rick_may [1 .. 255]`,
    the commemorative Soldier statues will become transparent 
    (values near 0 being opaque, 255 being invisible),
    and will not collide with players, shots or projectiles.

- **Projectiles Ignore Teammates**

    When enabled with `sm_projectiles_ignore_teammates 1`,
    projectiles will pass through teammates (but not friendly buildings).

- **Removes Halloween Souls**

    When enabled with `sm_remove_halloween_souls 1`,
    no souls will be spawned during the Halloween holiday events.

#### Gameplay Changes

- **Gunboats Always Apply**

    When enabled with `sm_gunboats_always_apply 1`,
    gunboats resistance will apply even if hitting an enemy.

- **Removes Medic Attach Speed**

    When enabled with `sm_remove_medic_attach_speed 1`,
    the Medic will not run as fast as its target if the target is faster.


## Installation

This plugin depends on the 
[DHooks2 Extension with detour support](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589)

Download the latest releases from the following links to 
`steam/steamapps/common/Team Fortress 2 Dedicated Server/tf` and unzip them:
- https://github.com/peace-maker/DHooks2/releases/latest
- https://github.com/ldesgoui/tf2-comp-fixes/releases/latest


This plugin supports auto-updating using 
[Updater](https://forums.alliedmods.net/showthread.php?t=169095)


## Internals

### Reverse Engineering

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

### Remove Medic Attach Speed

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

### Fix Ghost Crossbow Bolts & Projectiles Ignore Teammates

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

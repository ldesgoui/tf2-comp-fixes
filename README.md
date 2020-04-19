# TF2 Competitive Fixes

Various technical or gameplay altering changes catered towards competitive play

This plugin only support Linux servers.

### Features

- **Fixes Sticky Delay**

    When enabled with `sm_fix_sticky_delay 1`,
    stickies will no longer fail to detonate when swapping weapons.

- **Fixes Ghost Crossbow Bolts**

    When enabled with `sm_fix_ghost_crossbow_bolts 1`,
    crossbow bolts will no longer pass through teammates when in close range.

- **Removes Medic Attach Speed**

    When enabled with `sm_remove_medic_attach_speed 1`,
    the Medic will not run as fast as its target if the target is faster.

- **Projectiles Ignore Teammates**

    When enabled with `sm_projectiles_ignore_teammates 1`,
    projectiles will pass through teammates (but not friendly buildings).

- **Removes Upper Bound On `mp_bonusroundtime`**

## Installation

Download [DHooks](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589)
and https://github.com/ldesgoui/tf2-comp-fixes/archive/master.zip 
to `steam/steamapps/common/Team Fortress 2 Dedicated Server/tf` and unzip them.

## Internals

### Remove Medic Attach Speed

When enabled, the Medic will not run as fast as its healing target when said target is faster.

The function `CTFPlayer::TeamFortress_CalculateMaxSpeed(this, bool)` contains the behavior we
are trying to change, consider the following pseudocode:

```cpp
double CTFPlayer::TeamFortress_CalculateMaxSpeed(CTFPlayer *this, param) {
    // ..

    double max_speed = 0.0;
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
                double medigun_target_speed =
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
the medigun target. The boolean parameter is set to true, and that is the only occurence in the
binary. This parameter probably exists to ignore the max speed achieved when a demoman is charging
with a shield, and instead fetches the max speed while not charging.

We can easily patch this behavior by hooking `CTFPlayer::TeamFortress_CalculateMaxSpeed` itself
and returning `0.0` when this parameter is set to true.
Obviously, this applies to all mediguns, the Quick-Fix included.
The Quick-Fix still benefits from the speed boost while a demoman is charging.

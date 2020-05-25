# TF2 Competitive Fixes

Various technical or gameplay changes catered towards competitive play

[_Release notes_](https://github.com/ldesgoui/tf2-comp-fixes/releases)

### Usage

`sm_cf list` (or `!cf list` in chat) lists all available cvars with their
current values, and is available to everyone.

`sm_cf <PRESET>` (or `!cf <PRESET>` in chat) is available to all with the
SourceMod admin level `cvar` (flag `h`), or via RCON. On
[serveme.tf](https://serveme.tf), the command is available to the owner of a
premium reservation without having to use RCON. Thank to Arie for providing
these servers. It changes cvars in bulk according to the following:

|                                          | all | fixes | etf2l | ozf | rgl | none |
| ---------------------------------------- | --- | ----- | ----- | --- | --- | ---- |
| sm_deterministic_fall_damage             | 1   | 1     | 1     | 0   | 1   | 0    |
| sm_fix_ghost_crossbow_bolts              | 1   | 1     | 1     | 0   | 1   | 0    |
| sm_fix_slope_bug                         | 1   | 1     | 1     | 1   | 1   | 0    |
| sm_fix_sticky_delay                      | 1   | 1     | 1     | 1   | 1   | 0    |
| sm_gunboats_always_apply                 | 1   | 0     | 0     | 0   | 0   | 0    |
| sm_projectiles_ignore_teammates          | 1   | 1     | 0     | 0   | 0   | 0    |
| sm_remove_halloween_souls                | 1   | 1     | 1     | 0   | 1   | 0    |
| sm_remove_medic_attach_speed             | 1   | 0     | 0     | 0   | 0   | 0    |
| sm_remove_pipe_spin                      | 1   | 1     | 0     | 0   | 0   | 0    |
| sm_rest_in_peace_rick_may                | 128 | 128   | 0     | 255 | 128 | 0    |
| sm_winger_jump_bonus_when_fully_deployed | 1   | 0     | 0     | 0   | 0   | 0    |

Every feature will be enabled or disabled immediately except for features that
hook short-lived entities, in which case the feature will apply if the entity
was created when the feature was enabled. For now this includes:
`sm_fix_ghost_crossbow_bolts`, `sm_projectiles_ignore_teammates`,
`sm_remove_pipe_spin`.

### Features

#### Fixes

- **Deterministic Fall Damage**

  When enabled with `sm_deterministic_fall_damage 1`, the random variable in
  fall damage calculation will be removed.

  Credits to the existing plugin
  https://github.com/stephanieLGBT/tf2-FallDamageFixer

- **Fixes Ghost Crossbow Bolts**

  When enabled with `sm_fix_ghost_crossbow_bolts 1`, crossbow bolts will no
  longer pass through teammates when in close range.

- **Fixes Slope Bugs**

  When enabled with `sm_fix_slope_bug 1`, players won't stop while sliding on
  slopes anymore.

  Credits to the existing plugin https://github.com/laurirasanen/groundfix

- **Fixes Sticky Delay**

  When enabled with `sm_fix_sticky_delay 1`, stickies will no longer fail to
  detonate when swapping weapons.

- **Ghostify Soldier Statues**

  When enabled with `sm_rest_in_peace_rick_may [1 .. 255]`, the commemorative
  Soldier statues will become transparent (values near 0 being opaque, 255 being
  invisible), and will not collide with players, shots or projectiles.

- **Projectiles Ignore Teammates**

  When enabled with `sm_projectiles_ignore_teammates 1`, projectiles will pass
  through teammates (but not friendly buildings).

- **Removes Halloween Souls**

  When enabled with `sm_remove_halloween_souls 1`, no souls will be spawned
  during the Halloween holiday events.

- **Remove Pipe Spin**

  When enabled with `sm_remove_pipe_spin 1`, pipes will not spawn with a random
  rotation.

- **Tournament Match End Ignores Whitelist**

  Enabled by default with `sm_tournament_end_ignores_whitelist 1`, the whitelist
  will not be executed at the end of a `mp_tournament` match.

#### Gameplay Changes

- **Gunboats Always Apply**

  When enabled with `sm_gunboats_always_apply 1`, gunboats resistance will apply
  even if hitting an enemy.

- **Removes Medic Attach Speed**

  When enabled with `sm_remove_medic_attach_speed 1`, the Medic will not run as
  fast as its target if the target is faster.

- **Winger Jump Bonus Applies When Fully Deployed**

  When enabled with `sm_winger_jump_bonus_when_fully_deployed 1`, the Winger's
  jump bonus will only take effect when the weapon is fully deployed. (TODO: for
  now, hardcoded as 200ms after the player switches to the weapon)

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

You can read on how some of these changes were implemented [here](INTERNALS.md).

# TF2 Competitive Fixes

Various technical or gameplay changes catered towards competitive play

[_Release notes_](https://github.com/ldesgoui/tf2-comp-fixes/releases)

### Usage

`sm_cf` (or `!cf` in chat) displays the current running version.

`sm_cf list` (or `!cf list` in chat) lists all available cvars with their
current values, and is available to everyone.

`sm_cf <PRESET>` (or `!cf <PRESET>` in chat) is available to all with the
SourceMod admin level `cvar` (flag `h`), or via RCON. On
[serveme.tf](https://serveme.tf), the command is available to the owner of a
premium reservation without having to use RCON. Thank to Arie for providing
these servers. It changes cvars in bulk according to the following:

|                                          | all | fixes | none |  asf | etf2l | ozf | rgl |
| ---------------------------------------- | --- | ----- | ---- |  --- | ----- | --- | --- |
| sm_deterministic_fall_damage             | 1   | 1     | 0    |  1   | 1     | 0   | 1   |
| sm_empty_active_ubercharges_when_dropped | 1   | 1     | 0    |  0   | 0     | 0   | 1   |
| sm_fix_ghost_crossbow_bolts              | 1   | 1     | 0    |  0   | 1     | 1   | 1   |
| sm_fix_post_pause_state                  | 1   | 1     | 0    |  0   | 0     | 0   | 0   |
| sm_fix_slope_bug                         | 1   | 1     | 0    |  1   | 1     | 1   | 1   |
| sm_fix_sticky_delay                      | 1   | 1     | 0    |  0   | 1     | 1   | 1   |
| sm_inhibit_extendfreeze                  | 1   | 1     | 0    |  0   | 0     | 0   | 0   |
| sm_override_pipe_size                    | 4.0 | 4.0   | 0    |  0   | 0     | 0   | 0   |
| sm_projectiles_ignore_teammates          | 1   | 1     | 0    |  1   | 1     | 0   | 0   |
| sm_remove_halloween_souls                | 1   | 1     | 0    |  0   | 1     | 1   | 1   |
| sm_remove_pipe_spin                      | 1   | 0     | 0    |  0   | 0     | 0   | 0   |
| sm_rest_in_peace_rick_may                | 128 | 128   | 0    |  0   | 0     | 255 | 128 |
|                                          |     |       |      |      |       |     |     |
| sm_gunboats_always_apply                 | 1   | 0     | 0    |  0   | 1     | 0   | 0   |
| sm_remove_medic_attach_speed             | 1   | 0     | 0    |  0   | 0     | 0   | 0   |
| sm_solid_buildings                       | 1   | 0     | 0    |  0   | 0     | 0   | 0   |
| sm_winger_jump_bonus_when_fully_deployed | 1   | 0     | 0    |  0   | 1     | 0   | 0   |

**Leagues should not rely on presets as part of their server configurations,
except for `none`**

_Presets were updated on 2021-12-09._

### Features

#### Fixes

- **Deterministic Fall Damage**

  When enabled with `sm_deterministic_fall_damage 1`, the random variable in
  fall damage calculation will be removed.

  Credits to the existing plugin
  https://github.com/stephanieLGBT/tf2-FallDamageFixer

- **Empty active ubercharges when the medigun is dropped**

  When enabled with `sm_empty_active_ubercharges_when_dropped 1`, mediguns that
  are dropped while the ubercharge is active will be emptied.  
  This prevents the exploit of swapping mediguns while uberchargeded to conserve
  some of the charge.

- **Fixes Ghost Crossbow Bolts**

  When enabled with `sm_fix_ghost_crossbow_bolts 1`, crossbow bolts will no
  longer pass through teammates when in close range.

- **Revert state after unpausing**

  When enabled with `sm_fix_post_pause_state 1`, gameplay state that changed
  because of the UserCmd handling bug will be restored to what it was before
  the pause. For now, this includes:

  - Medigun ubercharge

- **Fixes Slope Bugs**

  When enabled with `sm_fix_slope_bug 1`, players won't stop while sliding on
  slopes anymore.

  Credits to the existing plugin https://github.com/laurirasanen/groundfix

- **Fixes Sticky Delay**

  When enabled with `sm_fix_sticky_delay 1`, stickies will no longer fail to
  detonate when swapping weapons.

- **Inhibit `extendfreeze`**

  When enabled with `sm_inhibit_extendfreeze 1`, clients will not be able to use
  the `extendfreeze` command.  
  This prevents some information leak, players can use this command after dying
  to spectate their killer in third person.  
  This slightly alters the handling of freezecams and may result in reduced
  spawn timers of at most 2 seconds across the board.

  [Demonstration of the info leak in this video](https://youtu.be/WHGVAJgHMX8?t=371)

- **Override Pipe Collider Size**

  When enabled with `sm_override_pipe_size [1 .. ]`, all pipes will have their
  collider resized to that value in Hammer Units.  
  The size of official pipes is 4.0, except for Iron Bomber, which is 8.75 wide
  and 7.71424 tall.

  Credits for implementing go to https://github.com/bodolaz146

- **Projectiles Ignore Teammates**

  When enabled with `sm_projectiles_ignore_teammates 1`, projectiles will pass
  through teammates (but not friendly buildings).

- **Removes Halloween Souls**

  When enabled with `sm_remove_halloween_souls 1`, no souls will be spawned
  during the Halloween holiday events.

- **Remove Pipe Spin**

  When enabled with `sm_remove_pipe_spin 1`, pipes will not spawn with a random
  rotation, similarly to Loch-n-Load pipes

- **Ghostify Soldier Statues**

  When enabled with `sm_rest_in_peace_rick_may [1 .. 255]`, the commemorative
  Soldier statues will become transparent (values near 0 being opaque, 255 being
  invisible), and will not collide with players, shots or projectiles.

- **Tournament Match End Ignores Whitelist**

  _Enabled by default_ with `sm_tournament_end_ignores_whitelist 1`, the whitelist
  will not be executed at the end of a `mp_tournament` match.

#### Gameplay Changes

- **Gunboats Always Apply**

  When enabled with `sm_gunboats_always_apply 1`, gunboats resistance will apply
  even if hitting an enemy.

- **Removes Medic Attach Speed**

  When enabled with `sm_remove_medic_attach_speed 1`, the Medic will not run as
  fast as its target if the target is faster.

- **Make Engineer buildings solid**

  When enabled with `sm_solid_buildings 1`, the Engineer's Dispenser and
  Sentry gun will be solid to teammates.

- **Winger Jump Bonus Applies When Fully Deployed**

  When enabled with `sm_winger_jump_bonus_when_fully_deployed 1`, the Winger's
  jump bonus will only take effect when the weapon is fully deployed.

#### Other

- **Concede Command**

  _This command is deprecated and will be removed in a future update._

  When enabled with `sm_concede_command 1`, teams will be able to type
  `!concede`/`/concede` in chat to concede the match.  
  `sm_concede_command_vote n` adds the requirement for `n` players to type the
  command before the match is conceded.  
  `sm_concede_command_timeleft n` makes the command only available when `n`
  minutes are left on the map timer.  
  ATTENTION: This only really works for 5CP maps and *needs* to be disabled on
  other map types.

#### Note

Every feature is active immediately when the cvar is enabled except for features
that hook short-lived entities, in which case the feature will apply if the
entity was created when the feature was enabled. For now this includes:

- `sm_fix_ghost_crossbow_bolts`
- `sm_override_pipe_size`
- `sm_projectiles_ignore_teammates`
- `sm_remove_pipe_spin`

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

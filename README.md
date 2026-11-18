# Cause And Effect

BO7 Zombies port (Kronos) of **Cause And Effect**, the BO3 mod by LogisticalReaper, ported with the author's permission.

**Test version**: the effects are not all tested in game yet. Please report anything that breaks.

## How it works

- At the start of the match an options screen lets you pick the rules (ADS / FIRE or the arrows to move, USE or Enter to select):
  - **Effects stack**: effects are not removed when new ones are added
  - **Allow illegal combos**: combos that contradict each other, such as "killing zombies spawns zombies"
  - **No repeat combos**: a combo is never used twice
- Every round a random **cause** is paired with a random **effect**. Each time the cause happens, the effect fires.
- The current combo is shown top left, the roll is shown top center.

## Causes (15)

- when a perk is purchased
- when a powerup spawns
- when a zombie spawns
- when a zombie dies
- when a player takes damage
- when a player gets a headshot
- when a zombie dies to a grenade
- when a player earns 100+ points
- when a player loses 300+ points
- when a player loses 1000+ points
- when a door is purchased
- when a player reloads
- when a player swaps weapons
- when a gumball is eaten
- when a player slides

## Effects (40)

- a zombie spawns / 5 zombies spawn
- a random perk is lost / gained
- gain or lose 100 points, gain or lose 10 percent of your total points
- activate a random gobblegum effect, give a random gobblegum
- give a random gun, give a random paped gun
- held gun becomes paped / un-paped, toggles being paped
- spawn a random powerup, open a random door
- player speed is randomised
- wallbuy prices are randomised, wallbuys are randomised
- an earthquake occurs
- a random zombie dies, a random player drops a grenade
- the mystery box moves
- active weapon gets random attachments
- players orientation is slightly changed, a random player is slightly moved
- a random zombie triggers an AAT, players gun gets a random AAT, players AAT is removed
- players take 1 damage
- sprint, ADS, slide and jump toggle
- players gun gets a random camo
- all zombies gain 10 percent of their max health
- a random zombie teleports near a player
- perks randomize their locations
- active gun loses a bullet

## Known limits

- The HUD shows on the host only in co-op.
- Wallbuy ammo may keep its original price when prices are randomised.
- The camo effect refills the gun's ammo.

## Install

Use [FuzMods](https://github.com/Fuzion28/fuzmods), or copy `mod.json`, `scripts/` and `lua/` to `kronos/mods/cne/`.

## Credits

Original BO3 mod: LogisticalReaper. BO7 port: Fuzion28.

# Test report

## 0.4 changes (compiled, **not tested in game yet**)

| Change | How to check in game |
|---|---|
| Camo effect skips melee weapons, keeps the magazine | Upgraded melee + "Players gun gets a random camo": the mist and multi-kill swings stay. On a gun the magazine count is kept. |
| Random paped gun and attachments wait for the weapon switch before the PaP | "Give a random paped gun" / "Active weapon gets random attachments": the new gun ends up paped |
| Roll sounds use BO7 aliases (`fly_pickup_deny` ticks, `ui_select_purchase_confirm` result) | Sounds play during the roll |
| "a zombie spawns" / "5 zombies spawn" add to the round total, as BO3 does | The round lasts 1 / 5 zombies longer. Once the round has spawned all its zombies they appear near a player instead |
| "Held gun becomes paped" on an already paped gun gives a random AAT (BO3 repack) | Trigger it on a paped gun |
| Sprint / ADS / slide / jump toggles follow BO3: 1st trigger keeps it allowed, 2nd blocks | Trigger twice and check |
| "Activate a random gobblegum effect" rolls one gum for every player | Co-op: everyone gets the same gum |
| "Give a random gobblegum" with 3 full slots replaces a random slot | Fill the slots, then trigger it |
| HUD: roll fades in and out over 1 s, ON green / OFF red / CONFIRM green, blue bar slides to the selected option | Options screen and the first roll. The ON/OFF position comes from a width estimate, so check it lines up |

## Tested in game before 0.4

- Quick host test of the first build: options screen, roll and combo HUD worked.
- KrikoTV's reports (1 damage, randomised speed, headshot paped gun, melee) were fixed in 0.3 and 0.4. Those fixes are not confirmed in game yet.

# HamCraft server config

Versioned server-side configuration for the HamCraft Minecraft server.
The mod list itself is versioned through the `.mrpack` GitHub Releases;
this directory covers everything else the server needs to behave the same
way on any machine.

## Layout

- `server.properties` — core server knobs (MOTD, difficulty, view distance…).
  Management-server secret lines are intentionally stripped; the management
  server is disabled.
  **Note:** `enforce-secure-profile=false` is deliberate — the client pack ships
  NoChatReports, which withholds the profile public key by design, so requiring
  signed chat would warn every player every session.
- `config/` — config files for mods whose behavior we deliberately changed:
  - `carpet.conf` — Carpet rules (shulker stacking, anvil tweaks, villager prices…).
    **Note:** Carpet reads this from inside the world folder (`world/carpet.conf`);
    this tracked copy must be copied there on deploy.
  - `soaring_phantoms/config.toml` — phantom spawn height (Y=160).
  - `universal-graves/config.json` — grave expiry (2 hours).
  - `potionstacking.json` — potion stack size (16).
  - `sessility.properties`, `sleepmenu.json` — AFK handling, sleep-menu limits.
  - `veinminer/` — VeinMiner tree-chopping (v26.2.7): `settings.json` (speed 1.0 =
    manual pace, hunger 0.005/block = vanilla, searchRadius 5, maxChain 200),
    `groups.json` (logs-only group, explicit block IDs — the client can't parse
    `#tag` syntax). **Note:** must be a JSON array, not a single object, and
    UTF-8 without BOM or the mod silently falls back to defaults.
- `ops.json` — server operators.
- `scripts/` — helper scripts (e.g. supervisor for the Windows trial box).

## Not tracked

The world (`world/`), logs, cache, and player caches change constantly or are
too large — they need real backups, not git. Never commit secrets (RCON
passwords, management-server secrets). See `.gitignore`.

## New server setup

### 1. Install the server modpack

Download the `-server.mrpack` from the matching GitHub Release and extract it
into the server directory. This provides the `mods/` folder.

### 2. Copy config files

Copy everything from this repo's `server/` into the server directory:

```
server/server.properties → <server>/server.properties
server/config/*         → <server>/config/
server/config/carpet.conf → <server>/world/carpet.conf   # NOT config/ !
server/ops.json         → <server>/ops.json
```

**Important:** `carpet.conf` goes inside the `world/` folder, not `config/`.
Create the world folder first if it doesn't exist yet.

### 3. Create or migrate the world

- **New world:** Launch the server once to generate the world, then stop it
  before continuing to step 4 (Carpet needs the world folder to exist).
- **Migrate existing:** Copy the `world/` folder from the old server. Then
  overwrite `world/carpet.conf` with the tracked copy (or verify the rules
  are still set — Carpet persists them, but a mod update can reset).

### 4. Apply gamerules and Carpet rules

These live in the world's `level.dat` (gamerules) and `world/carpet.conf`
(Carpet rules) — neither survives a fresh world, so apply them once via the
server console:

**Vanilla gamerules:**
```
gamerule minecraft:players_sleeping_percentage 0
```

**Carpet rules** (or copy the tracked `carpet.conf` into `world/` before first launch):
```
carpet anvilNoPriorWorkPenalty true
carpet soulSpeedNoDurability true
carpet thornsNoDurability true
carpet experienceLevelCost 29-30
carpet villagerDoNotCraftBread true
carpet villagerUpgradeWhileTrading true
carpet villagerMinimumTradePrice true
carpet stackableShulkerBoxes true
```

**Mod gamerules:**
```
gamerule mob_explosion_griefing:mob_explosion_griefing false
gamerule mob_explosion_griefing:creeper_griefing false
gamerule mob_explosion_griefing:ghast_griefing false
gamerule mob_explosion_griefing:wither_griefing false
gamerule mob_explosion_griefing:enderman_griefing false
gamerule mob_explosion_griefing:door_breaking_griefing false
gamerule trampleless:farmland_trampling false
```
(`mob_explosion_griefing:turtle_egg_griefing` stays at default `true`;
`trampleless:feather_falling_trampling` stays at default `false`.)

**VeinMiner:** no console command needed — `config/veinminer/settings.json`
and `groups.json` are picked up automatically. Run `veinminer reload` in the
console after changing them on a live server.

### 5. Verify

- `carpet list` — all 8 rules show `true`
- `gamerule minecraft:players_sleeping_percentage` — `0`
- VeinMiner: check `logs/latest.log` for "Failed to load groups.json" (should be absent)

## Workflow (tweaking live)

1. Tweak config on the test machine.
2. Commit + push (ask Muse to do this over SSH: "persist the server config").
3. On deploy: copy the changed files into place; run `veinminer reload` or
   re-apply gamerules/Carpet rules as needed — no restart required for most.

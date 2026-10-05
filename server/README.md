# HamCraft server config

Versioned server-side configuration for the HamCraft Minecraft server.
The mod list itself is versioned through the `.mrpack` GitHub Releases;
this directory covers everything else the server needs to behave the same
way on any machine.

## Layout

- `server.properties` — core server knobs (MOTD, difficulty, view distance…).
  Management-server secret lines are intentionally stripped; the management
  server is disabled.
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
- `scripts/supervisor.ps1` — headless server supervisor for the Windows trial box
  (holds stdin open so the server survives SSH disconnect).
- `scripts/apply-server-settings.ps1` — applies all gamerules (vanilla + mod)
  and Carpet rules from PACK_MANIFEST.md. Run once per fresh world — gamerules
  live in level.dat and Carpet rules in world/carpet.conf, neither of which
  survives a world wipe.

## Not tracked

The world (`world/`), logs, cache, and player caches change constantly or are
too large — they need real backups, not git. Never commit secrets (RCON
passwords, management-server secrets). See `.gitignore`.

## Workflow

1. Tweak config on the test machine.
2. Commit + push (ask Muse to do this over SSH: "persist the server config").
3. On a new machine (e.g. the mini PC): clone, copy `server/*` into the server
   dir (remember `config/carpet.conf` → `world/carpet.conf`), install Java,
   launch.

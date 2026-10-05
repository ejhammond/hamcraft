# HamCraft server settings — central source of truth
# Applies all gamerules and Carpet rules from PACK_MANIFEST.md
# Usage: run on the PC with the server running, or adapt the $serverDir
# Each command is written to stdin-cmd.txt with a delay for the supervisor to process

param(
    [string]$serverDir = "C:\mc-server-test"
)

$stdinFile = Join-Path $serverDir "stdin-cmd.txt"

$commands = @(
    # === Vanilla gamerules (PACK_MANIFEST.md) ===
    "gamerule minecraft:players_sleeping_percentage 0",

    # === Carpet FGA rules (all default off — enable these) ===
    "carpet anvilNoPriorWorkPenalty true",
    "carpet soulSpeedNoDurability true",
    "carpet thornsNoDurability true",
    "carpet experienceLevelCost 29-30",
    "carpet villagerDoNotCraftBread true",
    "carpet villagerUpgradeWhileTrading true",
    "carpet villagerMinimumTradePrice true",
    "carpet stackableShulkerBoxes true",

    # === MobExplosionGriefing (all false except turtle_egg stays true) ===
    "gamerule mob_explosion_griefing:mob_explosion_griefing false",
    "gamerule mob_explosion_griefing:creeper_griefing false",
    "gamerule mob_explosion_griefing:ghast_griefing false",
    "gamerule mob_explosion_griefing:wither_griefing false",
    "gamerule mob_explosion_griefing:enderman_griefing false",
    "gamerule mob_explosion_griefing:door_breaking_griefing false",
    # turtle_egg_griefing stays at default true (lure farms)

    # === Trampleless ===
    "gamerule trampleless:farmland_trampling false"
    # feather_falling_trampling stays at default false
)

Write-Host "Applying $($commands.Count) settings to $serverDir..."
foreach ($c in $commands) {
    $c | Out-File -Encoding ascii $stdinFile
    Start-Sleep -Milliseconds 800
}
Write-Host "Done. Verify with: carpet list, and check gamerules in-game."

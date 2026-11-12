# PvP death attribution evidence

## Reference addon comparison

- `C:/Users/wilhe/Downloads/Lagom_1/Lagom/Core.lua` is the older reference. Its `PLAYER_DEAD` path records a death and synchronizes statistics; its target/nameplate scans can observe an enemy that the local player may have killed, but do not identify who killed the local player.
- `C:/Users/wilhe/Downloads/Lagom/Lagom/Core.lua` is newer. Its death-recap path waits about 0.7 seconds after `PLAYER_DEAD`, reads `C_DeathRecap.GetRecapEvents()` (with a legacy global fallback), and looks at `sourceName`. It reports a recap source as a player only when hostile-player observations support that classification. When recap data is unavailable, a hostile current target can be reported as uncertain (“probably”). This is reference implementation evidence, not proof the event fields are part of the public Forever contract.

## WoW Forever API evidence

- Target snapshot: WoW Forever 1.60.1.70862, `Gethe/wow-ui-source` commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06`.
- `C_DeathRecap.GetRecapEvents(recapID: number?)` is source-declared and returns a table of `DeathRecapEventInfo`.
- The generated `DeathRecapEventInfo` declaration has no documented fields. `sourceName`, environmental attribution, addon access, runtime availability and operation behavior remain unverified by the generated schema.
- Do not use combat-log events. Treat unknown, secret, invalid or environmental recap data as no player killer. Only a hostile player supported by observation can be a confirmed nemesis; target-only fallback must be labeled uncertain and must not increment confirmed nemesis counts.

## Ledger call flow

Graphify maps Ledger's current PvP death flow through `Core.lua`: `PLAYER_DEAD` records the death, `AnnouncePvpDeath` sends the internal `PVP_DEATH` guild addon message, and receivers record Nemesis data. Any Death Recap integration must preserve the guild-only message flow, defer attribution until recap data is available, and guard delayed callbacks against guild/database changes.

## Validation still required

In WoW Forever, record actual build/interface and separately test API presence, result shape, valid use and delivery after death. Scenarios: hostile player killer, environmental death after recent PvP targeting, missing recap, protected or malformed values, uncertain target fallback, guild receiver sync and Nemesis counting. Static declarations and the reference addon do not replace this runtime test.

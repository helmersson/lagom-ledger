# Profession catalog: PTGForever implementation record

> The initial design steps below are historical. Current implementation status and remaining runtime checks are listed at the end.

## Agreed scope

- Redesign Lagom Ledger's existing Professions tab as a guild-shared learned-recipe catalog, following PTGForever's core behavior.
- MVP: choose a profession, search recipes and crafted items, and see which guild members can craft a result.
- Required materials/reagents are included in the selected recipe detail pane. Crafting requests remain deferred.
- Use hidden addon messages: GUILD for broadcasts and requests, private addon WHISPER replies for manual recovery; never visible guild chat.
- Share a member's recipe snapshot and available materials when they open/update their own profession; do not send at login or periodically in the MVP.
- Let `/lagom sync` explicitly request already-saved recipe and material data from online guild members for missed/late data; replies are rate-limited and sent as private addon whispers to the requester.
- Show the shared recipe catalog only; do not add a skill-text fallback.

## Reference findings

PTGForever 0.4.12 scans learned, non-dummy recipe IDs after profession UI events, stores results per character and profession, and syncs changed snapshots in bounded queued chunks. It delays reads after profession open/list updates, resolves missing base-profession information through child-profession metadata, skips linked/guild/NPC views, and refuses to replace good data with empty scans. Its UI supports profession filtering, recipe/item search and crafter lookup. It does not demonstrate that native trade hyperlinks reliably open another character's recipes. `GetAllRecipeIDs`, used by PTGForever, is absent from the pinned Forever generated API inventory; actual runtime availability and useful recipe results must be proven in-game before building transport or UI on top of it.

Reference files:

- `C:/Users/wilhe/Downloads/PTGForever-0.4.12/PTGForever/Modules/Professions.lua`
- `C:/Users/wilhe/Downloads/PTGForever-0.4.12/PTGForever/Core/Store.lua`
- `C:/Users/wilhe/Downloads/PTGForever-0.4.12/PTGForever/Core/Comm.lua`
- `C:/Users/wilhe/Downloads/PTGForever-0.4.12/PTGForever/UI/Tabs/Professions.lua`

## Worker plan

1. Isolate the empty native Blizzard Professions window with the same character and profession: Ledger off, current Ledger on, then Ledger on without the experimental `TRADE_SKILL_*` capture. Keep other addons unchanged and `/reload` between trials. Remove the synchronous native-link getter path before adding more profession-event work.
2. Prove local recipe scanning in WoW Forever before designing sync. Use a delayed, cancellable scan after the profession is ready; use base-profession info with the child-profession parent fallback; skip linked/guild/NPC views; verify recipe-ID and recipe-info APIs against actual client output. Preserve the last good snapshot if a scan is empty, partial or not ready. `NEW_RECIPE_LEARNED` may arrive while the profession is closed: only update that recipe if its owning profession and learned state can be resolved safely; never scan an unrelated open window.
3. Store snapshots by guild, canonical full character identity including realm, and numeric profession ID. Include learned recipe IDs and crafted item IDs (0 when no item exists) so recipes without output items remain searchable by recipe name. Keep PvP short-name identity behavior separate.
4. After local scanning is proven, sync changed snapshots through a new addon message type on the hidden GUILD channel. Queue numbered chunks under 255 bytes; check actual send results; validate sender, guild, version, size, IDs, revisions, duplicates and timeouts. Replace a cached snapshot only after all chunks arrive. Let a later profession open republish a list after a prior loss, with a small burst cooldown. Do not add login/periodic backfill.
5. Build the existing tab around a profession filter, recipe/item search, results, required materials and the crafters for the selected result. Materials are for one craft; each required slot has one quantity and alternatives. Omit optional/hidden slots. Resolve names locally when possible; show item IDs while item names load. Defer crafting requests, skill-text fallback and separate crafter browsing panes.
6. Add focused contract tests for scan gating, empty/partial snapshot safety, serialization/chunking, send failure, atomic receive and guild/realm separation.
7. Test with two clients: open/reopen a profession; learn a recipe; find it by recipe name and output item; see the correct crafters; confirm chat stays quiet; switch guilds; reload; and drop a chunk to verify the last good cache survives. Repeat the native Blizzard window A/B test and check keyboard/controller focus in the new tab.

## Current implementation state

- Removed the synchronous native trade-link getter and `SetItemRef` UI path.
- Added a delayed scan of the character's own profession, gated on the profession window, ownership checks, feature detection, learned/non-dummy recipes, and a non-empty complete scan. Empty or partial scans retain the previous catalog. Empty profile profession reads also retain the previous names/ranks.
- Added per-guild catalog storage keyed by normalized full character name and profession ID, queued <=255-byte hidden GUILD chunks, send-result checks, and atomic receiver replacement after complete validated reassembly.
- Added a three-pane profession list, searchable recipe list and selected recipe/crafter details. First Aid, Mining, Skinning, Herbalism and Fishing are excluded from the catalog view. Removed the bottom profession/skill fallback and stale shared footer.
- Added material capture from recipe schematics when the owner opens their profession. Required slots with valid quantities and item/currency alternatives are shared in separate material messages; optional/hidden slots are omitted. Item IDs remain usable while display names load. `/lagom sync` replays material data only when it is already saved by an online owner. An older recipe catalog without material data requires the owner to reopen that profession with the updated addon, then the recipient must sync while the owner is online. There is no login or periodic material backfill.
- Added owner-only diagnostics for recipe-scan failures and fixed profession-slot iteration across nil entries.
- Added roster-based identity matching, local alias merge, and a rate-limited `/lagom sync` request/replay path using private addon whispers. This is manual recovery only; there is no login or periodic catalog backfill.
- Added static contract assertions and updated the root README.
- The user confirmed local recipe scanning now works. Two-client recipe/material sync and acceptance in WoW Forever remain unverified, as do sender-name variants, transport limits and the earlier native Blizzard Professions-window behavior. The pinned API inventory omits `GetAllRecipeIDs`; local success does not prove availability on every Forever build. No commit or push was performed.

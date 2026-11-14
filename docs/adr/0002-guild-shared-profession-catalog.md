# Use a guild-shared learned recipe catalog

- Status: Accepted
- Date: 2026-11-14

The Professions tab uses a Ledger-owned catalog of learned recipes and crafters, rather than depending on native trade links to open another character's profession. Its three-pane view filters professions, searches recipes/outputs, and shows required materials and crafters. Materials are captured during the existing profession scan and sent in separate bounded, versioned addon-message chunks; existing recipe chunks remain unchanged for backward compatibility. Crafting requests remain deferred. Native remote-link behavior is not reliable enough to serve as the catalog. A member's catalog is shared when they open/update a profession or learn a recipe. `/lagom sync` may request already-saved catalogs from online guild members; replies use private addon `WHISPER` messages. No automatic login or periodic catalog backfill is performed.

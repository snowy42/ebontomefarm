# EbonTomeFarm: project handover

Updated 2026-09-19. Owner: Matthew Snow (`snowy42`). Work directly on `main`, with regular checkpoints. User explicitly requested a finished, installable addon and a durable restart document.

## Goal
A compact, attractive WoW Project Ebonhold tome-farming addon: import an EbonholdHub build, match wanted echoes to tome sources, group and order farming stops, provide map pins / optional TomTom guidance, and track permanent collection. Movable, hideable, scrollable tracker; clickable details with mobs/bosses and alternate sources. No automatic movement or combat.

## Checkpoint status
Committed implementation modules at this checkpoint: `Core.lua`, `Codec.lua`, `Import.lua`, `Collection.lua` under `EbonTomeFarm/`. More implementation checkpoints are being committed immediately after this document; inspect the actual tree and recent commits rather than treating this list as final.

The local working implementation also includes `Data.lua`, `Route.lua`, `Navigation.lua`, `UI.lua`, `Events.lua`, the TOC, a data builder, and a strict WoW API mock / test suite. **35 tests have passed locally under real Lua 5.1.5. These are automated/mock tests, not live Ebonhold tests.** Remaining work at this checkpoint: persist all remaining modules and tests, finish visual QA, run CI from repository contents, package the install ZIP, and update this document to release state.

## Verified compatibility facts
- Client target: 3.3.5-era / TOC Interface `30300` / Lua 5.1.
- Hub v2.0.4 exports plain Base64-encoded JSON. Desired `echoTiers` are S/A/B/C; F/pool excluded. Include `lockedEchoes` and wanted `echoBundles`; deduplicate quality/stack variants by echo family. Preserve unresolved echoes rather than silently drop them.
- Also accept `EBH1:spellID.tierCode.stack,...:CLASS:Name`, `EWL1:CLASS:spellID:flag,...`, raw JSON and newline-separated names.
- Native metadata: `ProjectEbonhold.PerkDatabase[id]` has `comment`, `requiredSpell`, `quality`, `groupId`.
- Permanent discovery: `ProjectEbonhold.PerkService.GetDiscoveredEchoes()`, keyed by echo spell ID. Dedicated spellbook tab `Echoes` provides permanent tome spells via requiredSpell / echoID+100000. Never infer collection from current-run granted perks, locked perks or buffs.
- Bag items named `Tome of Echo: NAME` are shown as obtained/in bags, not falsely called learned. Manual done/needed overrides and reset to auto-detection are supported.
- Builds saved account-wide in `EbonTomeFarmDB`; collection overrides, personal pins and display settings per character in `EbonTomeFarmCharDB`.
- Native map coordinates use legacy `GetCurrentMapAreaID`, `SetMapByID`, `SetMapZoom`, `GetMapZones`. Legacy TomTom takes `AddZWaypoint(continentIndex, zoneIndex, xPercent, yPercent, title, ...)`, not Retail UiMap IDs / fractions.

## Critical data findings
World of Echoes: https://worldofechoes.pages.dev/ and https://github.com/stanislasbardoux/worldofechoes
Pinned commit: `ee25ea4cb58ec0f18644d1331a25bfd2d729d26f`.
`src/assets/data/tomes.json`: 128 tomes, 173 source records. SHA256 `702311152861685f26871d78236bc6e6369ada54b031e79c49c4f6397320625b`.

**Its coordinates are WEBSITE IMAGE percentages. EK/Kalimdor images are stitched zone atlases. Do not send these x/y values to native WoW/TomTom.** Instead, the original builder matches community mob names to native NPC spawns and instance entrances from PE-Questie. No website artwork or upstream application code is bundled.

Coordinate source: https://github.com/Xurkon/PE-Questie
Pinned reference commit: `89c3b3173df8eef3427bb5492a7fa8cea2846e3f`.
Read `Database/Wotlk/wotlkNpcDB.lua`, `Database/Zones/zoneTables.lua`, and `Compat/UiMapData.lua`. Preserve its MIT notice. Geometry: worldX=left-width*x; worldY=top-height*y. UiMapData.mapID is the legacy client map ID.

Current generated coverage: 60 NPC pins + 49 exterior instance entrances + 7 area landmarks = 116 pinned source records, covering 96 distinct tomes. Eight additional records are zone-only. Forty-nine source records are unlocated/generic/placeholders. Thirty-two distinct tomes have no reliable fixed pin. All are retained, with notes and warnings.

Two source contradictions are explicitly flagged: Instructor Razuvious and Patchwerk are listed under Ulduar upstream but native NPC data places them in Naxxramas. Route to the Naxxramas exterior entrance, retain a warning that the tome-drop association itself needs confirmation.

Representative NPC points are independently sourced actual spawn coordinates, not promises of precise drop spots. Alias matches to community shorthand are marked inferred. Exterior-Onyxia / Hellfire Citadel / Grinding Quarry records use labelled landmarks where exact NPC positions cannot be resolved. Unknown/legend-placeholder pins are excluded from routes.

## Implementation / QA design
Original modules: Core, Codec, Import, Collection, Route, Navigation, UI, Events. Bounded non-executing JSON/Base64 parser; no loadstring of imports. Greedy coverage/distance farm itinerary, not a terrain-aware global shortest path. Hold active farm until collection; arrival never completes it. Skip only defers; Replan restores deferred stops. Raid/dungeon and minimum-tier filters never delete targets. Native map pins and a built-in directional card work without TomTom. Only remove this addon's own TomTom waypoint.

UI: dark slate/gold tracker, progress bar, current farm card, scrollable rows, search, build picker, import preview, source details, preferences, minimap toggle, manual collection and personal location recording. Use only original-client-compatible frame methods and client-shipped textures/fonts. Visual render previews must be labelled as mock renders, never in-game captures.

## Provenance and licensing
EbonholdHub code is all-rights-reserved. It was inspected only to understand wire formats and integration data; do not redistribute or copy its implementation/artwork/fonts. EbonTomeFarm implementation is original and uses an MIT licence. Credit World of Echoes factual data separately; it does not have an explicit app licence. Include PE-Questie MIT notice for coordinate data.

## Reproduction / continuation
Use source and tests in this repository. Research Actions artifacts expire after three days; the final repository must NOT depend on them. A pinned data fetch/build workflow and committed generated Data.lua are planned so normal installation requires no network/Python/Questie/Hub/TomTom.

During the current chat, local workspace is `/mnt/data/ebontomefarm/src`; reference files in sibling `references/`, `questie/`, and `navigation/`. Real Lua executable is `/mnt/data/ebontomefarm/navigation/lua-5.1.5/src/lua`. These temporary paths are conveniences, not durable deliverables.

Next steps: commit remaining implementation and generator, persist generated data, finish visual inspection, commit and run automated tests in CI, create correctly rooted `EbonTomeFarm/EbonTomeFarm.toc` ZIP, document installation/limitations, update this handover with final test and artifact status. Do not claim live-client testing without actually running Ebonhold.

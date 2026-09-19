# EbonTomeFarm: durable project handover

Updated 2026-09-20. Owner: Matthew Snow (`snowy42`). Repository:
https://github.com/snowy42/ebontomefarm. Work on `main` with regular tested
checkpoints. Matthew requested a finished installable addon and this document
so another chat can resume without any temporary files.

## What is built

Version **1.0.0**, targeting original WoW **3.3.5a / Interface 30300 / Lua 5.1**.
The addon implements all five requested feature areas: Hub build import,
wanted-echo to tome-source matching, grouped farming itinerary and navigation,
permanent collection checklist with clickable map/mob/boss details, and a
compact movable/hideable/scrollable UI. It includes native pins, a built-in
direction card, optional legacy TomTom, source cycling, search, filtering,
manual overrides, personal recorded locations, and account-wide saved builds.

**40 Lua addon/mock tests and 8 Python distribution/parser tests pass locally.**
The data builder reproduced the committed Data.lua byte-for-byte from pinned
inputs. GitHub Actions runs tests and packages exact source/install artifacts.
`tools/package.py` makes a deterministic 13-file install ZIP with a per-file
manifest and SHA-256 checksums. The release workflow publishes the same build
as a durable GitHub release when `release.json` changes; inspect Actions and
Releases to confirm the latest publication result.

**No live Ebonhold client was available.** The first release is explicitly a
prerelease until `docs/TESTING.md` is exercised in game. Do not tell Matthew it
was tested in his client, or that community drops are confirmed. There is no
unfinished core feature stub; remaining acceptance work is actual-client and
server-data validation, followed by any fixes that validation reveals.

## Start here in a new chat

1. Read this document, README.md, docs/DATA.md and docs/TESTING.md. Read the
   actual `main` tree and recent commits; do not trust an old chat's file list.
2. Read any reported error or requested change. Preserve saved-variable
   compatibility. Test the change, commit to main, and update this handover.
3. Run Lua 5.1 tests, Python tests and package validation. Check the CI result
   for the actual committed SHA before claiming success. A release ZIP is
   installed by copying its EbonTomeFarm folder into Interface\AddOns.

Repository-local commands:

```sh
lua5.1 tests/test.lua
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tools/package.py
```

Python tooling requires Python 3.10+ and only its standard library. For data
updates, run `tools/fetch_data.py`, then the build command in docs/DATA.md.
Data.lua is committed; players need no Python, external app or network access.
The offline developer-kit workflow can fetch pinned inputs and official
hash-checked Lua 5.1.5 sources for an offline development environment.
Research artifacts expire and are NOT required by the addon or normal tests.

## Module map

- Core.lua: utilities, saved builds, character settings and statuses.
- Data.lua: generated offline factual database. Do not hand-edit normally.
- Codec.lua: bounded non-executing Base64 and JSON readers.
- Import.lua: Hub/EBH1/EWL1/name import, native metadata matching, deduplication.
- Collection.lua: permanent discovery/spellbook/bag adapters; read-only Hub copy.
- Route.lua: stop grouping, heuristic order, skip/replan and personal locations.
- Navigation.lua: original map IDs/pins, direction, optional legacy TomTom.
- UI.lua: original slate/gold widgets, tracker, dialogs and settings.
- Events.lua: load/events, debounced scans, navigation updates and /etf commands.
- tests/wow_mock.lua: deliberately restricted original-client mock.
- tests/test.lua: 40 addon tests. tests/test_tools.py: 8 build/parser tests.
- tools/build_data.py / fetch_data.py: pinned literal-data generation.
- tools/package.py: TOC/licence validation, reproducible ZIP and checksums.

## Compatibility facts that must not be lost

Hub v2.0.4 exports **plain Base64 JSON**. Its wanted echoTiers are S/A/B/C;
F/pool are excluded. Include lockedEchoes and wanted echoBundles. Deduplicate
quality/stack variants by echo family. Accept raw JSON, EBH1 journal strings,
EWL1 wishlist strings, and known echo names. Unknown build echoes stay visible;
never silently drop them or fabricate a farm source. Existing Hub state is
read only and imported builds are copies, not live synchronised references.

Native `ProjectEbonhold.PerkDatabase[id]` fields include comment, requiredSpell,
quality and groupId. Permanent discoveries are keyed echo spell IDs from
`ProjectEbonhold.PerkService.GetDiscoveredEchoes()`. The dedicated English
`Echoes` spellbook tab exposes permanent tome spells via requiredSpell or
id+100000. **Current-run granted perks, locked perks and buffs never establish
permanent collection.** Bag `Tome of Echo: NAME` items count as obtained for
farming, not learned. Manual done/need overrides can be reset to automatic.
An explicitly zero requiredSpell can establish an innate echo; absent data
cannot. English integration is the tested target.

Builds: account-wide EbonTomeFarmDB, maximum 30. Collection overrides, personal
pins, active build and window settings: EbonTomeFarmCharDB per character.
Do not erase user data to handle an import error. The client persists saved
variables on normal logout/reload; the addon does not write external files.

**Map IDs:** Data.lua stores `GetCurrentMapAreaID()` values. Original 3.3.5
`SetMapByID` takes **that value minus one**. PE-Questie's Compat/Compat.lua
confirms this getter/setter mismatch. A bug was fixed during continuation;
do not regress it or shift the whole database. Legacy TomTom takes
`AddZWaypoint(continentIndex, zoneIndex, xPercent, yPercent, title, ...)`.
Dynamic continent/zone enumeration is used, not Retail UiMap IDs. Only remove
EbonTomeFarm's own TomTom waypoint. Reading player position must not change an
open world map. Outdoor arrows are suppressed inside instances.

**Import ambiguity:** some plain echo names happen to be valid Base64. Only
select a decoded export when its payload starts with a JSON object/array;
otherwise use the name-list fallback. All 128 known single names are tested.
A decoded string is never executed. Import size, nesting and entry counts are
bounded. JSON rejects duplicate keys and malformed numeric/unicode values.

## Data provenance and limits

World of Echoes: https://worldofechoes.pages.dev/
https://github.com/stanislasbardoux/worldofechoes
Commit: ee25ea4cb58ec0f18644d1331a25bfd2d729d26f.
`src/assets/data/tomes.json` SHA-256:
702311152861685f26871d78236bc6e6369ada54b031e79c49c4f6397320625b.

PE-Questie: https://github.com/Xurkon/PE-Questie
Commit: 89c3b3173df8eef3427bb5492a7fa8cea2846e3f.
Use Wotlk NPC data, zoneTables and UiMapData. Every source file has a pinned
hash in fetch_data.py. Preserve PE-Questie's MIT notice in the install folder.

**World of Echoes x/y are WEBSITE IMAGE percentages.** EK/Kalimdor are stitched
zone atlases. Never pass website x/y to native maps/TomTom. Our builder matches
reported mobs to independently sourced native NPC spawns or instance
entrances. No website map artwork or upstream application code is bundled.
Geometry is worldX=left-width*x; worldY=top-height*y.

128 tome families / 173 source records. 60 NPC pins + 49 exterior entrances +
7 landmarks = 116 pinned records for 96 families. 8 additional zone-only
records; 49 generic/special/unlocated records. 32 families have no fixed pin.
They remain in the tracker with notes. No measured drop probabilities exist.
Aliases and representative spawns are explicitly uncertain, not confirmed
drop spots. Personal recorded pins are character-scoped.

Two upstream contradictions put Instructor Razuvious / Patchwerk under Ulduar.
Native NPC data places them in Naxxramas. Follow the Naxxramas exterior
entrance but retain a warning that the tome-drop association needs confirmation.

Routing is greedy coverage/priority/proximity, not a terrain-aware optimum or
flight-path/portal planner. Keep the active farm until its targets are
obtained. Arrival never completes it. Skip defers; Replan restores. Filters
never delete wanted targets. Cross-continent travel remains the player's job.

## Licensing and UI

The addon implementation is original MIT code. EbonholdHub is all-rights-
reserved and was inspected for interoperability only; do not copy its code,
artwork or fonts. Credit World of Echoes factual records separately; no
explicit application licence was identified. Include PE-Questie MIT text.
All notices are in the standalone addon folder as well as the repository.
Client-shipped font/texture paths are used; never package actual font files.
Any mock UI render must be labelled as a mock, not an in-game screenshot.

## Checkpoint history

The initial continuation recovered the complete implementation from main and
added CI (90676e5ad45f7d9f9cb2e899ff0f320fb17f3455). The tested import/map fixes
were committed as 39c70bb1296f7bd7a1b7aa9871f39a170d3b39ec. A one-time patch
workflow applied those four files atomically, ran all 40 tests, and removed
itself. Subsequent commits add distribution tests, licences, documentation and
release tooling. The repository and release assets are the durable records;
no `/mnt/data` path is needed for continuation.

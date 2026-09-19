# Data, provenance and coordinate conventions

## Sources inspected

- [World of Echoes](https://worldofechoes.pages.dev/),
  [source repository](https://github.com/stanislasbardoux/worldofechoes),
  `src/assets/data/tomes.json` at `ee25ea4cb58ec0f18644d1331a25bfd2d729d26f`.
  SHA-256: `702311152861685f26871d78236bc6e6369ada54b031e79c49c4f6397320625b`.
  Supplies reported tome/source relationships, mob names and notes.
- [PE-Questie](https://github.com/Xurkon/PE-Questie) at
  `89c3b3173df8eef3427bb5492a7fa8cea2846e3f`:
  `Database/Wotlk/wotlkNpcDB.lua`, `Database/Zones/zoneTables.lua`,
  `Compat/UiMapData.lua`. Supplies independent native NPC spawns, exterior
  instance entrances and map geometry. Its MIT notice ships inside the addon.
- [EbonholdHub v2.0.4](https://ebonholdhub.icu/): interoperability reference
  for exported builds, saved-build state and permanent-echo APIs. Its source
  and artwork are not redistributed; our parser and UI are original.

All source files used by the builder have pinned revisions and SHA-256 checks
in `tools/fetch_data.py`. No upstream application Lua is executed.

## Why the website's x/y cannot be sent directly to TomTom

World of Echoes uses image percentages. Its Eastern Kingdoms and Kalimdor maps
are stitched zone atlases, not native game maps. Treating those percentages as
in-game coordinates would produce misleading destinations.

The builder instead matches the reported mobs to Questie's native spawn data,
uses place/continent hints, and retains a representative actual spawn. Name
aliases are marked inferred. Multiple nearby spawns can appear as smaller map
pins. Some area-only descriptions use labelled entrance/landmark coordinates.
For Outland/Northrend, the conventional continent-image position may help
choose among independent NPC spawns; it is never used as the final native pin.

The stored mapID is the original **GetCurrentMapAreaID** value. Original 3.3.5
has an unusual getter/setter mismatch: **SetMapByID takes stored mapID - 1**.
This is also demonstrated by PE-Questie's `Compat/Compat.lua` WorldMapFrame
adapter. Do not remove the offset or change the entire database to compensate.
TomTom uses dynamically enumerated continent/zone indexes with x/y in **0-100**.
Our internal zone coordinates are fractions in **0-1**. This is not Retail's
UiMapID API. `MapXY` converts to continent overlays only when geometry permits.

## Snapshot coverage

Snapshot: 2026-09-19. 128 tomes, 173 reported source records.

| Source treatment | Records |
| --- | ---: |
| Representative native NPC spawn | 60 |
| Exterior dungeon/raid entrance | 49 |
| Labelled area/entrance landmark | 7 |
| Zone known but no precise pin | 8 |
| Generic, special or unlocated | 49 |

There are 116 pinned source records for 96 different tome families. The other
32 families have no reliable fixed pin. Retaining a source record does not
imply its reported drop is verified. No drop probabilities are estimated.

Two contradictory reports list **Instructor Razuvious** or **Patchwerk** under
Ulduar. Native NPC data places them in Naxxramas. The addon points to Naxxramas'
exterior entrance but preserves an explicit warning that the tome-drop
association still requires confirmation. See `data-report.json`.

## Rebuild

From the repository root, with Python 3:

```sh
python3 tools/fetch_data.py
python3 tools/build_data.py --world data-source/tomes.json --questie data-source/questie --output EbonTomeFarm/Data.lua
```

The first command needs network access. The second is offline and parses
literal data without importing or executing third-party Lua. The committed
Data.lua is sufficient for normal installation. Rebuilding the pinned inputs
was checked byte-for-byte against the committed output.

For a new upstream snapshot, update revision pins and hashes deliberately,
review alias matches/conflicts, regenerate, run tests, and update this report.
Never invent exact coordinates for an unresolved record. A personal recorded
location belongs in per-character saved variables, not the upstream facts.

Licensing/attribution details are in `EbonTomeFarm/THIRD_PARTY_NOTICES.md`.

# EbonTomeFarm

Turn a Project Ebonhold echo build into a practical tome-farming checklist and itinerary.
For the **original 3.3.5a client (Interface 30300, Lua 5.1)**, not Retail WoW.

**Version 1.0.1 names the tomes to collect in both the guide and farm card.**
Matthew has confirmed the initial 1.0.0 UI/import/route display working in
Ebonhold. This update passes automated tests; full live-client acceptance
is still pending, so releases remain marked prerelease.

## Install

Download `EbonTomeFarm-1.0.1.zip` from [Releases](https://github.com/snowy42/ebontomefarm/releases).
Close the game, extract it into your client's `Interface\AddOns` directory,
and restart. The result must be:

```text
Interface\AddOns\EbonTomeFarm\EbonTomeFarm.toc
```

Enable **EbonTomeFarm** at the character-selection AddOns screen. Avoid an extra
`ebontomefarm-main` or nested `EbonTomeFarm` folder. To install from GitHub's
source ZIP instead, copy only the `EbonTomeFarm` folder into `Interface\AddOns`.
No Python, external application, or online data download is needed in game.

## Use it

1. Open `/etf`, click **Import**, and paste the build's **Export code** from
   EbonholdHub. Click **Preview**, then **Import build**. A build page URL is
   not an export. **From Hub** also copies a build already saved in the
   installed EbonholdHub addon, without changing the original.
2. Click **Start**. The itinerary groups shared camps/instances, considers
   priority and distance, and gives a current farming stop. The built-in
   direction card and native map pins work without TomTom. Compatible legacy
   TomTom gets the current waypoint when installed.
3. Click any echo row for its map, farming mobs or bosses, alternate sources,
   coordinate confidence and community notes. Stay at the camp until its
   wanted tomes are collected. **Skip** defers a stop; **Replan** restores
   deferred stops. Neither arrival nor Skip marks an echo as collected.

The guide and farm card display **Collect: <echo names>**. Long shared-stop
lists show **(+N more)**; hover either display for names and mob descriptions.
Click the farm card to open one tome or choose from all targets at a shared
stop. Current-farm checklist rows have a gold border and **Farm now** label.
Names update as tomes are obtained and remain visible on arrival.

Drag the tracker or direction card to move it. Resize the tracker from its
lower-right corner, collapse it from the header, or hide/show it with `/etf`
or the minimap button. Search and scroll the list; **Needed / All** controls
whether completed entries are shown. **Settings** offers scaling, position
locking, minimum priority, raid/dungeon filters, automatic advance and TomTom.
Builds are account-wide; collection overrides, personal pins and settings are
per character. There is a limit of 30 saved builds; unused ones can be deleted.

## Collection rules

The addon reads permanent discoveries from ProjectEbonhold and the dedicated
**Echoes** spellbook tab. Current-run perks and buffs are never counted as
permanent ownership. A tome in your bags is marked **In bags - use the tome**,
so you can stop farming it without falsely recording it as learned.

A checkbox is a manual override. Right-click its row or press **Auto detect**
in the details window to restore automatic detection. **Record here** saves
your current outdoor position as a personal source for the selected echo.
Normal logout or `/reload` lets the client save your progress to disk.

## Coverage and limitations

The bundled snapshot contains **128 tome families and 173 community source
records**. **96 families have at least one native map pin** (116 pinned source
records). **32 families have no reliable fixed pin**; they remain visible with
available descriptions instead of receiving invented coordinates. Unknown
build echoes also stay in the checklist.

Instance pins are **outside entrances**, not boss-room coordinates. Native NPC
pins are representative spawns, not verified tome drop points; inferred name
matches and conflicting reports are labelled. The community dataset supplies
no measured drop rates. See [data provenance](docs/DATA.md).

Routing is a grouped, proximity-based itinerary, not a road/flight-path/portal
solver. You choose how to travel and perform all movement and combat. English
names and the English `Echoes` spellbook tab are the tested integration targets.
Server updates, localisation and modified client APIs can require adjustments.

The native ProjectEbonhold addon supplies echo IDs and permanent ownership.
EbonholdHub, Questie and TomTom are optional, separately installed addons.
EbonTomeFarm does not select your in-run echoes or replace Hub's auto-pick tool.

## Commands and support

`/etf import`, `/etf start`, `/etf pause`, `/etf skip`, `/etf replan`,
`/etf scan`, `/etf settings`, `/etf resetpos`, `/etf debug`.

For an error, enable `/console scriptErrors 1`, reload, and report the **first**
Lua error, the action that caused it and `/etf debug` output in
[Issues](https://github.com/snowy42/ebontomefarm/issues). Do not send passwords,
session tokens, or an entire WTF folder. See the [live-client checklist](docs/TESTING.md).

## Development and continuation

```sh
lua5.1 tests/test.lua
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tools/package.py
```

There are **48 Lua addon/mock tests and 8 Python distribution/parser tests**.
The deterministic packager validates TOC order, required files, licences and
version consistency, then produces a correctly rooted ZIP, per-file manifest
and SHA-256 checksums. Every normal main push runs CI and preserves exact
source/install artifacts; GitHub releases provide durable install downloads.

Read [PROJECT_HANDOVER.md](PROJECT_HANDOVER.md) before continuing in a new
chat. The repository contains the implementation, generated offline data,
pinned data builder, tests, packaging and workflows. No temporary chat files
or expiring research artifacts are required to build or install it.

Original implementation: [MIT](LICENSE). Factual sources and separate notices:
[EbonTomeFarm/THIRD_PARTY_NOTICES.md](EbonTomeFarm/THIRD_PARTY_NOTICES.md).

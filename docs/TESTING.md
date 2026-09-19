# Testing and first-client checklist

## Automated coverage

`lua5.1 tests/test.lua` runs 40 tests in the real Lua 5.1 interpreter against a
restricted original-client API mock. It loads every addon module in TOC order.
The mock intentionally lacks modern convenience APIs such as SetSize/SetShown.

Coverage includes JSON/Base64 limits and malformed imports, all 128 single-name
imports, Hub tiers and locked echoes, unresolved and innate echoes, native
permanent collection versus run-only perks, bag tomes, manual overrides, camp
grouping, arrival/skip/replan behaviour, filters, TomTom percentages and owned
waypoint cleanup, map setter offset, bearings, all source-detail variants,
UI interactions, resizing, persistence and late events.

`python3 -m unittest discover -s tests -p 'test_*.py' -v` runs eight tests for
reproducible ZIPs, archive roots, every member's SHA-256, missing files,
unsafe TOC paths, version mismatches, licence distribution, and a literal
upstream-data parser that rejects executable Lua.

CI also compiles every Lua file with luac5.1. The data builder was run against
pinned source files and reproduced Data.lua exactly. These checks do **not**
constitute execution inside the actual game client.

## Required live validation

The initial release is marked prerelease until this is performed. No live
Ebonhold client/server was available during development.

1. Enable `/console scriptErrors 1`. Install alongside ProjectEbonhold, first
   without optional Hub/TomTom. Log in and open `/etf`. Check readable fonts,
   drag/resize, scaling, scrolling, hide/show and recovery with resetpos.
2. Import a real current Hub export. Compare unique wanted echo families with
   the build, including locks/bundles. Confirm F/pool are excluded and unknown
   names remain visible. Repeat using From Hub with Hub installed.
3. Check one actually learned tome, one unlearned tome, and one tome in bags.
   Verify current-run echoes do not produce false ownership. Use the bag tome,
   then scan; test manual override and restore automatic detection.
4. Click a known outdoor source. Confirm the correct native zone opens, the
   displayed percentages agree with the pin, and mobs match the notes. Check
   an instance source goes to its exterior entrance, plus an unresolved source.
5. Start a multi-stop route. Check direction on all four compass headings,
   arrival does not complete it, collection advances it, Skip does not mark
   done, Replan restores skipped stops, and instance/priority filters work.
6. Install original-3.3.5 TomTom. Test add/replace/remove of ETF's waypoint and
   verify a separately created personal waypoint is unaffected. Check inside
   instances and during continent travel; no misleading outdoor arrow should
   be displayed inside an instance.
7. Log out normally, log back in, and switch characters. Confirm shared builds
   but separate manual marks, active build, custom locations and window state.

## Reporting a fault

Record client build/language, addon version, optional addons, exact action,
first Lua error (including stack trace), and `/etf debug` output. An export
code is useful for import faults, after removing comments or author fields
that should remain private. Do not upload passwords or an entire WTF folder.
Report inaccurate drops separately from software defects; include tome name,
mob/boss, zone, coordinates and how you confirmed it.

A UI mock render uses substitute fonts/icons and is not an in-game screenshot.

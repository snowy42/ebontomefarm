# Testing and first-client checklist

## Automated coverage

`lua5.1 tests/test.lua` runs 73 tests in the real Lua 5.1 interpreter against a
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

## 1.0.1 target-label regressions

Eight additional tests cover named single/shared farms, fitting long names
with an explicit remainder count, complete hover lists, per-target source
selection, collection refresh, names during arrival/map/instance states,
active-row highlighting, and non-overlapping layouts at supported sizes.
A render of the actual mock frame geometry was also visually inspected with
substitute fonts/icons. It is not an in-game capture.

## 1.0.2 regressions and live checks

Added 25 Lua tests for all-ticked reset, real learned/bag preservation,
confirmation/cancellation/build switching, aliases, nearest single tome versus
multi-tome raids, alternate sources, zone grouping, fresh-position handoff,
Replan/Skip semantics, missing samples and map browsing, continent ordering,
zone events, automatic-advance preference, notification login baseline,
polling/events/queues/deduplication/switches, previews and layout bounds.
The total is 73 Lua tests plus eight Python tests (81).

In the actual client, tick an unlearned item then Reset build and confirm it
returns to needed; learned/bag items must remain collected. Check Cancel is
harmless. Start outdoors in Eastern Kingdoms with nearby and Northrend sources;
Replan should pick the nearest available local source, finish that zone and
only then leave it. Test Replan while the world map is open, then close it.
Preview the new banner with `/etf testalert`, acquire a real tome, sort bags,
then obtain two different tomes. Check one banner per family, queued display,
no login flood, and both notification switches. These 1.0.2 live checks have
not yet been performed by the developer.

## Required live validation

Releases remain prereleases until this is performed. Matthew supplied an
in-game screenshot of 1.0.0 displaying an imported build and farming route.
That confirms initial loading/display, not every integration or source.
The 1.0.1 target-label update has not yet been verified in the actual client.

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

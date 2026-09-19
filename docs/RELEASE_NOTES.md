# EbonTomeFarm 1.0.2

## Reset the build without deleting it

A **Reset build** button is now at the bottom of the tracker and in Settings,
also available through `/etf reset`. After confirmation it removes manual
collected/needed ticks for the current build, restores skipped stops, clears
search and rescans actual permanent unlocks and bags. The imported build,
real unlocks, personal pins, filters and unrelated marks are preserved.
The route is paused for review; click **Start route** afterwards.

## Nearest farm first, one zone at a time

**Replan** restores skips and starts at the closest outstanding source from
your current position. It finishes that zone, choosing its next closest stop
after collection, before selecting the next nearest zone. Multi-tome raids
and high-priority echoes no longer outweigh a nearer source. The current
continent is exhausted first. Across continents no travel distance is claimed;
replan after travelling. No roads/flight-path/portal solver is included.

Position is sampled before route selection. When no valid position exists,
the addon waits instead of committing to an arbitrary raid. Replan with the
world map open waits for it to close. The active farm is held until its tomes
are obtained; arrival and Skip never mark a tome collected. Replan keeps
manual ticks; Reset build clears them. `/etf reroute` aliases Replan.

## Tome found

A large **TOME FOUND** banner displays the newly obtained tome name, with an
optional sound and a chat message. Multiple finds queue separately. Lightweight
bag polling every second backs up bag/loot events, even with the tracker hidden
or the route paused. Login bags are silent; each tome family is announced once
per login session to avoid sorting/rescan/reset spam. This records an item in
bags, not a permanent unlock. Use the tome normally.

Settings has banner/sound switches and a labelled **Test notification** preview
(`/etf testalert`) that does not change collection.

## Update and validation

Close the game, replace only `Interface\AddOns\EbonTomeFarm` with this ZIP's
folder, and restart. Do not delete saved variables or the WTF folder. Existing
builds and progress are retained. Use Reset build to repair accidental ticks.

**73 Lua 5.1/mock tests and eight Python tests passed locally (81 total)**,
including 25 new regression cases. Syntax, package hashes and layout bounds
were checked. The release workflow reruns these before publishing.
**This patch still requires live-client validation and remains a prerelease.**
Community tome/source data is unchanged.

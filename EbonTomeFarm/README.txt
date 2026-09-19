EbonTomeFarm 1.0.2 - Project Ebonhold tome farming
================================================
Target: original WoW 3.3.5a / Interface 30300 / Lua 5.1.

INSTALL
Close the game. Extract the EbonTomeFarm folder into the client's
Interface\AddOns folder. The resulting path must be:
  Interface\AddOns\EbonTomeFarm\EbonTomeFarm.toc
Restart the client and enable EbonTomeFarm in the character-screen AddOns list.
ProjectEbonhold provides native echo data. Hub, Questie and TomTom are not
required to import a text build and use the checklist/native pins.

FIRST USE
Type /etf. Click Import, paste the EbonholdHub build's Export code, click
Preview, then Import build. You can instead use From Hub to copy an already
saved build from the installed Hub addon. A website page URL is not an export.
The guide and farm card name what to collect. Hover either for all targets
and their mobs. Current-farm rows have a gold border and a Farm now label.
Click the farm card to inspect its tome (or choose one at a shared stop).
Click Start to begin the farming itinerary. Click an echo row for the map,
mobs/bosses, source warnings and alternate sources. Use Skip to defer a stop;
Replan restores deferred stops. Arrival alone never marks a tome collected.

Drag the tracker/arrow to move them. Drag the tracker's lower-right corner to
resize. Use the header minus to collapse, x or /etf to hide/show, and Settings
for scale, filters, locking and TomTom integration. The minimap button also
toggles the tracker. Settings can delete an unused saved build (30 maximum).

COLLECTION
Permanent native discoveries and the Echoes spellbook tab are scanned. Bag
tomes are labelled 'In bags - use the tome', not learned. The checkboxes are
manual overrides; right-click a row or use Auto detect to clear an override.
Run-only echoes never count as permanent unlocks. Builds are account-wide;
manual marks, personal pins and display settings are character-specific.

RESET / ROUTING / NOTIFICATIONS (1.0.2)
Reset build is at the bottom of the tracker and in Settings (/etf reset).
It clears this build's manual ticks and skips, rescans learned echoes and
bags, and pauses for review. Imported builds, real unlocks, personal pins,
filters and unrelated marks are kept. Click Start route when ready.
Replan keeps manual ticks, restores skips and starts at the nearest farm.
It finishes one zone before choosing the next nearest zone, and stays on
the same continent while it has stops. Close the map for a fresh position;
without one it waits instead of guessing. No cross-continent distance is
invented. Right-click one row in All echoes to undo just its manual tick.
A new bag tome displays TOME FOUND, its name, and an optional sound. Bags
are checked every second and after bag/loot events. Login bags are silent;
each family is announced once per login session. Finds queue individually,
even with the tracker hidden. Settings has switches and Test notification.
The banner detects a bag item, not permanent learning. Use the tome normally.

IMPORTANT LIMITS
128 tome families and 173 community source records are bundled. 96 tome
families have at least one native pin; 32 have no reliable fixed pin. These
remain in the list. Record here can save a verified personal outdoor source.
Pins for instances point to the entrance, not boss rooms. Some NPC-name
matches are inferred and clearly labelled. Drop rates are not measured.
Routing uses grouped stops and straight-line proximity, not roads, portals,
flight paths or dungeon layout. You control movement and combat yourself.
This build passed automated Lua 5.1/mock tests; live Ebonhold testing is still
needed. Client/server changes and community-source mistakes remain possible.

COMMANDS
/etf                Toggle tracker
/etf import         Import a build
/etf start          Start the farm route
/etf pause          Pause navigation
/etf skip           Defer the current stop
/etf replan         Restore skips and start nearest-first from here
/etf reset          Confirm reset of this build
/etf testalert      Preview the tome-found banner
/etf scan           Rescan permanent collection and bags
/etf settings       Preferences
/etf resetpos       Recover the tracker/arrow positions
/etf debug          Print integration diagnostics

TROUBLESHOOT
For a Lua error, type /console scriptErrors 1, then /reload. Report the first
error, the action that caused it and /etf debug output. Never send account
passwords, session tokens or your whole WTF folder. Back up saved variables
before deleting them. Exit the client normally to save progress to disk.

Source, issues and continuation notes:
https://github.com/snowy42/ebontomefarm
See LICENSE and THIRD_PARTY_NOTICES.md in this folder.

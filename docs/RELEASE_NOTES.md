# EbonTomeFarm 1.0.1

The floating guide and current-farm card now say **Collect: <echo names>**
instead of making you infer the target from a count. At shared stops, names
that fit are shown with a (+N more) indicator. Hover either display for the
target names and per-tome mobs. Click the farm card to open one target, or
choose from all targets in the shared-stop picker.

Current-farm checklist rows have a gold border and a **Farm now** label.
Names update after collection and remain visible while at the camp, viewing
the map, or inside an instance. The two cards are 20px taller; the main
tracker stays resizable and its controls remain correctly anchored.

**Update:** close the game, replace Interface\AddOns\EbonTomeFarm with this
ZIP's EbonTomeFarm folder, and restart. Imported builds and collection marks
are preserved in saved variables. No reimport or data reset is needed.

Validation: **48 Lua 5.1/mock tests and eight Python tests passed**, including
eight new target-display/layout regressions and visual mock-layout review.
Matthew's first in-game 1.0.0 screenshot confirms initial loading/display.
**This 1.0.1 patch still needs in-client verification; release is a prerelease.**

Community source data, routing algorithm, and TomTom titles are unchanged.

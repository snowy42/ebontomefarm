# EbonTomeFarm 1.0.0

First installable build for Project Ebonhold on the original WoW 3.3.5a client.

Import EbonholdHub Base64/JSON builds, installed Hub builds, EBH1/EWL1 journal
strings, or known echo names. Track wanted tome families in a movable,
resizable, searchable checklist with source details and native map pins.
Group farming camps and instance entrances into an itinerary, with a built-in
direction card and optional legacy TomTom. Permanent unlocks, bag tomes,
manual overrides and per-character personal locations are supported.

Includes 128 tome families and 173 community sources. 96 families have a
native pin; 32 have no reliable fixed pin and remain visible with available
guidance. Community drops, inferred NPC matches and instance entrances are
labelled; routing is straight-line/proximity based, not terrain-aware.

Validation: 40 real-Lua-5.1/mock tests, 8 Python distribution/parser tests,
Lua syntax checks, deterministic ZIP/manifest verification, and pinned-data
rebuild. The original 3.3.5 map getter/setter offset is explicitly tested.

**Prerelease: actual in-game Ebonhold validation is still required.**
All requested feature areas are implemented; no live-client result is claimed.

Install the EbonTomeFarm folder into Interface\AddOns and restart the client.
Open /etf, Import, Preview, Import build, then Start. Full instructions and
licence notices are included in the ZIP. The repository's PROJECT_HANDOVER.md
contains the continuation guide. The ZIP and manifest have SHA-256 checksums.

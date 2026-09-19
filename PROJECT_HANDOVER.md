# EbonTomeFarm: project handover

Last updated: 2026-09-19. Owner: Matthew Snow (`snowy42`).

## User request
Build a finished, installable World of Warcraft addon for Project Ebonhold (3.3.5-era client) that turns an EbonholdHub echo build into a practical tome-farming itinerary. Research the actual upstream formats and APIs before implementing. Keep committing progress to `main`; do not depend on a temporary chat surviving.

Required features:
1. Import the EbonholdHub build export and extract the required echoes.
2. Match echoes to tome locations, mob descriptions and dungeon/raid bosses, principally using World of Echoes data.
3. Plan successive farming stops, grouping useful targets and providing TomTom integration where supported.
4. Track outstanding tomes; clicking a row opens the appropriate map with a pin and farming details.
5. Attractive, compact, scrollable, movable and hideable on-screen tracker.

Scope: guidance and collection tracking, not automated movement, combat or unattended farming. Permanent tome unlocks must be distinguished from echoes temporarily drawn during a run. Do not claim in-game testing without actually testing in the game client.

## Repository and checkpoint state
Repository: https://github.com/snowy42/ebontomefarm
Default and working branch: `main`.
The GitHub connector has successfully committed files. Earlier chat statements that this connection was read-only were incorrect.
At this checkpoint **implementation has not yet been committed**. These files are present:
- `tools/research_fetch.py`: fetch public upstream reference data without executing upstream code.
- `.github/workflows/research.yml`: fetch text-only upstream references into a short-lived GitHub Actions artifact.
- This handover.

Latest research script commit before this handover: `d648671a2c30afe8be8c6f63f17306371fc9763c`.
The first research artifact truncated the Hub ZIP at 30 MB. The revised fetcher raises the size limit to 250 MB, checks oversized responses, and retains only text references. Do not use the first truncated ZIP as an installable addon.

## Primary research sources already identified
- https://worldofechoes.pages.dev/
- https://github.com/stanislasbardoux/worldofechoes (default branch `master`)
  - `src/assets/data/tomes.json` (93,055 bytes at initial inspection)
  - `src/assets/data/echoes.csv`
  - `src/assets/data/tomes_forum.md`
  - map viewer, models and services explain coordinate and data conventions.
  - Initial inspected commit: `ee25ea4cb58ec0f18644d1331a25bfd2d729d26f`.
- https://ebonholdhub.icu/
  - Associated addon download: `https://ebonholdhub.icu/releases/EbonholdHub.zip`.
  - No matching EbonholdHub source repository found yet. Inspect the downloaded Lua for export syntax and public integration globals. Do not redistribute its code without checking its licence.
- https://github.com/ProjectEbonhold/ebonhold-utils
- https://github.com/Raynbock/Ebonhold-Tomes
- https://github.com/Badutski2/EchoArchitect
- Other potentially useful references: EbonholdEchoBuddy, Better-Nexus and existing 3.3.5 TomTom implementations.

## Next actions
1. Retrieve the newest successful `upstream-research` Actions artifact. Read Hub Lua to establish exact build syntax and permanent-unlock APIs.
2. Inspect World of Echoes data schema, map coordinates and attribution/licensing. Match on verified names/IDs; explicitly show unresolved targets rather than fabricate locations.
3. Implement modular Lua 5.1-compatible addon, bundled validated location data, import parser, saved collection status, farming route logic, native map pins, optional legacy TomTom adapter and polished tracker/detail/import UI.
4. Test using Lua 5.1 plus a WoW API mock, malformed and real import examples, route grouping, map conversions and persistence. Record coverage and limits.
5. Package a ZIP with `EbonTomeFarm/EbonTomeFarm.toc` at the correct root; add installation instructions and update this document with exact tested state.

## Suggested restart prompt
Read PROJECT_HANDOVER.md and the repository files at snowy42/ebontomefarm, inspect recent commits, then continue the EbonTomeFarm addon to a tested installable package. Commit working checkpoints directly to main. Preserve completed work, verify upstream assumptions, and distinguish automated tests from unperformed live-client tests.

# Third-party notices

The MIT licence in LICENSE covers the original EbonTomeFarm implementation.
It does not grant rights to World of Warcraft, EbonholdHub, or other third-party
software and artwork. No game fonts, website maps, Hub code, or Hub artwork are
redistributed in this package. Client texture/font paths refer to existing game
assets. No upstream Lua application code is executed by the data builder.

## World of Echoes community facts

Tome names, reported sources, mob names, and community notes were read from
World of Echoes by Stanislas Bardoux and its contributors:
https://worldofechoes.pages.dev/
https://github.com/stanislasbardoux/worldofechoes

Pinned source: ee25ea4cb58ec0f18644d1331a25bfd2d729d26f,
src/assets/data/tomes.json. Its application has no explicit licence identified
at that revision. This package attributes the community factual records; it
does not relicense or reproduce the website application or map artwork.
Reports are community-supplied, not independently verified drops. Corrections
and attribution requests can be submitted to snowy42/ebontomefarm on GitHub.

## PE-Questie coordinate data

NPC spawn coordinates, instance entrances and map geometry are derived from
PE-Questie by Xurkon and contributors, revision
89c3b3173df8eef3427bb5492a7fa8cea2846e3f:
https://github.com/Xurkon/PE-Questie

Its MIT notice is reproduced below. Questie itself is not required or bundled.

MIT License

Copyright (c) 2026 Xurkon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Interoperability references, not bundled dependencies

EbonholdHub by Gangek: https://ebonholdhub.icu/ (all rights reserved).
Its exported build structure and public addon state were inspected only to
implement original, read-only interoperability. No EbonholdHub code is copied.
Project Ebonhold native collection APIs are read only.
Legacy TomTom is an optional separately installed addon; no TomTom source is
included. Use an original 3.3.5-compatible version, not Retail TomTom.

World of Warcraft and related marks/assets belong to their respective owners.
This is an independent community addon, not an official Blizzard product.

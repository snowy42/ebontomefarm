#!/usr/bin/env python3
"""Validate and reproducibly package the standalone addon (Python standard library)."""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
NAME = 'EbonTomeFarm'


def validate(root: Path) -> tuple[str, list[Path]]:
    addon = root / NAME
    toc = addon / (NAME + '.toc')
    if not toc.is_file():
        raise ValueError('Missing addon TOC: ' + str(toc))
    text = toc.read_text(encoding='utf-8')
    if not re.search(r'^## Interface: 30300\s*$', text, re.M):
        raise ValueError('This package targets original WoW 3.3.5 (Interface 30300).')
    match = re.search(r'^## Version: ([0-9]+\.[0-9]+\.[0-9]+)\s*$', text, re.M)
    if not match:
        raise ValueError('TOC needs a semantic version.')
    version = match.group(1)
    listed = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if not re.fullmatch(r'[A-Za-z0-9_]+\.lua', line):
            raise ValueError('Unexpected or unsafe TOC path: ' + line)
        if line in listed or not (addon / line).is_file():
            raise ValueError('Duplicate or missing TOC file: ' + line)
        listed.append(line)
    expected = ['Core.lua', 'Data.lua', 'Codec.lua', 'Import.lua', 'Collection.lua',
                'Route.lua', 'Navigation.lua', 'UI.lua', 'Events.lua']
    if listed != expected:
        raise ValueError('Unexpected addon load order: ' + repr(listed))
    if not re.search(r'VERSION\s*=\s*"' + re.escape(version) + '"', (addon / 'Core.lua').read_text()):
        raise ValueError('Core and TOC versions disagree.')
    for name in ['LICENSE', 'THIRD_PARTY_NOTICES.md', 'README.txt']:
        if not (addon / name).is_file():
            raise ValueError('Missing required distribution file: ' + name)
    if 'Copyright (c) 2026 Xurkon' not in (addon / 'THIRD_PARTY_NOTICES.md').read_text():
        raise ValueError('Missing coordinate-source licence notice.')
    files = []
    for path in sorted(addon.rglob('*')):
        if path.is_symlink():
            raise ValueError('Symlinks are not permitted in the install package.')
        if not path.is_file():
            continue
        if path.suffix.lower() not in ('.lua', '.toc', '.md', '.txt') and path.name != 'LICENSE':
            raise ValueError('Unexpected install asset: ' + str(path))
        files.append(path)
    return version, files


def package(root: Path = ROOT, output: Path | None = None) -> Path:
    root = root.resolve()
    output = (output or root / 'dist').resolve()
    version, files = validate(root)
    output.mkdir(parents=True, exist_ok=True)
    target = output / (NAME + '-' + version + '.zip')
    manifest = {'addon': NAME, 'version': version, 'interface': 30300, 'files': {}}
    with ZipFile(target, 'w', compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            name = path.relative_to(root).as_posix()
            data = path.read_bytes()
            info = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data, compress_type=ZIP_DEFLATED, compresslevel=9)
            manifest['files'][name] = hashlib.sha256(data).hexdigest()
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    sums = []
    for path in (target, output / 'manifest.json'):
        sums.append(hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name)
    (output / 'SHA256SUMS.txt').write_text('\n'.join(sums) + '\n', encoding='utf-8')
    print(str(target) + ': ' + str(len(files)) + ' files, ' + str(target.stat().st_size) + ' bytes')
    return target


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    package(args.root, args.output)

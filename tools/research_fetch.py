"""Retrieve public reference data for compatibility research; never execute it."""
import hashlib, io, pathlib, urllib.request, zipfile
OUT = pathlib.Path('research-cache')
OUT.mkdir(exist_ok=True)

def get(url):
    print('FETCH', url, flush=True)
    req = urllib.request.Request(url, headers={'User-Agent': 'EbonTomeFarm-Compatibility-Research/1.0'})
    with urllib.request.urlopen(req, timeout=90) as response:
        raw = response.read(250000001)
    if len(raw) > 250000000:
        raise ValueError('Reference exceeds 250 MB limit')
    print('RECEIVED', len(raw), hashlib.sha256(raw).hexdigest(), flush=True)
    return raw

def save(name, raw):
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(raw)

for name, url in [
    ('tomes.json', 'https://worldofechoes.pages.dev/assets/data/tomes.json'),
    ('echoes.csv', 'https://raw.githubusercontent.com/stanislasbardoux/worldofechoes/master/src/assets/data/echoes.csv'),
]:
    try:
        save(name, get(url))
    except Exception as exc:
        print('ERROR', name, str(exc))
for name, url in [
    ('hub', 'https://ebonholdhub.icu/releases/EbonholdHub.zip'),
    ('world', 'https://codeload.github.com/stanislasbardoux/worldofechoes/zip/refs/heads/master'),
    ('utils', 'https://codeload.github.com/ProjectEbonhold/ebonhold-utils/zip/refs/heads/main'),
    ('tomeaddon', 'https://codeload.github.com/Raynbock/Ebonhold-Tomes/zip/refs/heads/main'),
]:
    try:
        with zipfile.ZipFile(io.BytesIO(get(url))) as archive:
            for item in archive.infolist():
                p = pathlib.PurePosixPath(item.filename)
                if p.is_absolute() or '..' in p.parts or item.file_size > 12000000:
                    continue
                if p.suffix.lower() in ('.lua', '.toc', '.xml', '.json', '.csv', '.md', '.ts', '.js', '.py', '.txt') or p.name.lower() in ('license', 'copying'):
                    save(name + '/' + item.filename, archive.read(item))
            print('EXTRACTED text references', name, flush=True)
    except Exception as exc:
        print('ERROR', name, str(exc))
print('DONE')

"""Retrieve public navigation data for compatibility research; do not execute it."""
from pathlib import Path, PurePosixPath
from urllib.request import Request, urlopen
import hashlib, io, zipfile
out = Path('navigation-cache')
out.mkdir(exist_ok=True)
def fetch(url, cap=120000000):
    with urlopen(Request(url, headers={'User-Agent': 'EbonTomeFarm/1.0 research'}), timeout=70) as r:
        data = r.read(cap + 1)
    if len(data) > cap: raise ValueError('Reference exceeds size cap')
    print(url, len(data), hashlib.sha256(data).hexdigest(), flush=True)
    return data
url = 'https://codeload.github.com/Xurkon/PE-Questie/zip/refs/heads/main'
with zipfile.ZipFile(io.BytesIO(fetch(url))) as archive:
    for item in archive.infolist():
        p = PurePosixPath(item.filename)
        if p.is_absolute() or '..' in p.parts or item.file_size > 18000000: continue
        if p.suffix.lower() in ('.lua','.toc','.json','.md','.txt') or p.name.lower().startswith(('license','copying')):
            target = out / item.filename
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(item))
print('Extracted text references only')

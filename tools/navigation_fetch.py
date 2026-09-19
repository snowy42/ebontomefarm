"""Download public map and Lua reference files, without executing fetched code."""
from pathlib import Path
from urllib.request import Request, urlopen
import hashlib
out = Path('navigation-cache')
out.mkdir(exist_ok=True)
urls = {name + '.webp': 'https://worldofechoes.pages.dev/assets/maps/' + name + '.webp' for name in ('eastern-kingdoms', 'kalimdor', 'outland', 'northrend')}
urls['lua-5.1.5.tar.gz'] = 'https://www.lua.org/ftp/lua-5.1.5.tar.gz'
for name, url in urls.items():
    try:
        with urlopen(Request(url, headers={'User-Agent': 'EbonTomeFarm/1.0 research'}), timeout=40) as r:
            data = r.read(16000001)
        if len(data) > 16000000: raise ValueError('File exceeds 16 MB cap')
        (out / name).write_bytes(data)
        print(name, len(data), hashlib.sha256(data).hexdigest(), flush=True)
    except Exception as error:
        print(name, str(error), flush=True)

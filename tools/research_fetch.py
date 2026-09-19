"""Fetch public upstream data for compatibility research. Never execute upstream code."""
import hashlib, io, json, pathlib, re, urllib.request, zipfile
from urllib.parse import urljoin
OUT = pathlib.Path('research-cache')
OUT.mkdir(exist_ok=True)

def get(url, name):
    print('FETCH', url, flush=True)
    req = urllib.request.Request(url, headers={'User-Agent': 'EbonTomeFarm-Compatibility-Research/1.0'})
    with urllib.request.urlopen(req, timeout=45) as response:
        raw = response.read(30000000)
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(raw)
    print('SAVED', name, len(raw), hashlib.sha256(raw).hexdigest(), flush=True)
    return raw

for name, url in [('world', 'https://worldofechoes.pages.dev/'), ('hub', 'https://ebonholdhub.icu/')]:
    try:
        raw = get(url, name + '/index.html')
        html = raw.decode('utf-8')
        assets = re.findall(r'(?:src|href)=[\"\']([^\"\']+\.(?:js|json)(?:\?[^\"\']*)?)[\"\']', html)
        print('ASSETS', name, assets)
        for i, asset in enumerate(assets):
            try:
                js = get(urljoin(url, asset), name + '/asset' + str(i) + '.js')
                text = js.decode('utf-8', errors='replace')
                urls = sorted(set(re.findall(r'[^\s\"\'`<>]{1,180}\.json', text)))
                print('JSON REFERENCES', name, urls[:100])
                for j, item in enumerate(urls[:60]):
                    if item.startswith(('https://', '/','./')):
                        try:
                            get(urljoin(url, item), name + '/data' + str(j) + '.json')
                        except Exception as exc:
                            print('DATA ERROR', item, str(exc))
            except Exception as exc:
                print('ASSET ERROR', str(exc))
    except Exception as exc:
        print('SITE ERROR', str(exc))
try:
    get('https://ebonholdhub.icu/releases/EbonholdHub.zip', 'EbonholdHub.zip')
except Exception as exc:
    print('ADDON ERROR', str(exc))
print('DONE')

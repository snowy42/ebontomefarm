#!/usr/bin/env python3
"""Fetch pinned, hash-checked public factual data for offline addon generation.
No upstream code is imported or executed. Normal addon installation does not run this.
"""
from pathlib import Path
from urllib.request import Request, urlopen
import hashlib
WORLD='ee25ea4cb58ec0f18644d1331a25bfd2d729d26f'
QUESTIE='89c3b3173df8eef3427bb5492a7fa8cea2846e3f'
FILES=[
    ('tomes.json',f'https://raw.githubusercontent.com/stanislasbardoux/worldofechoes/{WORLD}/src/assets/data/tomes.json','702311152861685f26871d78236bc6e6369ada54b031e79c49c4f6397320625b'),
    ('questie/Compat/UiMapData.lua',f'https://raw.githubusercontent.com/Xurkon/PE-Questie/{QUESTIE}/Compat/UiMapData.lua','6e796d38f96bdf50051fa01242d9e03db9e2a6bc1b6fa166d671918423c99e08'),
    ('questie/Database/Zones/zoneTables.lua',f'https://raw.githubusercontent.com/Xurkon/PE-Questie/{QUESTIE}/Database/Zones/zoneTables.lua','48241098ebfb80da523891be9f9549845ff55172ca53d20d4d4f3a1629e07591'),
    ('questie/Database/Wotlk/wotlkNpcDB.lua',f'https://raw.githubusercontent.com/Xurkon/PE-Questie/{QUESTIE}/Database/Wotlk/wotlkNpcDB.lua','61c47e7440fd129546afadd4358886affe188fb940809c7e77355ef83ed064cb'),
]

def main():
    root=Path('data-source')
    for name,url,expected in FILES:
        with urlopen(Request(url,headers={'User-Agent':'EbonTomeFarm-data-builder/1.0'}),timeout=60) as response:
            data=response.read(12000001)
        if len(data)>12000000:raise ValueError('Reference exceeds size cap: '+name)
        actual=hashlib.sha256(data).hexdigest()
        if actual!=expected:raise ValueError('Upstream hash mismatch: '+name+' '+actual)
        path=root/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
        print(name,len(data),actual,flush=True)
if __name__=='__main__':main()

#!/usr/bin/env python3
"""Build offline farming data. Parse upstream literal data; never execute upstream Lua.

Usage: build_data.py --world tomes.json --questie PE-Questie-main --output EbonTomeFarm/Data.lua
NPC pins are independent native-map spawn records, NOT conversions of website pixels.
"""
import argparse, collections, hashlib, json, math, pathlib, re

NUMBER=re.compile(r'-?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?')
IDENT=re.compile(r'([A-Za-z_]\w*)\s*=')

class Literal:
    def __init__(self, text, pos=0): self.s, self.p = text, pos
    def skip(self):
        while self.p < len(self.s):
            if self.s[self.p].isspace(): self.p += 1
            elif self.s.startswith('--', self.p):
                end = self.s.find('\n', self.p); self.p = len(self.s) if end < 0 else end + 1
            else: break
    def value(self):
        self.skip(); s = self.s; p = self.p; c = s[p:p+1]
        if c == '{':
            self.p += 1; out = {}; index = 1
            while True:
                self.skip()
                if s[self.p] == '}': self.p += 1; return out
                if s[self.p] == '[':
                    self.p += 1; key = self.value(); self.skip(); assert s[self.p] == ']'; self.p += 1
                    self.skip(); assert s[self.p] == '='; self.p += 1
                else:
                    ident = IDENT.match(s, self.p)
                    if ident: key = ident.group(1); self.p = ident.end()
                    else: key = index; index += 1
                out[key] = self.value(); self.skip()
                if s[self.p] in ',;': self.p += 1
                elif s[self.p] != '}': raise ValueError('Nonliteral table at ' + s[self.p:self.p+80])
        if c in ('"', "'"):
            self.p += 1; out = []
            while self.p < len(s):
                c2 = s[self.p]; self.p += 1
                if c2 == c: return ''.join(out)
                if c2 == '\\':
                    c2 = s[self.p]; self.p += 1
                    if c2.isdigit():
                        num = c2
                        while len(num) < 3 and self.p < len(s) and s[self.p].isdigit(): num += s[self.p]; self.p += 1
                        out.append(chr(int(num)))
                    else: out.append({'n':'\n','r':'\r','t':'\t'}.get(c2,c2))
                else: out.append(c2)
            raise ValueError('Unterminated literal string')
        m = NUMBER.match(s,p)
        if m:
            self.p = m.end(); n = float(m.group()); return int(n) if n.is_integer() else n
        for k,v in [('nil',None),('true',True),('false',False)]:
            if s.startswith(k,p): self.p += len(k); return v
        raise ValueError('Not a literal at '+s[p:p+100])

def table_after(text, label):
    p = text.index(label) + len(label); p = text.index('{',p)
    return Literal(text,p).value()

def key(x): return re.sub('[^a-z0-9]','',x.lower().replace('’',"'"))
def seq(t): return [v for _,v in sorted(t.items())] if isinstance(t,dict) else []
def lua(x):
    if x is None: return 'nil'
    if x is True: return 'true'
    if x is False: return 'false'
    if isinstance(x,(int,float)): return repr(x)
    if isinstance(x,str):
        # Lua 5.1 has no JSON-style unicode escapes. Keep UTF-8 text literal.
        return '"'+x.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n').replace('\r','\\r').replace('\t','\\t')+'"'
    if isinstance(x,list): return '{'+','.join(lua(v) for v in x)+'}'
    return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in x.items() if v is not None)+'}'

def build(world, root):
    raw = world.read_bytes(); data = json.loads(raw)
    uimaptext = (root/'Compat/UiMapData.lua').read_text()
    maps = table_after(uimaptext,'QuestieCompat.UiMapData =')
    for m in re.finditer(r'local UiMapData\s*=',uimaptext):
        maps.update(Literal(uimaptext,uimaptext.index('{',m.end())).value())
    zones_text = (root/'Database/Zones/zoneTables.lua').read_text()
    area_ui = table_after(zones_text,'ZoneDB.private.areaIdToUiMapId =')
    # Resolve three explicit expansion-condition rows as Wrath before literal parsing.
    dungeon_text = zones_text[zones_text.index('ZoneDB.private.dungeonLocations ='):]
    dungeon_text = re.sub(r'\(?Questie\.IsWotlk and (\{[^{}]*\})\)? or \{[^{}]*\}',r'\1',dungeon_text)
    entrances = table_after(dungeon_text,'ZoneDB.private.dungeonLocations =')
    npctext = (root/'Database/Wotlk/wotlkNpcDB.lua').read_text()
    npcs = table_after(npctext,'QuestieDB.npcData = [[return')
    byname = collections.defaultdict(list)
    for nid,npc in npcs.items():
        if isinstance(npc.get(1),str): byname[key(npc[1])].append((nid,npc))
    zones = {}; area_zone = {}; name_zone = {}
    for area,ui in area_ui.items():
        m = maps.get(ui)
        if not m or m['mapType'] not in (2,3) or m['mapID']%1: continue
        mid = int(m['mapID'])
        c = {1414:1,1415:2,1945:3,113:4}.get(m.get('parentMapID'))
        if not c:
            parent = maps.get(m.get('parentMapID'),{})
            c = {1414:1,1415:2,1945:3,113:4}.get(parent.get('parentMapID'))
        if not c: continue
        zones[mid]={'name':m['name'],'mapID':mid,'c':c,'instance':m['instance'],'width':m[1],'height':m[2],'left':m[3],'top':m[4]}
        area_zone[area]=mid; name_zone[key(m['name'])]=mid
    # Include continent maps for native map overlays and coordinate conversion.
    for ui,c in [(1414,1),(1415,2),(1945,3),(113,4)]:
        m=maps[ui];mid=int(m['mapID']);zones[mid]={'name':m['name'],'mapID':mid,'c':c,'instance':m['instance'],'width':m[1],'height':m[2],'left':m[3],'top':m[4],'continent':True}
    continent={'eastern-kingdoms':2,'kalimdor':1,'outland':3,'northrend':4}
    aliases={
        'Scarlet Paladins':['Scarlet Paladin'], 'Scarlet Knights':['Scarlet Knight'], 'Giant Yetis':['Giant Yeti'],
        'Tortured Druids':['Tortured Druid'], 'Bloodsail Mage/Raider':['Bloodsail Mage','Bloodsail Raider'],
        'Bloodsail Raiders':['Bloodsail Raider'], 'Blackrock Stronghold mobs':['Blackrock Slayer','Blackrock Warlock'],
        'Grimtotem mobs':['Grimtotem Shaman'], 'Ethereal mobs':['Bash\'ir Arcanist','Bash\'ir Spell-Thief'],
        'Ethereal Arcanist, Plunderer, Nethermancer':['Ethereal Arcanist','Ethereal Plunderer','Ethereal Nethermancer'],
        'Ethereal Plunderers/Arcanists':['Ethereal Plunderer','Ethereal Arcanist'], 'Ethereal Necromancer':['Ethereal Nethermancer'],
        'Bash’ir Ethereals':["Bash'ir Arcanist","Bash'ir Spell-Thief"],
        'Seers':['Umbrafen Seer'], 'Seers (packs of 3)':['Umbrafen Seer'],
        'Either Stags, Wolves or Grove Walkers':['Sinewy Wolf','Grove Walker'],
        'Wind Elementals (confirmed)':['Whispering Wind'], 'Clerics, Shattered Hand Zealot':['Scarlet Cleric'], 'Clerics':['Scarlet Cleric'],
        'Same mobs as Subtle Presence':['Bloodsail Raider'], 'Same mobs as Relentless Energy':['Bloodsail Raider'],
        'Skeletons':['Skeletal Flayer'],
    }
    # Aliases expand community shorthand, never claim new tome drop associations.
    place_zones={
        'hearthglen':'Western Plaguelands','scarletencampments':'Western Plaguelands','blackrockstronghold':'Burning Steppes',
        'bootybay':'Stranglethorn Vale','outsidebb':'Stranglethorn Vale','southwindvillage':'Silithus',
        'bashirlanding':"Blade's Edge Mountains",'tomboflights':'Terokkar Forest','forgecampwrath':"Blade's Edge Mountains",
        'southernpathtowardnagrandshattrath':'Zangarmarsh','redridgemountain':'Redridge Mountains','redrigemountain':'Redridge Mountains',
        'tyrshand':'Eastern Plaguelands','pyrewoodvillage':'Silverpine Forest','malykriss':'Icecrown',
    }
    dungeon_names={'naxxramas':3456,'ulduar':4273,'trialofthecrusader':4722,'onyxiaslair':2159,'blacktemple':3959,
        'eyeofeternity':4500,'obsidiansanctum':4493,'cullingofstratholme':4100,'scarletmonastery':796,'shatteredhalls':3714,'stratholme':2017}
    output=[]; report={'sourceSHA256':hashlib.sha256(raw).hexdigest(),'conflicts':[],'unmapped':[],'counts':{}}
    for source in data['locations']:
        loc={'id':source['id'],'tomeID':source['tomeId'],'place':source['placeName'],'mobs':source['mobs'],
             'notes':source.get('notes',''),'c':continent[source['zone']],'sourceX':source['x'],'sourceY':source['y'],'kind':'world'}
        pname=key(loc['place']); ntext=loc['notes'].lower()
        if any(pname.startswith(s) for s in ('unknown','bottomright')):
            loc['kind']='special' if 'reaper' in ntext or any('Reaper' in m for m in loc['mobs']) else 'unknown'
        elif pname in ('anywhere','everywhere','prettymucheverywhere'):
            loc['kind']='generic'
        if loc['kind']!='world':
            loc['accuracy']='unmapped';output.append(loc);continue
        hint=None
        for nk,mid in sorted(name_zone.items(),key=lambda kv:-len(kv[0])):
            if nk and nk in pname: hint=mid;break
        if hint is None:
            for fragment,zname in place_zones.items():
                if fragment in pname:hint=name_zone.get(key(zname));break
        declared=None
        for frag,area in dungeon_names.items():
            if frag in key(loc['place'].split(';')[0]): declared=area;break
        if 'outsideony' in pname: declared=None
        names=[]
        for mob in source['mobs']:
            if mob in aliases and key(mob.rstrip('s')) not in {key(n) for n in aliases[mob]}:loc['inferredNPC']=True
            names.extend(aliases.get(mob,[s.strip() for s in re.split(r',|\s/\s',mob) if s.strip()]))
        candidates=[]; dungeon_candidates=[]
        for name in names:
            rows=byname.get(key(name),[])
            if not rows: rows=byname.get(key(name.rstrip('s')),[])
            for nid,npc in rows:
                for area,pts in (npc.get(7) or {}).items():
                    if area in entrances: dungeon_candidates.append((area,nid,npc[1]))
                    mid=area_zone.get(area)
                    if mid and zones[mid]['c']==loc['c'] and (not hint or hint==mid):
                        for pt in seq(pts):
                            xy=seq(pt)
                            if len(xy)>=2 and 0<xy[0]<100 and 0<xy[1]<100:candidates.append((mid,xy[0],xy[1],nid,npc[1]))
        # Unique boss instance resolves two upstream source-label contradictions.
        if declared and dungeon_candidates and not any(d[0]==declared for d in dungeon_candidates):
            unique={d[0] for d in dungeon_candidates}
            if len(unique)==1:
                actual=next(iter(unique));info='Source lists '+loc['place']+'; native NPC data places '+dungeon_candidates[0][2]+' in a different instance. Pin follows the NPC instance; the tome drop still needs in-game confirmation.'
                report['conflicts'].append({'id':loc['id'],'message':info,'from':declared,'to':actual})
                loc['warning']=info;declared=actual
        if not declared and not candidates and len({d[0] for d in dungeon_candidates})==1:
            declared=dungeon_candidates[0][0];loc['warning']='NPC spawn data is inside an instance. Pin is the exterior entrance, not the exact mob room.'
        if declared:
            choices=seq(entrances.get(declared,{}));entry=seq(choices[0]) if choices else []
            if len(entry)>=3 and entry[0] in area_zone:
                loc['mapID']=area_zone[entry[0]];loc['x']=entry[1]/100;loc['y']=entry[2]/100
                loc['instanceArea']=declared;loc['kind']='raid' if declared in (3456,4273,4722,2159,3959,4500,4493) else 'dungeon'
                loc['accuracy']='entrance';loc['zone']=zones[loc['mapID']]['name']
                if declared==3456:loc['place']='Naxxramas'
                if dungeon_candidates:loc['npcIDs']=sorted({d[1] for d in dungeon_candidates if d[0]==declared})
        elif candidates:
            counts=collections.Counter(p[0] for p in candidates);mid=max(counts,key=counts.get)
            pts=[p for p in candidates if p[0]==mid]
            # Choose an actual spawn with the densest 4%-wide neighbourhood, never a mean in water.
            if loc['c'] in (3,4):
                # These two source images use the conventional continent layout.
                # Use its approximate marker ONLY to choose an independently sourced NPC spawn.
                cm=next(z for z in zones.values() if z.get('continent') and z['c']==loc['c'])
                z=zones[mid];wx=cm['left']-cm['width']*loc['sourceX']/100;wy=cm['top']-cm['height']*loc['sourceY']/100
                px=(z['left']-wx)/z['width']*100;py=(z['top']-wy)/z['height']*100
                best=min(pts,key=lambda p:(p[1]-px)**2+(p[2]-py)**2)
            else:
                best=max(pts,key=lambda p:sum((p[1]-q[1])**2+(p[2]-q[2])**2<=16 for q in pts))
            loc.update(mapID=mid,x=round(best[1]/100,5),y=round(best[2]/100,5),zone=zones[mid]['name'],accuracy='npc')
            loc['npcIDs']=sorted({p[3] for p in pts});loc['pinMob']=best[4]
            near=sorted(pts,key=lambda p:(p[1]-best[1])**2+(p[2]-best[2])**2)
            sample=[]
            for p in near:
                xy=[round(p[1]/100,5),round(p[2]/100,5)]
                if not any((xy[0]-q[0])**2+(xy[1]-q[1])**2<.000025 for q in sample):sample.append(xy)
                if len(sample)>=12:break
            loc['spawns']=sample
        if not loc.get('mapID'):
            landmark = 2159 if 'outsideony' in pname else 3714 if pname=='hellfirecitadel' else 1584 if 'grindingquarry' in pname else None
            if landmark:
                entry=seq(seq(entrances[landmark])[0]);mid=area_zone[entry[0]]
                loc.update(mapID=mid,x=entry[1]/100,y=entry[2]/100,zone=zones[mid]['name'],accuracy='landmark',kind='world')
                loc['warning']='Area entrance landmark only. Farm the exterior area described by the source; this is not an exact NPC spawn.'
        if not loc.get('mapID') and hint:
            loc['mapID']=hint;loc['zone']=zones[hint]['name'];loc['accuracy']='zone'
        if not loc.get('accuracy'):
            loc['accuracy']='unmapped';report['unmapped'].append({'id':loc['id'],'place':loc['place'],'mobs':loc['mobs']})
        if 'to be confirmed' in ntext or 'to be tested' in ' '.join(loc['mobs']).lower():loc['warning']=loc.get('warning','Community report is not confirmed. Treat this as a lead, not a guaranteed drop.')
        output.append(loc)
    tomes=[{'id':t['id'],'name':t['name'],'key':key(t['name']),'quality':t['quality']} for t in data['tomes']]
    report['counts']=dict(collections.Counter(l['accuracy'] for l in output));report['tomes']=len(tomes);report['locations']=len(output)
    report['tomesWithPins']=len({l['tomeID'] for l in output if l.get('x')})
    result={'meta':{'date':'2026-09-19','worldSource':'https://worldofechoes.pages.dev/','coordinateSource':'PE-Questie WotLK NPC database / native map geometry','sourceSHA256':report['sourceSHA256'],'worldCommit':'ee25ea4cb58ec0f18644d1331a25bfd2d729d26f','coordinateCommit':'89c3b3173df8eef3427bb5492a7fa8cea2846e3f'},'zones':zones,'tomes':tomes,'locations':output}
    return result,report

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--world',type=pathlib.Path,required=True);ap.add_argument('--questie',type=pathlib.Path,required=True);ap.add_argument('--output',type=pathlib.Path,required=True);args=ap.parse_args()
    result,report=build(args.world,args.questie)
    text='-- Generated factual farming records. See THIRD_PARTY_NOTICES.md and docs/DATA.md.\nEbonTomeFarm.Data = {\n'
    for k,v in result.items():
        if isinstance(v,list):text+='['+lua(k)+']={\n'+',\n'.join(lua(r) for r in v)+'\n},\n'
        else:text+='['+lua(k)+']='+lua(v)+',\n'
    text+='}\n';args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(text)
    args.output.with_suffix('.json').write_text(json.dumps(result,indent=2))
    (args.output.parent.parent/'docs').mkdir(exist_ok=True)
    (args.output.parent.parent/'docs/data-report.json').write_text(json.dumps(report,indent=2))
    print(json.dumps(report,indent=2))
if __name__=='__main__':main()

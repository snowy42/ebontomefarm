"""Distribution and non-executing upstream-data parser tests; no third-party packages."""
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'tools' / (name + '.py'))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

pack = module('package')
builder = module('build_data')

class DistributionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        shutil.copytree(ROOT / 'EbonTomeFarm', self.root / 'EbonTomeFarm')
    def tearDown(self):
        self.temp.cleanup()
    def test_reproducible_zip_and_correct_root(self):
        first = pack.package(self.root, self.root / 'a')
        second = pack.package(self.root, self.root / 'b')
        self.assertEqual(first.read_bytes(), second.read_bytes())
        with ZipFile(first) as z:
            self.assertIn('EbonTomeFarm/EbonTomeFarm.toc', z.namelist())
            self.assertTrue(all(n.startswith('EbonTomeFarm/') for n in z.namelist()))
            self.assertEqual(z.testzip(), None)
    def test_manifest_hashes_match_every_archive_member(self):
        target = pack.package(self.root)
        manifest = json.loads((target.parent / 'manifest.json').read_text())
        with ZipFile(target) as z:
            self.assertEqual(set(z.namelist()), set(manifest['files']))
            for name, digest in manifest['files'].items():
                self.assertEqual(hashlib.sha256(z.read(name)).hexdigest(), digest)
    def test_missing_runtime_file_is_rejected(self):
        (self.root / 'EbonTomeFarm' / 'Data.lua').unlink()
        with self.assertRaises(ValueError):
            pack.validate(self.root)
    def test_unsafe_toc_path_is_rejected(self):
        toc = self.root / 'EbonTomeFarm' / 'EbonTomeFarm.toc'
        toc.write_text(toc.read_text() + '\n../private.lua\n')
        with self.assertRaises(ValueError):
            pack.validate(self.root)
    def test_version_mismatch_is_rejected(self):
        toc = self.root / 'EbonTomeFarm' / 'EbonTomeFarm.toc'
        toc.write_text(toc.read_text().replace('Version: 1.0.0', 'Version: 9.9.9'))
        with self.assertRaises(ValueError):
            pack.validate(self.root)
    def test_licence_must_ship_with_standalone_addon_folder(self):
        (self.root / 'EbonTomeFarm' / 'THIRD_PARTY_NOTICES.md').unlink()
        with self.assertRaises(ValueError):
            pack.validate(self.root)

class LiteralDataTests(unittest.TestCase):
    def test_literals_and_lua_serialization_roundtrip(self):
        data = {'name': 'Tome "test"\nnext', 'yes': True, 'point': {1: 0.5, 2: -2.25}}
        self.assertEqual(builder.Literal(builder.lua(data)).value(), data)
    def test_executable_upstream_lua_is_never_evaluated(self):
        for text in ['{x=function() return 1 end}', '{x=os.execute("anything")}', '{x=loadstring("x")}']:
            with self.assertRaises(ValueError):
                builder.Literal(text).value()

if __name__ == '__main__':
    unittest.main()

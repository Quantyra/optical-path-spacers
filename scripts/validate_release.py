"""Offline integrity, metadata, privacy, local links and basic mesh checks.
Python standard library only. Does not execute CAD, G-code or machine commands.
SPDX-License-Identifier: CERN-OHL-S-2.0
"""
from pathlib import Path
import hashlib
import json
import re
import struct

ROOT = Path(__file__).resolve().parents[1]


def triangles(path):
    data = path.read_bytes()
    if len(data) >= 84 and 84 + 50 * struct.unpack_from('<I', data, 80)[0] == len(data):
        return [tuple(tuple(struct.unpack_from('<3f', data, i + 12 + j * 12))
                      for j in range(3)) for i in range(84, len(data), 50)]
    vertices = [tuple(map(float, v)) for v in re.findall(
        r'vertex\s+([-+\deE.]+)\s+([-+\deE.]+)\s+([-+\deE.]+)', data.decode('ascii'))]
    assert len(vertices) % 3 == 0
    return [tuple(vertices[i:i + 3]) for i in range(0, len(vertices), 3)]


def mesh_info(path):
    tris = triangles(path)
    assert tris, f'Empty mesh: {path}'
    edges = {}
    volume = 0
    for a, b, c in tris:
        volume += (a[0]*(b[1]*c[2]-b[2]*c[1]) +
                   a[1]*(b[2]*c[0]-b[0]*c[2]) + a[2]*(b[0]*c[1]-b[1]*c[0])) / 6
        for u, v in [(a, b), (b, c), (c, a)]:
            edge = tuple(sorted((u, v)))
            edges[edge] = edges.get(edge, 0) + 1
    assert all(n == 2 for n in edges.values()), f'Non-manifold edge: {path}'
    assert volume > 0, f'Non-positive signed volume: {path}'
    bounds = [[min(v[i] for t in tris for v in t), max(v[i] for t in tris for v in t)]
              for i in range(3)]
    return dict(triangles=len(tris), bounds_mm=bounds, signed_volume_mm3=volume,
                closed_edge_incidence=True)


def main():
    listed = set()
    for line in (ROOT/'SHA256SUMS').read_text().splitlines():
        digest, name = line.split('  ', 1)
        p = ROOT/name
        assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest() == digest, name
        listed.add(name)
    actual = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*')
              if p.is_file() and '.git' not in p.parts and '__pycache__' not in p.parts
              and p.name != 'SHA256SUMS'}
    assert actual == listed, f'Inventory mismatch: {actual ^ listed}'
    manifest = json.loads((ROOT/'manifest.json').read_text())
    for entry in manifest['files']:
        p = ROOT/entry['path']
        assert p.stat().st_size == entry['bytes']
        assert hashlib.sha256(p.read_bytes()).hexdigest() == entry['sha256']
    z = json.loads((ROOT/'.zenodo.json').read_text())
    assert z['version'] == manifest['version'], 'Package/Zenodo version mismatch'
    assert z['license'] == 'cern-ohl-s-2.0'
    assert z['creators'] and 'doi' not in z
    cff = (ROOT/'CITATION.cff').read_text()
    assert 'cff-version: 1.2.0' in cff and 'CERN-OHL-S-2.0' in cff
    assert re.search(r'^version: [\"\']?' + re.escape(manifest['version']) + r'[\"\']?$',
                     cff, re.MULTILINE), 'CFF version mismatch'
    assert {e['path'] for e in manifest['files']} == actual - {'manifest.json'}
    assert 'Daniel Eric' in cff and 'Quantyra' in cff
    assert z['creators'] == [{'name': 'Fredriksen, Daniel Eric', 'affiliation': 'Quantyra'}]
    assert manifest['source_location'] in cff
    if (ROOT/'gcode').exists():
        gcode_manifest = json.loads((ROOT/'gcode/manifest.json').read_text())
        assert gcode_manifest['version'] == manifest['version'], 'G-code version mismatch'
        assert {e['filename'] for e in gcode_manifest['files']} == {
            p.name for p in (ROOT/'gcode').glob('*.gcode')}
        for entry in gcode_manifest['files']:
            p = ROOT/'gcode'/entry['filename']
            assert p.stat().st_size == entry['bytes']
            assert hashlib.sha256(p.read_bytes()).hexdigest() == entry['sha256']
            assert (ROOT/entry['modeled_counterpart']).is_file()
        assert not any('29m' in e['filename'] for e in gcode_manifest['files'])
    else:
        assert not list(ROOT.rglob('*.gcode'))
        assert not re.search(r'^doi:', cff, re.MULTILINE)
        assert not z.get('doi') and not z.get('prereserve_doi')
    text_suffixes = {'.md', '.json', '.cff', '.scad', '.py', '.gcode'}
    for name in sorted(actual):
        p = ROOT/name
        if p.suffix not in text_suffixes:
            continue
        data = p.read_text(encoding='utf-8')
        assert not re.search(r'(?im)^//\s*PRIVATE\b', data), f'Private CAD header: {name}'
        assert not re.search(r'(?<![A-Za-z])[A-Za-z]:[\\/]', data), f'Local drive path: {name}'
        if p.suffix == '.scad':
            assert 'qa_' not in data, f'QA selector: {name}'
            for ref in re.findall(r'(?:use|include)\s*<([^>]+)>', data):
                dependency = (p.parent/ref).resolve()
                assert dependency.is_relative_to(ROOT) and dependency.is_file(), ref
        if p.suffix == '.md':
            for ref in re.findall(r'\]\(([^)]+)\)', data):
                if re.match(r'^(?:https?://|mailto:|#)', ref):
                    continue
                target = (p.parent/ref.split('#')[0]).resolve()
                assert target.is_relative_to(ROOT) and target.is_file(), (name, ref)
    geometry = json.loads((ROOT/'docs/geometry-checks.json').read_text())
    assert geometry['status'] == 'PASS_GEOMETRY_ONLY'
    for entry in geometry['approved_mesh_exports']:
        p = ROOT/entry['mesh']
        if p.exists():
            assert hashlib.sha256(p.read_bytes()).hexdigest() == entry['sha256']
        assert entry['regenerated_symmetric_difference_mm3'] < 1e-5
    for entry in geometry['interfaces']:
        assert entry['docked_overlap_mm3'] < 1e-4
        assert max(entry['two_tongue_7_2mm_straight_withdrawal_sweep_overlap_mm3']) < 1e-4
    meshes = {p.name: mesh_info(p) for p in sorted((ROOT/'stl').glob('*.stl'))}
    for entry in geometry['approved_mesh_exports']:
        name = Path(entry['mesh']).name
        if name in meshes:
            info = meshes[name]
            assert abs(info['signed_volume_mm3'] - entry['volume_mm3']) < 1e-4
            # Export evidence uses [minimum_xyz, maximum_xyz]; mesh_info is per axis.
            assert all(abs(info['bounds_mm'][axis][side] - entry['bounds_mm'][side][axis]) < 1e-5
                       for axis in range(3) for side in range(2))
    print(json.dumps(dict(status='PASS',checked_files=len(listed),meshes=meshes), indent=2))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Lightweight structural verification for public-facing portfolio CSVs."""
from pathlib import Path
import csv
from collections import Counter
ROOT = Path(__file__).resolve().parents[1]
def read_csv(name):
    with (ROOT / 'data' / name).open('r', encoding='utf-8-sig', newline='') as handle:
        return list(csv.DictReader(handle))

def check():
    species = read_csv('species_summary.csv')
    nodes = read_csv('quadruped_nodes_sample.csv')
    roles = read_csv('role_paths.csv')
    assert len(species) == 16, f"expected 16 species, found {len(species)}"
    assert len(nodes) == 68, f"expected 68 quadruped nodes, found {len(nodes)}"
    assert len(roles) == 36, f"expected 36 T4 rows, found {len(roles)}"
    assert len({r['nodeId'] for r in nodes}) == len(nodes), 'duplicate node ID'
    assert len({r['speciesId'] for r in species}) == 16, 'duplicate species ID'
    ids = {r['nodeId'] for r in nodes}
    by_species = {}
    for row in nodes:
        assert row['speciesId'] in {'Q01', 'Q02', 'Q03', 'Q04'}
        assert row['modelStatus'] in {'UNMODELED','GEOMETRY_REVIEW_REQUIRED'}, 'unknown status'
        parent = row['parentId']
        assert (not parent and row['tier']=='T0') or (parent in ids and row['tier'] in {'T1','T2'}), f"invalid parent: {row['nodeId']}"
        by_species.setdefault(row['speciesId'], []).append(row)
    for sid, rows in by_species.items():
        assert Counter(r['tier'] for r in rows) == {'T0':1,'T1':4,'T2':12}, sid
    assert len(by_species)==4
    by_role=Counter(r['t3Id'] for r in roles)
    assert len(by_role)==9 and all(n==4 for n in by_role.values())
    assert len({r['t4Id'] for r in roles})==36
    print('PASS: 16 species, 68 quadruped nodes, 9 roles, 36 methods; parent links valid.')
if __name__ == '__main__': check()

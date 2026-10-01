#!/usr/bin/env python3
"""Temporary: merges lib/l10n/fragments/*.json into lib/l10n/app_es.arb
(keeps existing messages; fails on conflicting values). Idempotent."""
import glob, json, sys, collections
arb = "lib/l10n/app_es.arb"
base = json.load(open(arb), object_pairs_hook=collections.OrderedDict)
added = 0
for path in sorted(glob.glob("lib/l10n/fragments/*.json")):
    for k, v in json.load(open(path), object_pairs_hook=collections.OrderedDict).items():
        if k in base:
            if base[k] != v:
                sys.exit(f"conflict on {k} in {path}")
            continue
        base[k] = v
        added += 1
json.dump(base, open(arb, "w"), ensure_ascii=False, indent=2)
open(arb, "a").write("\n")
print(f"merged, {added} new entries")

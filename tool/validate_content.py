#!/usr/bin/env python3
"""Validate content.json against content.schema.json plus extra checks.

Usage:
  pip install jsonschema
  python3 tool/validate_content.py [--file content.json] [--schema content.schema.json] [--against GIT_REF]

--against REF: if content.json differs from the one at REF, contentVersion must be higher,
and an existing cheat id must keep its category (ids are never reused for another cheat).
Exit code 0 = valid, 1 = invalid.
"""
import argparse, json, subprocess, sys
from datetime import datetime

try:
    from jsonschema import Draft7Validator
except ImportError:
    sys.exit("Missing dependency: run `pip install jsonschema`")


def parse_date(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00")) if "T" in s else datetime.fromisoformat(s)


def git_show(ref, path):
    r = subprocess.run(["git", "show", f"{ref}:{path}"], capture_output=True, text=True)
    return json.loads(r.stdout) if r.returncode == 0 else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", default="content.json")
    ap.add_argument("--schema", default="content.schema.json")
    ap.add_argument("--against")
    a = ap.parse_args()

    errors = []
    try:
        data = json.load(open(a.file, encoding="utf-8"))
    except Exception as e:
        sys.exit(f"ERROR: cannot read {a.file}: {e}")
    schema = json.load(open(a.schema, encoding="utf-8"))

    for e in sorted(Draft7Validator(schema).iter_errors(data), key=lambda e: list(e.absolute_path)):
        path = "/".join(str(p) for p in e.absolute_path) or "(root)"
        errors.append(f"schema: {path}: {e.message}")

    if not errors:
        cat_ids = [c["id"] for c in data["categories"]]
        for d in {i for i in cat_ids if cat_ids.count(i) > 1}:
            errors.append(f"duplicate category id: {d}")
        seen = set()
        for c in data["cheats"]:
            if c["id"] in seen:
                errors.append(f"duplicate cheat id: {c['id']}")
            seen.add(c["id"])
            if c["categoryId"] not in cat_ids:
                errors.append(f"{c['id']}: unknown categoryId '{c['categoryId']}'")
            try:
                if parse_date(c["updatedAt"]) < parse_date(c["addedAt"]):
                    errors.append(f"{c['id']}: updatedAt is before addedAt")
            except ValueError as ex:
                errors.append(f"{c['id']}: bad date ({ex})")
        try:
            parse_date(data["updatedAt"])
        except ValueError as ex:
            errors.append(f"updatedAt: bad date ({ex})")

        if a.against:
            old = git_show(a.against, a.file)
            if old is None:
                print(f"note: no {a.file} at {a.against}, skipping version check")
            elif old != data:
                if data["contentVersion"] <= old["contentVersion"]:
                    errors.append(
                        f"content changed but contentVersion ({data['contentVersion']}) "
                        f"is not higher than {a.against} ({old['contentVersion']})")
                old_cat = {c["id"]: c["categoryId"] for c in old["cheats"]}
                for c in data["cheats"]:
                    if c["id"] in old_cat and old_cat[c["id"]] != c["categoryId"]:
                        errors.append(f"{c['id']}: id reused for a different category (was '{old_cat[c['id']]}')")

    if errors:
        print(f"{a.file}: {len(errors)} problem(s)")
        for e in errors:
            print(" -", e)
        sys.exit(1)
    langs = sorted({l for c in data["cheats"] for l in c["title"]})
    print(f"OK: {len(data['cheats'])} cheats, {len(data['categories'])} categories, "
          f"contentVersion {data['contentVersion']}, languages in titles: {', '.join(langs)}")


main()

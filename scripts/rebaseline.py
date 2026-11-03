#!/usr/bin/env python3
"""Rewrite failed `expect` values in a watch config to their on-chain values.

    python3 scripts/rebaseline.py --file watch/x.hcl --plan plan.json [--summary changes.md]

Reads the JSON plan (`chainform plan --json`), and for every failed assertion
replaces the value in the matching `expect` block in place. Comments and
layout are kept; the trailing comment on a changed line is replaced with a
TODO so the reviewer describes the new value and links its source.

Exit codes: 0 all failed assertions rewritten, 3 some could not be rewritten
automatically (listed in the summary), 2 bad input.
"""

import argparse
import json
import re
import sys


def render(value, abi_type):
    """Render a canonical plan value as an HCL literal for the given ABI type."""
    if abi_type.endswith("]"):
        elem = abi_type[: abi_type.rindex("[")]
        return "[" + ", ".join(render(v, elem) for v in value) + "]"
    if abi_type == "bool":
        return "true" if value else "false"
    if re.fullmatch(r"u?int\d*", abi_type):
        return str(value)
    s = json.dumps(str(value))
    # HCL template sequences inside quoted strings.
    return s.replace("${", "$${").replace("%{", "%%{")


def show(value):
    """Plan value as text for the summary (JSON spelling for bools and lists)."""
    return value if isinstance(value, str) else json.dumps(value)


def split_comment(rhs):
    """Split `value  # comment` into (value, comment), ignoring # inside strings."""
    in_str = escaped = False
    for i, ch in enumerate(rhs):
        if in_str:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_str = False
        elif ch == '"':
            in_str = True
        elif ch == "#" or rhs.startswith("//", i):
            return rhs[:i].rstrip(), rhs[i:]
    return rhs.rstrip(), ""


def find_block(lines, start, end, header):
    """Return (open_idx, close_idx) of the first block whose header matches."""
    for i in range(start, end):
        if header.match(lines[i]):
            depth = 0
            for j in range(i, end):
                depth += lines[j].count("{") - lines[j].count("}")
                if depth == 0:
                    return i, j
            return None
    return None


def rewrite(lines, assertion):
    res = re.escape(assertion["resource"])
    attr = re.escape(assertion["attr"])

    resource = find_block(
        lines, 0, len(lines), re.compile(rf'^\s*resource\s+"[^"]+"\s+"{res}"\s*\{{')
    )
    if not resource:
        return "resource block not found"
    expect = find_block(
        lines, resource[0] + 1, resource[1], re.compile(r"^\s*expect\s*\{")
    )
    if not expect:
        return "expect block not found"

    line_re = re.compile(rf"^(\s*{attr}\s*=\s*)(.*?)(\r?\n?)$")
    for i in range(expect[0] + 1, expect[1]):
        m = line_re.match(lines[i])
        if not m:
            continue
        old, _ = split_comment(m.group(2))
        if old.startswith("[") and not old.endswith("]"):
            return "multi-line value, edit by hand"
        new = render(assertion["actual"], assertion["type"])
        lines[i] = (
            f"{m.group(1)}{new} # was {old}; TODO: describe and link the proposal / tx"
            f"{m.group(3)}"
        )
        return None
    return "attribute not found in expect block"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True)
    ap.add_argument("--plan", required=True)
    ap.add_argument("--summary")
    args = ap.parse_args()

    try:
        with open(args.plan) as f:
            plan = json.load(f)
        with open(args.file) as f:
            lines = f.readlines()
    except (OSError, json.JSONDecodeError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    changed, skipped = [], []
    for a in plan.get("assertions", []):
        if a.get("satisfied"):
            continue
        name = f'{a["resource"]}.{a["attr"]}'
        err = rewrite(lines, a)
        row = (name, a["type"], show(a["expected"]), show(a["actual"]))
        if err:
            skipped.append(row + (err,))
        else:
            changed.append(row)

    with open(args.file, "w") as f:
        f.writelines(lines)

    out = []
    if changed:
        out += ["| Attribute | Type | Was | Now (on-chain) |", "| --- | --- | --- | --- |"]
        out += [f"| `{n}` | `{t}` | `{e}` | `{a}` |" for n, t, e, a in changed]
    if skipped:
        out += ["", "**Not rewritten automatically - edit by hand:**", ""]
        out += [f"- `{n}` (`{t}`): `{e}` -> `{a}` - {why}" for n, t, e, a, why in skipped]
    if plan.get("operations"):
        out += ["", "**The plan also proposes operations** (managed attributes); "
                "move them into `expect` - this repo only watches."]
    text = "\n".join(out) + "\n"
    if args.summary:
        with open(args.summary, "w") as f:
            f.write(text)
    print(text)

    return 3 if skipped or plan.get("operations") else 0


if __name__ == "__main__":
    sys.exit(main())

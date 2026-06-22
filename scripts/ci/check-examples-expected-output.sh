#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

python3 - "$ROOT_DIR" <<'PY'
import difflib
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Set


ROOT = Path(sys.argv[1])
EXAMPLES = ROOT / "examples"
VOLATILE_MANIFEST_FIELDS = {"id", "wasCached"}


def is_ignored_path(path: Path) -> bool:
    parts = set(path.parts)
    return bool(parts & {"_build", "deps", "node_modules", ".elixir_ls"})


def normalize_manifest(raw: bytes, manifest_path: Path) -> bytes:
    try:
        data = json.loads(raw.decode("utf-8"))
    except Exception as error:
        raise RuntimeError(f"Invalid JSON in {manifest_path.relative_to(ROOT)}: {error}") from error

    for field in VOLATILE_MANIFEST_FIELDS:
        data.pop(field, None)

    return (json.dumps(data, sort_keys=True, indent=2) + "\n").encode("utf-8")


def git_lines(args: List[str]) -> List[str]:
    output = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    ).stdout
    return [line for line in output.splitlines() if line]


def tracked_manifest_paths() -> Set[Path]:
    return {
        ROOT / line
        for line in git_lines(["ls-files", "--", "examples/**/_GeneratedFiles.json"])
        if not is_ignored_path(Path(line).relative_to("examples"))
    }


def tracked_file_paths() -> Set[Path]:
    return {ROOT / line for line in git_lines(["ls-files", "--", "examples"])}


def read_git_blob(path: Path) -> Optional[bytes]:
    relative = str(path.relative_to(ROOT))
    result = subprocess.run(
        ["git", "show", f"HEAD:{relative}"],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode != 0:
        return None
    return result.stdout


def discover_generated_paths(manifest_paths: Set[Path]) -> Set[Path]:
    paths: Set[Path] = set()
    for manifest_path in sorted(manifest_paths):
        paths.add(manifest_path)
        try:
            data = json.loads(manifest_path.read_text())
        except Exception as error:
            raise RuntimeError(f"Invalid JSON in {manifest_path.relative_to(ROOT)}: {error}") from error

        files_generated = data.get("filesGenerated", [])
        if not isinstance(files_generated, list):
            raise RuntimeError(f"{manifest_path.relative_to(ROOT)} has non-list filesGenerated")

        for relative_name in files_generated:
            if not isinstance(relative_name, str) or not relative_name:
                raise RuntimeError(f"{manifest_path.relative_to(ROOT)} has invalid generated path: {relative_name!r}")
            paths.add(manifest_path.parent / relative_name)

    return paths


def read_expected_state(paths: Set[Path]) -> Dict[Path, Optional[bytes]]:
    state: Dict[Path, Optional[bytes]] = {}
    for path in sorted(paths):
        raw = read_git_blob(path)
        if raw is None:
            state[path] = None
            continue

        if path.name == "_GeneratedFiles.json":
            state[path] = normalize_manifest(raw, path)
        else:
            state[path] = raw

    return state


def read_generated_state(paths: Set[Path]) -> Dict[Path, Optional[bytes]]:
    state: Dict[Path, Optional[bytes]] = {}
    for path in sorted(paths):
        if not path.exists():
            state[path] = None
            continue

        raw = path.read_bytes()
        if path.name == "_GeneratedFiles.json":
            state[path] = normalize_manifest(raw, path)
        else:
            state[path] = raw

    return state


def read_raw_manifest_state(paths: Set[Path]) -> Dict[Path, bytes]:
    raw: Dict[Path, bytes] = {}
    for path in sorted(paths):
        if path.name == "_GeneratedFiles.json" and path.exists():
            raw[path] = path.read_bytes()
    return raw


def require_clean_generated_outputs(paths: Set[Path]) -> None:
    relative_paths = [str(path.relative_to(ROOT)) for path in sorted(paths)]
    if not relative_paths:
        return

    status = subprocess.run(
        ["git", "status", "--porcelain=v1", "--", *relative_paths],
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    ).stdout.strip()
    if not status:
        return

    print("[examples-output] Generated example outputs are already dirty before the compile check.", file=sys.stderr)
    print("[examples-output] Regenerate/review them first, then commit or discard the expected output update.", file=sys.stderr)
    print("", file=sys.stderr)
    print(status, file=sys.stderr)
    raise SystemExit(1)


def restore_semantic_equal_manifests(before_raw: Dict[Path, bytes], before: Dict[Path, Optional[bytes]], after: Dict[Path, Optional[bytes]]) -> None:
    for path, raw in before_raw.items():
        if before.get(path) == after.get(path) and path.exists() and path.read_bytes() != raw:
            path.write_bytes(raw)


def show_diff(path: Path, before: Optional[bytes], after: Optional[bytes]) -> None:
    label = str(path.relative_to(ROOT))
    if before is None:
        print(f"[examples-output] ADDED {label}", file=sys.stderr)
        after_text = (after or b"").decode("utf-8", errors="replace").splitlines(keepends=True)
        sys.stderr.writelines(difflib.unified_diff([], after_text, fromfile=f"{label} (missing)", tofile=label))
        return

    if after is None:
        print(f"[examples-output] REMOVED {label}", file=sys.stderr)
        before_text = before.decode("utf-8", errors="replace").splitlines(keepends=True)
        sys.stderr.writelines(difflib.unified_diff(before_text, [], fromfile=label, tofile=f"{label} (missing)"))
        return

    before_text = before.decode("utf-8", errors="replace").splitlines(keepends=True)
    after_text = after.decode("utf-8", errors="replace").splitlines(keepends=True)
    sys.stderr.writelines(difflib.unified_diff(before_text, after_text, fromfile=f"{label} (before)", tofile=f"{label} (after)"))


def main() -> int:
    manifest_paths = tracked_manifest_paths()
    before_paths = discover_generated_paths(manifest_paths)
    require_clean_generated_outputs(before_paths)
    before_state = read_expected_state(before_paths)
    before_raw_manifests = read_raw_manifest_state(before_paths)

    subprocess.run(["npm", "run", "test:examples"], cwd=ROOT, check=True)

    after_paths = discover_generated_paths(manifest_paths)
    all_paths = before_paths | after_paths
    before_state = read_expected_state(all_paths)
    after_state = read_generated_state(all_paths)

    restore_semantic_equal_manifests(before_raw_manifests, before_state, after_state)

    changed = [path for path in sorted(all_paths) if before_state.get(path) != after_state.get(path)]
    if not changed:
        print("[examples-output] Example generated output matches checked-in expectations.")
        return 0

    print("[examples-output] Generated example output drifted after npm run test:examples.", file=sys.stderr)
    print("[examples-output] This means checked-in generated outputs are stale or a generator changed behavior.", file=sys.stderr)
    print("[examples-output] Review the diffs below and commit the expected generated output if correct.", file=sys.stderr)
    print("", file=sys.stderr)

    for path in changed:
        show_diff(path, before_state.get(path), after_state.get(path))

    return 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode)
    except RuntimeError as error:
        print(f"[examples-output] ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
PY

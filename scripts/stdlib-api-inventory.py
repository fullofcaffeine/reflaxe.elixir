#!/usr/bin/env python3
"""Build and validate the pinned Haxe standard-library public API inventory."""

from __future__ import annotations

import argparse
import collections
import copy
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
HAXERC = ROOT / ".haxerc"
MACRO_DIR = ROOT / "tools/stdlib_api_inventory"
POLICY_PATH = ROOT / "docs/08-roadmap/stdlib-parity/api-policy.json"
INVENTORY_PATH = ROOT / "docs/08-roadmap/stdlib-parity/api-inventory.json"
SUMMARY_PATH = ROOT / "docs/08-roadmap/stdlib-parity/api-inventory.md"
UNITSTD_MANIFEST = ROOT / "test/upstream_unitstd/manifest.json"
BEADS_PATH = ROOT / ".beads/issues.jsonl"
SCHEMA_VERSION = 1
POLICY_SCHEMA_VERSION = 1
SEMANTIC_CORE_TASK = "haxe.elixir.codex-0yn.10.3"
SEMANTIC_HOST_TASK = "haxe.elixir.codex-0yn.10.4"
EVIDENCE_TASK = "haxe.elixir.codex-0yn.10.5"

PROFILE_DEFINITIONS: tuple[tuple[str, str, tuple[str, ...]], ...] = (
    ("macro", "macro/eval compiler context", ("--interp",)),
    ("js", "JavaScript", ("-js", "{output}.js")),
    ("neko", "Neko", ("-neko", "{output}.n")),
    ("php", "PHP", ("-php", "{output}_php")),
    ("python", "Python", ("-python", "{output}.py")),
    ("lua", "Lua", ("-lua", "{output}.lua")),
    ("hl", "HashLink", ("-hl", "{output}.hl")),
    ("flash", "Flash", ("-swf", "{output}.swf", "--swf-version", "11.4")),
    ("cpp", "C++", ("-cpp", "{output}_cpp")),
    ("java", "Java", ("-java", "{output}_java")),
)
NODEJS_SOURCE_PROFILE = "nodejs-source"
CS_SOURCE_PROFILE = "cs-source"

ALLOWED_APPLICABILITY = {"runtime", "compile-time", "compiler-display", "other-target"}
ALLOWED_SUPPORT = {"supported", "partial", "unsupported", "unknown", "not-applicable"}
ALLOWED_EVIDENCE = {"api-runtime", "module-runtime", "missing", "not-required"}


class InventoryError(RuntimeError):
    """A reviewable inventory or policy failure."""


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise InventoryError(f"missing required file: {path.relative_to(ROOT)}") from error
    except json.JSONDecodeError as error:
        raise InventoryError(f"invalid JSON in {path.relative_to(ROOT)}: {error}") from error


def expected_haxe_version() -> str:
    value = load_json(HAXERC)
    version = value.get("version")
    if not isinstance(version, str) or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise InventoryError(".haxerc must pin a full Haxe version")
    return version


def haxe_command() -> list[str]:
    configured = os.environ.get("HAXE_BIN")
    if configured:
        return [configured]
    local = ROOT / "node_modules/.bin/haxe"
    if local.exists():
        return [str(local)]
    return ["haxe"]


def command_output(command: list[str], *, cwd: Path | None = None, timeout: int = 60) -> str:
    env = os.environ.copy()
    env["HAXE_NO_SERVER"] = "1"
    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise InventoryError(f"command failed to finish: {' '.join(command)}: {error}") from error
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise InventoryError(f"command failed ({result.returncode}): {' '.join(command)}\n{detail[-4000:]}")
    return result.stdout.strip()


def generate_typed_profiles() -> tuple[dict[str, list[dict[str, Any]]], str]:
    haxe = haxe_command()
    expected = expected_haxe_version()
    actual = command_output(haxe + ["-version"], cwd=ROOT, timeout=20)
    if actual != expected:
        raise InventoryError(f"expected Haxe {expected} from .haxerc, got {actual}")

    profiles: dict[str, list[dict[str, Any]]] = {}
    with tempfile.TemporaryDirectory(prefix="reflaxe-elixir-stdlib-api-") as raw_temp:
        temp = Path(raw_temp)
        for name, _description, target_args in PROFILE_DEFINITIONS:
            json_path = temp / f"{name}.json"
            output_stem = temp / f"all-{name}"
            resolved_args = [part.format(output=str(output_stem)) for part in target_args]
            command = haxe + [
                "-cp",
                str(MACRO_DIR),
                "--no-output",
                "--macro",
                "StdlibApiImportAll.run()",
                "-D",
                "doc-gen",
                "--dce",
                "no",
                *resolved_args,
                "--json",
                str(json_path),
            ]
            command_output(command, cwd=temp, timeout=60)
            try:
                profile = json.loads(json_path.read_text(encoding="utf-8"))
            except (FileNotFoundError, json.JSONDecodeError) as error:
                raise InventoryError(f"Haxe did not produce valid typed JSON for {name}: {error}") from error
            if not isinstance(profile, list):
                raise InventoryError(f"typed JSON for {name} is not a list")
            profiles[name] = profile
    return profiles, actual


def type_path(type_data: dict[str, Any]) -> str:
    return ".".join([*type_data.get("pack", []), type_data["name"]])


def module_path(type_data: dict[str, Any]) -> str:
    return ".".join([*type_data.get("pack", []), type_data["moduleName"]])


def referenced_type_path(path_data: dict[str, Any]) -> str:
    return ".".join([*path_data.get("pack", []), path_data["typeName"]])


def render_params(params: list[dict[str, Any]] | None) -> str:
    if not params:
        return ""
    rendered: list[str] = []
    for param in params:
        value = param.get("name", "T")
        constraints = param.get("constraints") or []
        if constraints:
            value += ":(" + " & ".join(render_type(item) for item in constraints) + ")"
        default_type = param.get("defaultType")
        if default_type:
            value += "=" + render_type(default_type)
        rendered.append(value)
    return "<" + ", ".join(rendered) + ">"


def render_type(type_data: dict[str, Any] | None) -> str:
    if not type_data:
        return "Unknown"
    kind = type_data.get("kind")
    args = type_data.get("args")
    if kind == "TDynamic":
        if isinstance(args, dict):
            nested = args.get("t") or (args if args.get("kind") else None)
            if nested:
                return f"Dynamic<{render_type(nested)}>"
        return "Dynamic"
    if kind in {"TInst", "TEnum", "TType", "TAbstract"}:
        if not isinstance(args, dict) or not isinstance(args.get("path"), dict):
            raise InventoryError(f"malformed {kind} type: {type_data}")
        path = referenced_type_path(args["path"])
        params = args.get("params") or []
        return path + ("<" + ", ".join(render_type(item) for item in params) + ">" if params else "")
    if kind == "TFun":
        if not isinstance(args, dict):
            raise InventoryError(f"malformed TFun type: {type_data}")
        rendered_args: list[str] = []
        for index, argument in enumerate(args.get("args") or []):
            name = argument.get("name") or f"arg{index + 1}"
            optional = "?" if argument.get("opt") else ""
            rendered_args.append(f"{optional}{name}:{render_type(argument.get('t'))}")
        return "(" + ", ".join(rendered_args) + ") -> " + render_type(args.get("ret"))
    if kind == "TAnonymous":
        if not isinstance(args, dict):
            raise InventoryError(f"malformed TAnonymous type: {type_data}")
        fields = []
        for field in sorted(args.get("fields") or [], key=lambda item: item.get("name", "")):
            optional = "?" if ":optional" in metadata_names(field) else ""
            fields.append(f"{optional}{field.get('name')}:{render_type(field.get('type'))}")
        return "{" + ", ".join(fields) + "}"
    raise InventoryError(f"unsupported Haxe typed-JSON kind: {kind!r}")


def render_type_reference(reference: dict[str, Any]) -> str:
    path_data = reference.get("path")
    if not isinstance(path_data, dict):
        raise InventoryError(f"malformed Haxe type reference: {reference}")
    params = reference.get("params") or []
    return referenced_type_path(path_data) + (
        "<" + ", ".join(render_type(item) for item in params) + ">" if params else ""
    )


def render_abstract_contract(args: dict[str, Any]) -> list[str]:
    details: list[str] = []
    for direction in ("from", "to"):
        for conversion in args.get(direction) or []:
            rendered = f"{direction} {render_type(conversion.get('t'))}"
            if conversion.get("field"):
                rendered += f" via {conversion['field']}"
            details.append(rendered)
    for operator in args.get("binops") or []:
        raw_operator = operator.get("op")
        name = raw_operator.get("kind") if isinstance(raw_operator, dict) else raw_operator
        if not isinstance(name, str) or not isinstance(operator.get("field"), str):
            raise InventoryError(f"malformed abstract binary operator: {operator}")
        details.append(f"binary {name} via {operator['field']}")
    for operator in args.get("unops") or []:
        name = operator.get("op")
        if not isinstance(name, str) or not isinstance(operator.get("field"), str):
            raise InventoryError(f"malformed abstract unary operator: {operator}")
        position = "postfix" if operator.get("postFix") else "prefix"
        details.append(f"unary {position} {name} via {operator['field']}")
    for field in args.get("array") or []:
        if not isinstance(field, str):
            raise InventoryError(f"malformed abstract array access: {field!r}")
        details.append(f"array access via {field}")
    for access in ("read", "write"):
        field = args.get(access)
        if field:
            if not isinstance(field, str):
                raise InventoryError(f"malformed abstract {access} access: {field!r}")
            details.append(f"{access} via {field}")
    return sorted(set(details))


def render_type_declaration(item: dict[str, Any]) -> str:
    item_path = type_path(item)
    type_kind = item.get("kind")
    args = item.get("args") or {}
    params = render_params(item.get("params"))
    if type_kind == "class":
        modifiers = [
            name
            for name, enabled in (
                ("extern", args.get("isExtern")),
                ("final", args.get("isFinal")),
                ("abstract", args.get("isAbstract")),
            )
            if enabled
        ]
        declaration_kind = "interface" if args.get("isInterface") else "class"
        declaration = " ".join([*modifiers, declaration_kind, item_path + params])
        super_class = args.get("superClass")
        if super_class:
            declaration += " extends " + render_type_reference(super_class)
        interfaces = args.get("interfaces") or []
        if interfaces:
            relation = " extends " if args.get("isInterface") else " implements "
            declaration += relation + ", ".join(render_type_reference(value) for value in interfaces)
        return declaration
    if type_kind == "typedef":
        return f"typedef {item_path}{params} = {render_type(args.get('type'))}"
    if type_kind == "abstract":
        declaration = f"abstract {item_path}{params}({render_type(args.get('type'))})"
        contract = render_abstract_contract(args)
        return declaration + (" [" + "; ".join(contract) + "]" if contract else "")
    if type_kind == "enum":
        return f"enum {item_path}{params}"
    raise InventoryError(f"unexpected public type kind {type_kind!r} for {item_path}")


def metadata_names(value: dict[str, Any]) -> list[str]:
    names = []
    for item in value.get("meta") or []:
        name = item.get("name")
        if isinstance(name, str):
            names.append(name)
    return sorted(set(names))


def normalize_source(path_value: str | None, std_root: Path | None = None) -> str | None:
    if not path_value:
        return None
    path = Path(path_value)
    if std_root:
        try:
            return "std/" + path.resolve().relative_to(std_root.resolve()).as_posix()
        except (OSError, ValueError):
            pass
    parts = path.parts
    for index, part in enumerate(parts):
        if part == "std":
            return Path(*parts[index:]).as_posix()
    try:
        return path.resolve().relative_to(ROOT.resolve()).as_posix()
    except (OSError, ValueError):
        return path.name


def find_std_root(profiles: dict[str, list[dict[str, Any]]]) -> Path:
    configured = os.environ.get("HAXE_STD_PATH")
    if configured:
        candidate = Path(configured).expanduser().resolve()
        if (candidate / "Std.hx").exists():
            return candidate
        raise InventoryError(f"HAXE_STD_PATH does not contain Std.hx: {candidate}")
    for profile in profiles.values():
        for item in profile:
            file_value = (item.get("pos") or {}).get("file")
            if not file_value:
                continue
            candidate = Path(file_value).resolve()
            for parent in candidate.parents:
                if parent.name == "std" and (parent / "Std.hx").exists():
                    return parent
    raise InventoryError("could not locate the pinned Haxe std directory from typed JSON")


def module_from_relative(relative: Path) -> str:
    value = relative.as_posix()
    if not value.endswith(".hx"):
        raise InventoryError(f"unexpected stdlib source suffix: {relative}")
    return value[:-3].replace("/", ".")


def scan_reference_modules(std_root: Path) -> dict[str, Path]:
    modules: dict[str, Path] = {}
    for source in sorted(std_root.rglob("*.hx")):
        relative = source.relative_to(std_root)
        if len(relative.parts) > 1 and relative.parts[0] not in {"haxe", "sys"}:
            continue
        module = module_from_relative(relative)
        modules[module] = source
    return modules


def source_fingerprint(modules: dict[str, Path], std_root: Path) -> str:
    digest = hashlib.sha256()
    for module, path in sorted(modules.items()):
        relative = path.relative_to(std_root).as_posix()
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def member_scope(field: dict[str, Any], container_scope: str, *, abstract: bool = False) -> str:
    if not abstract:
        return container_scope
    meta = set(metadata_names(field))
    if ":from" in meta or ":enum" in meta:
        return "static"
    type_data = field.get("type") or {}
    if type_data.get("kind") == "TFun":
        arguments = ((type_data.get("args") or {}).get("args") or [])
        if arguments and arguments[0].get("name") == "this":
            return "instance"
        return "static"
    return "instance"


def add_raw_api(
    merged: dict[tuple[str, ...], dict[str, Any]],
    *,
    module: str,
    type_name: str,
    type_kind: str,
    row_kind: str,
    scope: str,
    name: str,
    signature: str,
    profile: str,
    source: str | None,
    metadata: Iterable[str] = (),
    profile_signature: str | None = None,
) -> None:
    key = (module, type_name, type_kind, row_kind, scope, name, signature)
    row = merged.setdefault(
        key,
        {
            "module": module,
            "type": type_name,
            "typeKind": type_kind,
            "kind": row_kind,
            "scope": scope,
            "name": name,
            "signature": signature,
            "profiles": set(),
            "sources": set(),
            "metadata": set(),
            "profileSignatures": collections.defaultdict(set),
        },
    )
    row["profiles"].add(profile)
    if source:
        row["sources"].add(source)
    row["metadata"].update(metadata)
    if profile_signature:
        row["profileSignatures"][profile].add(profile_signature)


def render_field_signature(field: dict[str, Any], *, abstract: bool, scope: str) -> str:
    field_type = field.get("type")
    if abstract and scope == "instance" and (field_type or {}).get("kind") == "TFun":
        field_type = copy.deepcopy(field_type)
        arguments = ((field_type.get("args") or {}).get("args") or [])
        if arguments and arguments[0].get("name") == "this":
            field_type["args"]["args"] = arguments[1:]
    return render_params(field.get("params")) + render_type(field_type)


def add_field_variants(
    merged: dict[tuple[str, ...], dict[str, Any]],
    *,
    module: str,
    type_name: str,
    type_kind: str,
    field: dict[str, Any] | None,
    profile: str,
    std_root: Path,
    container_scope: str,
    abstract: bool = False,
) -> None:
    if not field or not field.get("isPublic"):
        return
    variants = [field, *(field.get("overloads") or [])]
    for variant in variants:
        if variant.get("isPublic") is False:
            continue
        field_kind = ((variant.get("kind") or {}).get("kind"))
        row_kind = "method" if field_kind == "FMethod" else "field"
        member_name = variant.get("name") or field.get("name") or "unknown"
        scope = member_scope(variant, container_scope, abstract=abstract)
        if abstract and member_name == "_new":
            member_name = "new"
            scope = "constructor"
        signature = render_field_signature(variant, abstract=abstract, scope=scope)
        add_raw_api(
            merged,
            module=module,
            type_name=type_name,
            type_kind=type_kind,
            row_kind=row_kind,
            scope=scope,
            name=member_name,
            signature=signature,
            profile=profile,
            source=normalize_source((variant.get("pos") or {}).get("file"), std_root),
            metadata=metadata_names(variant),
        )


def find_abstract_implementation(
    profile: list[dict[str, Any]],
    by_type: dict[str, dict[str, Any]],
    abstract_type: dict[str, Any],
    implementation: dict[str, Any],
) -> dict[str, Any] | None:
    """Resolve Haxe's synthetic `_Module.Abstract_Impl_` package spelling."""
    direct = by_type.get(referenced_type_path(implementation))
    if direct:
        return direct
    expected_pack = [*abstract_type.get("pack", []), "_" + abstract_type["moduleName"]]
    candidates = [
        item
        for item in profile
        if item.get("kind") == "class"
        and item.get("name") == implementation.get("typeName")
        and item.get("moduleName") == implementation.get("moduleName")
    ]
    exact = [item for item in candidates if item.get("pack", []) == expected_pack]
    if len(exact) == 1:
        return exact[0]
    if len(candidates) == 1:
        return candidates[0]
    if candidates:
        raise InventoryError(
            f"ambiguous abstract implementation for {type_path(abstract_type)}: "
            + ", ".join(type_path(item) for item in candidates)
        )
    return None


def extract_typed_apis(
    profiles: dict[str, list[dict[str, Any]]],
    modules: dict[str, Path],
    std_root: Path,
) -> dict[tuple[str, ...], dict[str, Any]]:
    merged: dict[tuple[str, ...], dict[str, Any]] = {}
    module_names = set(modules)
    for profile_name, profile in profiles.items():
        by_type = {type_path(item): item for item in profile}
        for item in profile:
            module = module_path(item)
            if module not in module_names or item.get("isPrivate"):
                continue
            item_type_path = type_path(item)
            type_kind = item.get("kind")
            if type_kind not in {"class", "enum", "typedef", "abstract"}:
                raise InventoryError(f"unexpected public type kind {type_kind!r} for {item_type_path}")
            add_raw_api(
                merged,
                module=module,
                type_name=item_type_path,
                type_kind=type_kind,
                row_kind="type",
                scope="type",
                name=item.get("name") or item_type_path.rsplit(".", 1)[-1],
                signature=f"{type_kind} {item_type_path}{render_params(item.get('params'))}",
                profile=profile_name,
                source=normalize_source((item.get("pos") or {}).get("file"), std_root),
                metadata=metadata_names(item),
                profile_signature=render_type_declaration(item),
            )
            args = item.get("args") or {}
            if type_kind == "class":
                for field in args.get("fields") or []:
                    add_field_variants(merged, module=module, type_name=item_type_path, type_kind=type_kind,
                                       field=field, profile=profile_name, std_root=std_root, container_scope="instance")
                for field in args.get("statics") or []:
                    add_field_variants(merged, module=module, type_name=item_type_path, type_kind=type_kind,
                                       field=field, profile=profile_name, std_root=std_root, container_scope="static")
                add_field_variants(merged, module=module, type_name=item_type_path, type_kind=type_kind,
                                   field=args.get("constructor"), profile=profile_name, std_root=std_root,
                                   container_scope="constructor")
            elif type_kind == "enum":
                for constructor in args.get("constructors") or []:
                    add_raw_api(
                        merged,
                        module=module,
                        type_name=item_type_path,
                        type_kind=type_kind,
                        row_kind="enum-constructor",
                        scope="constructor",
                        name=constructor["name"],
                        signature=render_type(constructor.get("type")),
                        profile=profile_name,
                        source=normalize_source((constructor.get("pos") or {}).get("file"), std_root),
                        metadata=metadata_names(constructor),
                    )
            elif type_kind == "typedef":
                typedef_type = args.get("type") or {}
                if typedef_type.get("kind") == "TAnonymous":
                    for field in (typedef_type.get("args") or {}).get("fields") or []:
                        add_field_variants(merged, module=module, type_name=item_type_path, type_kind=type_kind,
                                           field=field, profile=profile_name, std_root=std_root,
                                           container_scope="typedef-field")
            elif type_kind == "abstract":
                implementation = args.get("impl")
                if implementation:
                    implementation_type = find_abstract_implementation(
                        profile, by_type, item, implementation
                    )
                    if implementation_type:
                        implementation_args = implementation_type.get("args") or {}
                        for field in implementation_args.get("fields") or []:
                            add_field_variants(merged, module=module, type_name=item_type_path,
                                               type_kind=type_kind, field=field, profile=profile_name,
                                               std_root=std_root, container_scope="instance", abstract=True)
                        for field in implementation_args.get("statics") or []:
                            add_field_variants(merged, module=module, type_name=item_type_path,
                                               type_kind=type_kind, field=field, profile=profile_name,
                                               std_root=std_root, container_scope="static", abstract=True)
    return merged


def extract_nodejs_source_api(
    merged: dict[tuple[str, ...], dict[str, Any]], source: Path, std_root: Path
) -> None:
    """Extract the one std module that requires the external hxnodejs library to type."""
    text = source.read_text(encoding="utf-8")
    module = "haxe.http.HttpNodeJs"
    class_match = re.search(r"\bclass\s+(HttpNodeJs)(?:\s+extends\s+([^\s{]+))?\s*\{", text)
    if not class_match:
        raise InventoryError("could not find public class haxe.http.HttpNodeJs in pinned source")
    type_name = module
    extends = f" extends {class_match.group(2)}" if class_match.group(2) else ""
    normalized_source = normalize_source(str(source), std_root)
    add_raw_api(
        merged,
        module=module,
        type_name=type_name,
        type_kind="class",
        row_kind="type",
        scope="type",
        name="HttpNodeJs",
        signature=f"class {type_name}{extends}",
        profile=NODEJS_SOURCE_PROFILE,
        source=normalized_source,
    )
    field_pattern = re.compile(r"^\s*public\s+var\s+(\w+)\s*:\s*([^;]+);", re.MULTILINE)
    function_pattern = re.compile(
        r"^\s*public\s+(?:(?:override|inline|dynamic|final|extern)\s+)*function\s+(\w+)"
        r"\s*(<[^\n{]+>)?\s*\(([^)]*)\)\s*(?::\s*([^\n{]+))?",
        re.MULTILINE,
    )
    for match in field_pattern.finditer(text):
        add_raw_api(
            merged,
            module=module,
            type_name=type_name,
            type_kind="class",
            row_kind="field",
            scope="instance",
            name=match.group(1),
            signature=re.sub(r"\s+", " ", match.group(2).strip()),
            profile=NODEJS_SOURCE_PROFILE,
            source=normalized_source,
        )
    for match in function_pattern.finditer(text):
        params = re.sub(r"\s+", " ", (match.group(2) or "").strip())
        arguments = re.sub(r"\s+", " ", match.group(3).strip())
        returns = re.sub(r"\s+", " ", (match.group(4) or "Void").strip())
        add_raw_api(
            merged,
            module=module,
            type_name=type_name,
            type_kind="class",
            row_kind="method",
            scope="constructor" if match.group(1) == "new" else "instance",
            name=match.group(1),
            signature=f"{params}({arguments}) -> {returns}",
            profile=NODEJS_SOURCE_PROFILE,
            source=normalized_source,
        )
    extracted_names = {
        key[5]
        for key in merged
        if key[0] == module and key[3] != "type"
    }
    expected_names = {"responseHeaders", "new", "cancel", "request"}
    if extracted_names != expected_names:
        raise InventoryError(
            "haxe.http.HttpNodeJs source fallback changed; expected public members "
            f"{sorted(expected_names)}, got {sorted(extracted_names)}"
        )


def extract_cs_host_source_api(
    merged: dict[tuple[str, ...], dict[str, Any]], source: Path, std_root: Path
) -> None:
    """Record the public fields added only by Haxe's C# `sys.net.Host`."""
    text = source.read_text(encoding="utf-8")
    expected = {
        "hostEntry": ("IPHostEntry", "cs.system.net.IPHostEntry"),
        "ipAddress": ("IPAddress", "cs.system.net.IPAddress"),
    }
    field_pattern = re.compile(
        r"^\s*public\s+var\s+(\w+)\s*\(default,\s*null\)\s*:\s*([\w.]+)\s*;",
        re.MULTILINE,
    )
    discovered = {
        name: source_type
        for name, source_type in field_pattern.findall(text)
        if name in expected
    }
    expected_source_types = {name: values[0] for name, values in expected.items()}
    if discovered != expected_source_types:
        raise InventoryError(
            "C# sys.net.Host source fallback changed; expected target-only fields "
            f"{expected_source_types}, got {discovered}"
        )

    normalized_source = normalize_source(str(source), std_root)
    for name, (_source_type, public_type) in sorted(expected.items()):
        add_raw_api(
            merged,
            module="sys.net.Host",
            type_name="sys.net.Host",
            type_kind="class",
            row_kind="field",
            scope="instance",
            name=name,
            signature=public_type,
            profile=CS_SOURCE_PROFILE,
            source=normalized_source,
        )


def extract_cs_exception_source_api(
    merged: dict[tuple[str, ...], dict[str, Any]],
    exception_source: Path,
    value_exception_source: Path,
    std_root: Path,
) -> None:
    """Record exception methods whose public visibility is specific to C#."""
    exception_text = exception_source.read_text(encoding="utf-8")
    value_exception_text = value_exception_source.read_text(encoding="utf-8")
    declarations = [
        (
            r"static\s+public\s+function\s+caught\s*\(value:Any\)\s*:Exception",
            "haxe.Exception",
            "static",
            "caught",
            "(value:Any) -> haxe.Exception",
            exception_source,
        ),
        (
            r"static\s+public\s+function\s+thrown\s*\(value:Any\)\s*:Any",
            "haxe.Exception",
            "static",
            "thrown",
            "(value:Any) -> Any",
            exception_source,
        ),
        (
            r"public\s+function\s+unwrap\s*\(\)\s*:Any",
            "haxe.Exception",
            "instance",
            "unwrap",
            "() -> Any",
            exception_source,
        ),
        (
            r"override\s+function\s+unwrap\s*\(\)\s*:Any",
            "haxe.ValueException",
            "instance",
            "unwrap",
            "() -> Any",
            value_exception_source,
        ),
    ]
    for pattern, type_name, scope, name, signature, source in declarations:
        text = exception_text if source == exception_source else value_exception_text
        if not re.search(pattern, text):
            raise InventoryError(
                f"C# exception source fallback changed; could not verify {type_name}.{name}"
            )
        add_raw_api(
            merged,
            module=type_name,
            type_name=type_name,
            type_kind="class",
            row_kind="method",
            scope=scope,
            name=name,
            signature=signature,
            profile=CS_SOURCE_PROFILE,
            source=normalize_source(str(source), std_root),
        )
        if type_name == "haxe.ValueException":
            add_raw_api(
                merged,
                module=type_name,
                type_name=type_name,
                type_kind="class",
                row_kind="method",
                scope=scope,
                name=name,
                signature=signature,
                profile=CS_SOURCE_PROFILE,
                source=normalize_source(str(exception_source), std_root),
            )


def finalize_surface(
    merged: dict[tuple[str, ...], dict[str, Any]], modules: dict[str, Path]
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for key in sorted(merged):
        raw = merged[key]
        logical = "|".join(key)
        if raw["kind"] == "type":
            digest = sha256_text(logical)[:12]
            api_id = f"{raw['module']}::type:{raw['type']}@{digest}"
            overload_group = None
        else:
            digest = sha256_text(logical)[:12]
            api_id = f"{raw['module']}::{raw['type']}::{raw['scope']}.{raw['name']}@{digest}"
            overload_group = f"{raw['module']}::{raw['type']}::{raw['scope']}.{raw['name']}"
        row = {
            "apiId": api_id,
            "module": raw["module"],
            "type": raw["type"],
            "typeKind": raw["typeKind"],
            "kind": raw["kind"],
            "scope": raw["scope"],
            "name": raw["name"],
            "signature": raw["signature"],
            "overloadGroup": overload_group,
            "profiles": sorted(raw["profiles"]),
            "targetCondition": " || ".join(sorted(raw["profiles"])),
            "sources": sorted(raw["sources"]),
            "metadata": sorted(raw["metadata"]),
        }
        rows.append(row)
        if raw["kind"] == "type":
            profile_signatures: dict[str, str] = {}
            for profile in sorted(raw["profiles"]):
                signatures = raw["profileSignatures"].get(profile) or {raw["signature"]}
                if len(signatures) != 1:
                    raise InventoryError(
                        f"multiple type declarations for {raw['type']} in profile {profile}: "
                        f"{sorted(signatures)}"
                    )
                profile_signatures[profile] = next(iter(signatures))
            row["targetSignatures"] = profile_signatures
    present_modules = {row["module"] for row in rows}
    missing = sorted(set(modules) - present_modules)
    extra = sorted(present_modules - set(modules))
    if missing or extra:
        raise InventoryError(f"public surface module mismatch; missing={missing}, extra={extra}")
    groups: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
    for row in rows:
        if row["overloadGroup"]:
            groups[row["overloadGroup"]].append(row)
    for group_rows in groups.values():
        ordered = sorted(group_rows, key=lambda item: (item["signature"], item["apiId"]))
        for index, row in enumerate(ordered):
            row["overloadIndex"] = index
            row["overloadCount"] = len(ordered)
    for row in rows:
        if row["overloadGroup"] is None:
            row["overloadIndex"] = 0
            row["overloadCount"] = 1
    api_ids = [row["apiId"] for row in rows]
    duplicates = sorted(item for item, count in collections.Counter(api_ids).items() if count > 1)
    if duplicates:
        raise InventoryError(f"duplicate API IDs after surface extraction: {duplicates}")
    return sorted(rows, key=lambda item: item["apiId"])


def module_surface_digest(module: str, rows: list[dict[str, Any]]) -> str:
    payload = []
    for row in rows:
        if row["module"] != module:
            continue
        payload.append(
            "|".join(
                [
                    row["apiId"],
                    row["signature"],
                    ",".join(row["profiles"]),
                    ",".join(row["sources"]),
                    json.dumps(row.get("targetSignatures", {}), sort_keys=True),
                ]
            )
        )
    return sha256_text("\n".join(payload))


def semantic_task(module: str) -> str:
    host_prefixes = ("sys.", "haxe.io.", "haxe.http.")
    host_modules = {"Sys", "haxe.Http", "haxe.EntryPoint", "haxe.MainLoop", "haxe.Timer"}
    return SEMANTIC_HOST_TASK if module.startswith(host_prefixes) or module in host_modules else SEMANTIC_CORE_TASK


def applicability_for(module: str) -> tuple[str, str]:
    if module.startswith("haxe.macro."):
        return "compile-time", "Haxe macro API; it runs inside the Haxe compiler, not in generated Elixir."
    if module.startswith("haxe.display."):
        return "compiler-display", "Haxe editor/display-server API; it is not part of generated Elixir programs."
    if module.startswith("haxe.extern."):
        return "compile-time", "Typing helper for extern declarations; the compiler erases it before generated Elixir runs."
    if module == "haxe.http.HttpJs":
        return "other-target", "Browser XMLHttpRequest implementation selected only for the JavaScript target."
    if module == "haxe.http.HttpNodeJs":
        return "other-target", "Node.js HTTP implementation selected only when the nodejs define and hxnodejs types are present."
    return "runtime", "Public API that can be used by Haxe code compiled to Elixir."


def policy_from_manifest(
    module: str,
    digest: str,
    manifest_entries: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    applicability, applicability_reason = applicability_for(module)
    if applicability != "runtime":
        return {
            "module": module,
            "surfaceDigest": digest,
            "applicability": applicability,
            "applicabilityReason": applicability_reason,
            "supportState": "not-applicable",
            "evidenceState": "not-required",
            "evidence": [],
            "blockers": [],
            "reviewNote": "Excluded only from the generated-Elixir runtime contract; the API remains inventoried.",
        }

    decision = manifest_entries.get(module)
    support = "unknown"
    evidence_state = "missing"
    evidence: list[dict[str, str]] = []
    review_note = "No module-level runtime-conformance decision exists yet."
    if decision:
        status = decision["status"]
        review_note = decision.get("reason") or f"Upstream unitstd status: {status}."
        if status in {"enabled", "adapted"}:
            support = "supported"
            evidence_state = "module-runtime"
            evidence.append(
                {
                    "kind": "upstream-unitstd",
                    "path": decision["fixture"],
                    "selector": decision.get("source", module),
                }
            )
        elif status == "skipped-target-specific":
            support = "partial"
        elif status == "skipped-unsupported":
            support = "unsupported"
        elif status == "no-upstream-spec":
            support = "unknown"
        else:
            raise InventoryError(f"unknown upstream unitstd status for {module}: {status}")

    blockers: list[str] = []
    if support != "supported":
        blockers.append(semantic_task(module))
    if evidence_state != "api-runtime":
        blockers.append(EVIDENCE_TASK)
    return {
        "module": module,
        "surfaceDigest": digest,
        "applicability": applicability,
        "applicabilityReason": applicability_reason,
        "supportState": support,
        "evidenceState": evidence_state,
        "evidence": evidence,
        "blockers": sorted(set(blockers)),
        "reviewNote": review_note,
    }


def build_initial_policy(haxe_version: str, rows: list[dict[str, Any]], modules: Iterable[str]) -> dict[str, Any]:
    manifest = load_json(UNITSTD_MANIFEST)
    manifest_entries = {item["module"]: item for item in manifest.get("modules", [])}
    policies = [
        policy_from_manifest(module, module_surface_digest(module, rows), manifest_entries)
        for module in sorted(modules)
    ]
    return {
        "schemaVersion": POLICY_SCHEMA_VERSION,
        "haxeVersion": haxe_version,
        "meaning": {
            "api-runtime": "Evidence names the ordinary-Haxe runtime assertion(s) for this exact API row.",
            "module-runtime": "A runtime suite covers the module, but coverage has not yet been mapped to every API row.",
            "missing": "No exact runtime evidence is recorded for this API row.",
            "not-required": "The declaration does not run in generated Elixir; the applicability reason explains why.",
        },
        "modules": policies,
        "apiOverrides": [],
    }


def latest_beads() -> dict[str, dict[str, Any]]:
    issues: dict[str, dict[str, Any]] = {}
    if not BEADS_PATH.exists():
        return issues
    for line in BEADS_PATH.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            item = json.loads(line)
        except json.JSONDecodeError as error:
            raise InventoryError(f"invalid JSON in .beads/issues.jsonl: {error}") from error
        issue_id = item.get("id")
        if issue_id:
            issues[issue_id] = item
    return issues


def validate_evidence(evidence: Any, *, label: str, exact: bool) -> list[dict[str, str]]:
    if not isinstance(evidence, list):
        raise InventoryError(f"{label}.evidence must be a list")
    normalized: list[dict[str, str]] = []
    for index, item in enumerate(evidence):
        if not isinstance(item, dict):
            raise InventoryError(f"{label}.evidence[{index}] must be an object")
        kind = item.get("kind")
        path_value = item.get("path")
        selector = item.get("selector")
        if not all(isinstance(value, str) and value.strip() for value in (kind, path_value, selector)):
            raise InventoryError(f"{label}.evidence[{index}] needs non-empty kind, path, and selector")
        if Path(path_value).is_absolute() or path_value.startswith("../"):
            raise InventoryError(f"{label}.evidence[{index}] path must be repository-relative")
        if not (ROOT / path_value).exists():
            raise InventoryError(f"{label}.evidence[{index}] path is stale: {path_value}")
        if exact and selector in {"*", "all", "module"}:
            raise InventoryError(f"{label}.evidence[{index}] needs an exact selector")
        if exact:
            if not path_value.endswith(".hx"):
                raise InventoryError(
                    f"{label}.evidence[{index}] must point to an ordinary-Haxe runtime test"
                )
            evidence_text = (ROOT / path_value).read_text(encoding="utf-8")
            if selector not in evidence_text:
                raise InventoryError(
                    f"{label}.evidence[{index}] selector is stale: {selector!r} is not in {path_value}"
                )
        normalized.append({"kind": kind, "path": path_value, "selector": selector})
    return normalized


def validate_blockers(blockers: Any, *, label: str, issues: dict[str, dict[str, Any]]) -> list[str]:
    if not isinstance(blockers, list) or any(not isinstance(item, str) for item in blockers):
        raise InventoryError(f"{label}.blockers must be a list of Beads IDs")
    if len(blockers) != len(set(blockers)):
        raise InventoryError(f"{label}.blockers contains duplicates")
    for blocker in blockers:
        issue = issues.get(blocker)
        if not issue:
            raise InventoryError(f"{label} references missing blocker {blocker}")
        if issue.get("status") in {"closed", "complete"}:
            raise InventoryError(f"{label} references closed blocker {blocker}")
    return blockers


def validate_policy(
    policy: dict[str, Any],
    *,
    haxe_version: str,
    rows: list[dict[str, Any]],
    modules: dict[str, Path],
) -> tuple[dict[str, dict[str, Any]], dict[str, dict[str, Any]]]:
    if policy.get("schemaVersion") != POLICY_SCHEMA_VERSION:
        raise InventoryError(f"api-policy.json schemaVersion must be {POLICY_SCHEMA_VERSION}")
    if policy.get("haxeVersion") != haxe_version:
        raise InventoryError(
            f"api-policy.json pins Haxe {policy.get('haxeVersion')!r}, expected {haxe_version}; review and refresh it"
        )
    entries = policy.get("modules")
    if not isinstance(entries, list):
        raise InventoryError("api-policy.json modules must be a list")
    by_module: dict[str, dict[str, Any]] = {}
    for entry in entries:
        if not isinstance(entry, dict) or not isinstance(entry.get("module"), str):
            raise InventoryError("every api-policy module entry needs a module name")
        module = entry["module"]
        if module in by_module:
            raise InventoryError(f"duplicate api-policy module: {module}")
        by_module[module] = entry
    missing = sorted(set(modules) - set(by_module))
    stale = sorted(set(by_module) - set(modules))
    if missing or stale:
        raise InventoryError(f"api-policy module drift; missing={missing}, stale={stale}")

    issues = latest_beads()
    for module, entry in sorted(by_module.items()):
        label = f"module {module}"
        expected_digest = module_surface_digest(module, rows)
        if entry.get("surfaceDigest") != expected_digest:
            raise InventoryError(
                f"{label} public surface changed; review its API diff and run --refresh-policy"
            )
        applicability = entry.get("applicability")
        support = entry.get("supportState")
        evidence_state = entry.get("evidenceState")
        blockers = validate_blockers(entry.get("blockers"), label=label, issues=issues)
        if applicability not in ALLOWED_APPLICABILITY:
            raise InventoryError(f"{label} has invalid applicability {applicability!r}")
        if support not in ALLOWED_SUPPORT:
            raise InventoryError(f"{label} has invalid supportState {support!r}")
        if evidence_state not in ALLOWED_EVIDENCE:
            raise InventoryError(f"{label} has invalid evidenceState {evidence_state!r}")
        for field in ("applicabilityReason", "reviewNote"):
            if not isinstance(entry.get(field), str) or not entry[field].strip():
                raise InventoryError(f"{label} needs a clear {field}")
        entry["evidence"] = validate_evidence(
            entry.get("evidence"), label=label, exact=evidence_state == "api-runtime"
        )
        if applicability == "runtime":
            if support == "not-applicable" or evidence_state == "not-required":
                raise InventoryError(f"{label} is runtime-relevant and cannot be marked not applicable")
            if evidence_state == "api-runtime":
                raise InventoryError(
                    f"{label} cannot claim API-level evidence for every row at module level; use apiOverrides"
                )
            needs_blocker = support != "supported" or evidence_state != "api-runtime"
            if needs_blocker and not blockers:
                raise InventoryError(f"{label} is not release-ready and needs an open blocker")
        else:
            if support != "not-applicable" or evidence_state != "not-required":
                raise InventoryError(f"{label} is non-runtime and must use not-applicable/not-required")
            if blockers:
                raise InventoryError(f"{label} is non-runtime and must not carry runtime blockers")
    row_ids = {row["apiId"] for row in rows}
    overrides: dict[str, dict[str, Any]] = {}
    for override in policy.get("apiOverrides") or []:
        if not isinstance(override, dict) or not isinstance(override.get("apiId"), str):
            raise InventoryError("every apiOverrides entry needs an apiId")
        api_id = override["apiId"]
        if api_id in overrides:
            raise InventoryError(f"duplicate API override: {api_id}")
        if api_id not in row_ids:
            raise InventoryError(f"stale API override: {api_id}")
        label = f"API override {api_id}"
        allowed_fields = {"apiId", "supportState", "evidenceState", "evidence", "blockers", "reviewNote"}
        unknown_fields = sorted(set(override) - allowed_fields)
        if unknown_fields:
            raise InventoryError(f"{label} has unknown fields: {unknown_fields}")
        if "supportState" in override and override["supportState"] not in ALLOWED_SUPPORT:
            raise InventoryError(f"{label} has invalid supportState {override['supportState']!r}")
        if "evidenceState" in override and override["evidenceState"] not in ALLOWED_EVIDENCE:
            raise InventoryError(f"{label} has invalid evidenceState {override['evidenceState']!r}")
        if "evidence" in override:
            override["evidence"] = validate_evidence(
                override["evidence"],
                label=label,
                exact=override.get("evidenceState") == "api-runtime",
            )
        if "blockers" in override:
            override["blockers"] = validate_blockers(override["blockers"], label=label, issues=issues)
        if "reviewNote" in override and (
            not isinstance(override["reviewNote"], str) or not override["reviewNote"].strip()
        ):
            raise InventoryError(f"{label}.reviewNote must be clear text")
        overrides[api_id] = override
    return by_module, overrides


def collect_local_ownership(reference_modules: set[str]) -> dict[str, list[str]]:
    owned: dict[str, set[str]] = collections.defaultdict(set)

    def add_tree(root: Path, prefix: str = "", *, allow_cross: bool = True) -> None:
        if not root.exists():
            return
        for path in sorted(root.rglob("*.hx")):
            relative = path.relative_to(root)
            value = relative.as_posix()
            if value.endswith(".cross.hx"):
                if not allow_cross:
                    continue
                value = value[: -len(".cross.hx")]
            else:
                value = value[:-3]
            module = value.replace("/", ".")
            if prefix:
                module = prefix + "." + module
            if module in reference_modules:
                owned[module].add(path.relative_to(ROOT).as_posix())

    local_std = ROOT / "std"
    elixir_std = ROOT / "std/elixir/_std"
    if local_std.exists():
        for path in sorted(local_std.rglob("*.hx")):
            try:
                path.relative_to(elixir_std)
                continue
            except ValueError:
                pass
            relative = path.relative_to(local_std)
            if relative.parts and relative.parts[0] == "elixir":
                continue
            value = relative.as_posix()
            if value.endswith(".cross.hx"):
                value = value[: -len(".cross.hx")]
            else:
                value = value[:-3]
            module = value.replace("/", ".")
            if module in reference_modules:
                owned[module].add(path.relative_to(ROOT).as_posix())
    add_tree(elixir_std, allow_cross=False)
    add_tree(ROOT / "src/haxe", "haxe")
    add_tree(ROOT / "src/sys", "sys")

    transformer = "src/reflaxe/elixir/ast/transformers/StdHaxeRuntimeOverrideTransforms.hx"
    for module in {"EReg", "haxe.exceptions.PosException", "haxe.iterators.ArrayIterator"}:
        if module in reference_modules and (ROOT / transformer).exists():
            owned[module].add(transformer)
    return {module: sorted(paths) for module, paths in owned.items()}


def resolved_classification(
    row: dict[str, Any],
    module_policy: dict[str, Any],
    override: dict[str, Any] | None,
    ownership: dict[str, list[str]],
    runtime_baseline_modules: set[str] | None = None,
) -> dict[str, Any]:
    runtime_baseline_modules = runtime_baseline_modules or set()
    if row["profiles"] == [CS_SOURCE_PROFILE]:
        classification = {
            "applicability": "other-target",
            "applicabilityReason": (
                "Public declaration added only by Haxe's C# target implementation; "
                "it is not part of generated Elixir programs."
            ),
            "supportState": "not-applicable",
            "evidenceState": "not-required",
            "evidence": [],
            "blockers": [],
            "reviewNote": "Kept in the pinned public inventory as a C#-only extension.",
        }
    elif (
        module_policy["applicability"] == "runtime"
        and row["module"] in runtime_baseline_modules
        and "macro" not in row["profiles"]
    ):
        profiles = ", ".join(row["profiles"])
        classification = {
            "applicability": "other-target",
            "applicabilityReason": (
                f"Declaration appears only in the pinned {profiles} target profile(s), not in "
                "the macro/eval portable baseline used for generated Elixir."
            ),
            "supportState": "not-applicable",
            "evidenceState": "not-required",
            "evidence": [],
            "blockers": [],
            "reviewNote": "Kept in the inventory as a typed target-specific API variant.",
        }
    else:
        classification = {
            "applicability": module_policy["applicability"],
            "applicabilityReason": module_policy["applicabilityReason"],
            "supportState": module_policy["supportState"],
            "evidenceState": module_policy["evidenceState"],
            "evidence": copy.deepcopy(module_policy["evidence"]),
            "blockers": list(module_policy["blockers"]),
            "reviewNote": module_policy["reviewNote"],
        }
    if override:
        for field in ("supportState", "evidenceState", "evidence", "blockers", "reviewNote"):
            if field in override:
                classification[field] = copy.deepcopy(override[field])
    applicability = classification["applicability"]
    if applicability == "runtime":
        owner_paths = ownership.get(row["module"], [])
        classification["implementationOwner"] = (
            "reflaxe-elixir-target" if owner_paths else "official-haxe-stdlib-fallback"
        )
        classification["ownerEvidence"] = owner_paths or [f"std/{row['module'].replace('.', '/')}.hx"]
    elif applicability in {"compile-time", "compiler-display"}:
        classification["implementationOwner"] = "haxe-compiler"
        classification["ownerEvidence"] = row["sources"]
    else:
        classification["implementationOwner"] = "haxe-other-target"
        classification["ownerEvidence"] = row["sources"]
    return classification


def validate_resolved_classification(row: dict[str, Any], classification: dict[str, Any]) -> None:
    label = row["apiId"]
    applicability = classification.get("applicability")
    support = classification.get("supportState")
    evidence_state = classification.get("evidenceState")
    if applicability not in ALLOWED_APPLICABILITY:
        raise InventoryError(f"{label} has an invalid API applicability")
    if support not in ALLOWED_SUPPORT or evidence_state not in ALLOWED_EVIDENCE:
        raise InventoryError(f"{label} has an invalid API override classification")
    evidence = validate_evidence(
        classification.get("evidence"), label=f"API {label}", exact=evidence_state == "api-runtime"
    )
    classification["evidence"] = evidence
    if applicability == "runtime":
        if support == "not-applicable" or evidence_state == "not-required":
            raise InventoryError(f"runtime API override cannot mark {label} not applicable")
        ready = support == "supported" and evidence_state == "api-runtime"
        if not ready and not classification.get("blockers"):
            raise InventoryError(f"non-ready API override needs an open blocker: {label}")
        if ready and classification.get("blockers"):
            raise InventoryError(f"release-ready API override still has blockers: {label}")
    elif (
        support != "not-applicable"
        or evidence_state != "not-required"
        or classification.get("blockers")
    ):
        raise InventoryError(
            f"non-runtime API must use not-applicable/not-required with no blockers: {label}"
        )


def build_inventory(
    *,
    haxe_version: str,
    std_root: Path,
    modules: dict[str, Path],
    rows: list[dict[str, Any]],
    policy: dict[str, Any],
) -> dict[str, Any]:
    by_module, overrides = validate_policy(
        policy, haxe_version=haxe_version, rows=rows, modules=modules
    )
    ownership = collect_local_ownership(set(modules))
    runtime_baseline_modules = {
        row["module"] for row in rows if "macro" in row["profiles"]
    }
    inventory_rows: list[dict[str, Any]] = []
    for source_row in rows:
        row = copy.deepcopy(source_row)
        classification = resolved_classification(
            row,
            by_module[row["module"]],
            overrides.get(row["apiId"]),
            ownership,
            runtime_baseline_modules,
        )
        validate_resolved_classification(row, classification)
        row["classification"] = classification
        inventory_rows.append(row)

    module_summaries: list[dict[str, Any]] = []
    for module in sorted(modules):
        module_rows = [row for row in inventory_rows if row["module"] == module]
        module_policy = by_module[module]
        representative = next(
            (
                row["classification"]
                for row in module_rows
                if row["classification"]["applicability"] == module_policy["applicability"]
            ),
            module_rows[0]["classification"],
        )
        api_applicability = collections.Counter(
            row["classification"]["applicability"] for row in module_rows
        )
        module_summaries.append(
            {
                "module": module,
                "source": "std/" + modules[module].relative_to(std_root).as_posix(),
                "surfaceDigest": module_surface_digest(module, rows),
                "apiRows": len(module_rows),
                "typeRows": sum(row["kind"] == "type" for row in module_rows),
                "memberRows": sum(row["kind"] != "type" for row in module_rows),
                "applicability": module_policy["applicability"],
                "apiApplicability": dict(sorted(api_applicability.items())),
                "implementationOwner": representative["implementationOwner"],
                "supportState": module_policy["supportState"],
                "evidenceState": module_policy["evidenceState"],
                "blockers": module_policy["blockers"],
            }
        )

    applicability_counts = collections.Counter(
        row["classification"]["applicability"] for row in inventory_rows
    )
    support_counts = collections.Counter(
        row["classification"]["supportState"] for row in inventory_rows
    )
    evidence_counts = collections.Counter(
        row["classification"]["evidenceState"] for row in inventory_rows
    )
    owner_counts = collections.Counter(
        row["classification"]["implementationOwner"] for row in inventory_rows
    )
    runtime_rows = [row for row in inventory_rows if row["classification"]["applicability"] == "runtime"]
    blocked_rows = [
        row
        for row in runtime_rows
        if row["classification"]["supportState"] != "supported"
        or row["classification"]["evidenceState"] != "api-runtime"
    ]
    overload_groups: dict[str, int] = {}
    for row in inventory_rows:
        if row["overloadGroup"]:
            overload_groups[row["overloadGroup"]] = row["overloadCount"]
    overload_rows = sum(max(0, count - 1) for count in overload_groups.values())
    runtime_without_baseline = sorted(
        module
        for module, module_policy in by_module.items()
        if module_policy["applicability"] == "runtime" and module not in runtime_baseline_modules
    )
    return {
        "schemaVersion": SCHEMA_VERSION,
        "haxe": {
            "version": haxe_version,
            "sourceFingerprint": source_fingerprint(modules, std_root),
            "sourceRoot": "$HAXE_STD_PATH",
        },
        "profiles": [
            {"id": name, "description": description}
            for name, description, _arguments in PROFILE_DEFINITIONS
        ]
        + [
            {
                "id": NODEJS_SOURCE_PROFILE,
                "description": "Node.js-only source declaration fallback",
            },
            {
                "id": CS_SOURCE_PROFILE,
                "description": "C#-only public declarations read from the pinned target source",
            },
        ],
        "applicabilityBaseline": {
            "profile": "macro",
            "meaning": (
                "When a runtime module is present in macro/eval, declarations found only in other "
                "target profiles are target-specific rather than Elixir runtime requirements."
            ),
            "runtimeModulesWithoutBaseline": runtime_without_baseline,
        },
        "counts": {
            "modules": len(module_summaries),
            "apiRows": len(inventory_rows),
            "typeRows": sum(row["kind"] == "type" for row in inventory_rows),
            "memberRows": sum(row["kind"] != "type" for row in inventory_rows),
            "overloadRowsBeyondPrimary": overload_rows,
            "runtimeApiRows": len(runtime_rows),
            "releaseBlockingRuntimeApiRows": len(blocked_rows),
            "byApplicability": dict(sorted(applicability_counts.items())),
            "bySupportState": dict(sorted(support_counts.items())),
            "byEvidenceState": dict(sorted(evidence_counts.items())),
            "byImplementationOwner": dict(sorted(owner_counts.items())),
        },
        "modules": module_summaries,
        "apis": inventory_rows,
    }


def render_json(value: Any) -> str:
    return json.dumps(value, indent=2, ensure_ascii=False) + "\n"


def markdown_table(counts: dict[str, int], label: str) -> str:
    lines = [f"| {label} | API rows |", "|---|---:|"]
    lines.extend(f"| `{key}` | {value:,} |" for key, value in counts.items())
    return "\n".join(lines)


def render_summary(inventory: dict[str, Any]) -> str:
    counts = inventory["counts"]
    lines = [
        "# Haxe stdlib API inventory",
        "",
        "This is the checked public surface of the Haxe version pinned by `.haxerc`. It answers a",
        "different question from the older file-count report: a local override file is ownership, not",
        "proof that every public function works.",
        "",
        "An **API row** is one public type, field, property, method signature, enum constructor, or",
        "overload. **API-level runtime evidence** means a checked ordinary-Haxe test names the exact row",
        "it exercises and runs the generated Elixir. Module-wide tests remain useful, but they do not",
        "automatically prove every method in that module.",
        "",
        "Most rows come from Haxe's typed compiler data across ten targets. The Node.js HTTP module",
        "and public C#-only additions use narrow source readers because their external target libraries",
        "are not part of this repository. Each reader checks the exact declarations it expects and",
        "fails if the pinned source changes.",
        "",
        "## Current result",
        "",
        f"- Pinned Haxe version: **{inventory['haxe']['version']}**",
        f"- Reference modules: **{counts['modules']:,}**",
        f"- Public API rows: **{counts['apiRows']:,}**",
        f"- Public type rows: **{counts['typeRows']:,}**",
        f"- Public member rows: **{counts['memberRows']:,}**",
        f"- Extra overload rows beyond each primary signature: **{counts['overloadRowsBeyondPrimary']:,}**",
        f"- Runtime-relevant API rows: **{counts['runtimeApiRows']:,}**",
        f"- Runtime rows still blocking 1.0: **{counts['releaseBlockingRuntimeApiRows']:,}**",
        "",
        "> [!IMPORTANT]",
        "> The final number is expected to be non-zero while the stdlib completion tasks are open.",
        "> `npm run guard:stdlib-api-inventory` keeps that debt explicit and current. The stricter",
        "> `npm run guard:stdlib-api-release-ready` fails until the number reaches zero.",
        "",
        "## What the classifications mean",
        "",
        "- `runtime`: the API can be called by a generated Elixir program and is part of the 1.0 promise.",
        "- `compile-time` / `compiler-display`: Haxe compiler tooling, not generated application code.",
        "- `other-target`: an implementation selected only by another Haxe target, such as browser JS.",
        "  When a module has a macro/eval baseline, a declaration found only in another target profile",
        "  goes in this group instead of becoming a false Elixir release blocker.",
        "- `module-runtime`: a runtime suite exists for the module, but its assertions are not yet mapped",
        "  to each public API row. It is therefore still a release-evidence blocker.",
        "",
        "The runtime modules that cannot be loaded in the macro/eval profile stay in the Elixir",
        "contract and are reviewed directly: "
        + ", ".join(
            f"`{module}`"
            for module in inventory["applicabilityBaseline"]["runtimeModulesWithoutBaseline"]
        )
        + ".",
        "",
        "## Counts by applicability",
        "",
        markdown_table(counts["byApplicability"], "Applicability"),
        "",
        "## Counts by support state",
        "",
        markdown_table(counts["bySupportState"], "Support state"),
        "",
        "## Counts by evidence state",
        "",
        markdown_table(counts["byEvidenceState"], "Evidence state"),
        "",
        "## Module review list",
        "",
        "| Module | API rows | Applies to Elixir runtime? | Implementation owner | Support | Evidence | Open work |",
        "|---|---:|---|---|---|---|---|",
    ]
    for module in inventory["modules"]:
        blockers = ", ".join(f"`{item}`" for item in module["blockers"]) or "—"
        applicability = " + ".join(
            f"`{key}` ({value:,})" for key, value in module["apiApplicability"].items()
        )
        lines.append(
            f"| `{module['module']}` | {module['apiRows']:,} | {applicability} | "
            f"`{module['implementationOwner']}` | `{module['supportState']}` | "
            f"`{module['evidenceState']}` | {blockers} |"
        )
    lines.extend(
        [
            "",
            "## Commands",
            "",
            "```bash",
            "# Normal CI check: regenerate and compare the checked files.",
            "npm run guard:stdlib-api-inventory",
            "",
            "# Intentional update after policy review.",
            "python3 scripts/stdlib-api-inventory.py --update",
            "",
            "# Explicitly acknowledge a reviewed Haxe API-surface change, then update outputs.",
            "python3 scripts/stdlib-api-inventory.py --refresh-policy",
            "python3 scripts/stdlib-api-inventory.py --update",
            "",
            "# Major-1 readiness check; this must fail while any runtime blocker remains.",
            "npm run guard:stdlib-api-release-ready",
            "```",
            "",
            "The machine-readable rows, signatures, target profiles, owners, evidence paths, and blockers",
            "are in [`api-inventory.json`](api-inventory.json). Human review decisions live in",
            "[`api-policy.json`](api-policy.json). Neither file contains machine-local absolute paths.",
            "",
        ]
    )
    return "\n".join(lines)


def compare_checked(path: Path, expected: str) -> None:
    try:
        actual = path.read_text(encoding="utf-8")
    except FileNotFoundError as error:
        raise InventoryError(f"missing checked inventory output: {path.relative_to(ROOT)}") from error
    if actual != expected:
        raise InventoryError(
            f"{path.relative_to(ROOT)} is stale; review the API/policy diff and run "
            "python3 scripts/stdlib-api-inventory.py --update"
        )


def release_blockers(inventory: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        row
        for row in inventory["apis"]
        if row["classification"]["applicability"] == "runtime"
        and (
            row["classification"]["supportState"] != "supported"
            or row["classification"]["evidenceState"] != "api-runtime"
        )
    ]


def build_surface() -> tuple[str, Path, dict[str, Path], list[dict[str, Any]]]:
    profiles, haxe_version = generate_typed_profiles()
    std_root = find_std_root(profiles)
    modules = scan_reference_modules(std_root)
    merged = extract_typed_apis(profiles, modules, std_root)
    node_module = modules.get("haxe.http.HttpNodeJs")
    if not node_module:
        raise InventoryError("pinned stdlib no longer contains haxe.http.HttpNodeJs")
    extract_nodejs_source_api(merged, node_module, std_root)
    cs_host = std_root / "cs/_std/sys/net/Host.hx"
    if not cs_host.exists():
        raise InventoryError("pinned stdlib no longer contains the C# sys.net.Host target source")
    extract_cs_host_source_api(merged, cs_host, std_root)
    cs_exception = std_root / "cs/_std/haxe/Exception.hx"
    value_exception = modules.get("haxe.ValueException")
    if not cs_exception.exists() or not value_exception:
        raise InventoryError("pinned stdlib no longer contains the C# exception target sources")
    extract_cs_exception_source_api(merged, cs_exception, value_exception, std_root)
    rows = finalize_surface(merged, modules)
    return haxe_version, std_root, modules, rows


def refresh_policy(existing: dict[str, Any] | None, haxe_version: str, rows: list[dict[str, Any]], modules: dict[str, Path]) -> dict[str, Any]:
    if existing is None:
        return build_initial_policy(haxe_version, rows, modules)
    refreshed = copy.deepcopy(existing)
    refreshed["schemaVersion"] = POLICY_SCHEMA_VERSION
    refreshed["haxeVersion"] = haxe_version
    old_entries = {item["module"]: item for item in refreshed.get("modules") or [] if isinstance(item, dict) and item.get("module")}
    initial = build_initial_policy(haxe_version, rows, modules)
    new_entries = []
    for default in initial["modules"]:
        entry = old_entries.get(default["module"], default)
        entry["surfaceDigest"] = default["surfaceDigest"]
        new_entries.append(entry)
    stale = sorted(set(old_entries) - set(modules))
    if stale:
        raise InventoryError(f"refusing to silently remove stale policy modules: {stale}")
    refreshed["modules"] = new_entries
    return refreshed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="regenerate in memory and compare checked outputs")
    mode.add_argument("--update", action="store_true", help="write the generated JSON and Markdown outputs")
    mode.add_argument("--refresh-policy", action="store_true", help="acknowledge the current reviewed public surface")
    parser.add_argument("--release-ready", action="store_true", help="also reject every non-ready runtime API")
    args = parser.parse_args(argv)

    haxe_version, std_root, modules, rows = build_surface()
    if args.refresh_policy:
        existing = load_json(POLICY_PATH) if POLICY_PATH.exists() else None
        policy = refresh_policy(existing, haxe_version, rows, modules)
        POLICY_PATH.write_text(render_json(policy), encoding="utf-8")
        print(f"[stdlib-api] refreshed {POLICY_PATH.relative_to(ROOT)} for {len(modules)} modules")
        return 0

    policy = load_json(POLICY_PATH)
    inventory = build_inventory(
        haxe_version=haxe_version,
        std_root=std_root,
        modules=modules,
        rows=rows,
        policy=policy,
    )
    inventory_text = render_json(inventory)
    summary_text = render_summary(inventory)
    if args.update:
        INVENTORY_PATH.write_text(inventory_text, encoding="utf-8")
        SUMMARY_PATH.write_text(summary_text, encoding="utf-8")
        print(
            f"[stdlib-api] wrote {inventory['counts']['modules']} modules and "
            f"{inventory['counts']['apiRows']} API rows"
        )
    else:
        compare_checked(INVENTORY_PATH, inventory_text)
        compare_checked(SUMMARY_PATH, summary_text)
        print(
            f"[stdlib-api] OK: {inventory['counts']['modules']} modules, "
            f"{inventory['counts']['apiRows']} API rows, deterministic checked output"
        )

    blockers = release_blockers(inventory)
    if args.release_ready and blockers:
        by_reason = collections.Counter(
            (
                row["classification"]["supportState"],
                row["classification"]["evidenceState"],
            )
            for row in blockers
        )
        print("[stdlib-api] NOT READY FOR 1.0:", file=sys.stderr)
        for (support, evidence), count in sorted(by_reason.items()):
            print(f"  - {count} API rows: support={support}, evidence={evidence}", file=sys.stderr)
        print(f"  See {SUMMARY_PATH.relative_to(ROOT)} and the recorded open Beads tasks.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except InventoryError as error:
        print(f"[stdlib-api] ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)

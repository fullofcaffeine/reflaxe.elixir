#!/usr/bin/env python3
"""Focused tests for the stdlib API inventory policy and source extraction."""

from __future__ import annotations

import copy
import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/stdlib-api-inventory.py"
SPEC = importlib.util.spec_from_file_location("stdlib_api_inventory", SCRIPT)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"could not load {SCRIPT}")
inventory = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(inventory)


def sample_row(module: str = "Sample") -> dict:
    return {
        "apiId": f"{module}::type:{module}",
        "module": module,
        "type": module,
        "typeKind": "class",
        "kind": "type",
        "scope": "type",
        "name": module,
        "signature": f"class {module}",
        "overloadGroup": None,
        "profiles": ["macro"],
        "targetCondition": "macro",
        "sources": [f"std/{module}.hx"],
        "metadata": [],
        "overloadIndex": 0,
        "overloadCount": 1,
    }


class StdlibApiInventoryTest(unittest.TestCase):
    def test_java_profile_has_a_complete_scoped_backend_descriptor(self) -> None:
        self.assertEqual(inventory.pinned_hxjava_version(), "4.2.0")

    def test_typed_profiles_run_inside_the_repository_lix_scope(self) -> None:
        with tempfile.TemporaryDirectory() as raw_temp:
            json_path = Path(raw_temp) / "java.json"
            json_path.write_text("[]", encoding="utf-8")
            command = ["haxe", "-java", str(Path(raw_temp) / "java")]
            with patch.object(inventory, "command_output") as run:
                self.assertEqual(
                    inventory.execute_typed_profile(command, json_path=json_path, name="java"),
                    [],
                )

        run.assert_called_once_with(command, cwd=inventory.ROOT, timeout=60)

    def test_type_renderer_is_readable_and_stable(self) -> None:
        function_type = {
            "kind": "TFun",
            "args": {
                "args": [
                    {
                        "name": "value",
                        "opt": True,
                        "t": {
                            "kind": "TInst",
                            "args": {
                                "path": {"pack": [], "typeName": "String"},
                                "params": [],
                            },
                        },
                    }
                ],
                "ret": {
                    "kind": "TAbstract",
                    "args": {
                        "path": {"pack": [], "typeName": "Bool"},
                        "params": [],
                    },
                },
            },
        }
        self.assertEqual(inventory.render_type(function_type), "(?value:String) -> Bool")
        dynamic_type = {
            "kind": "TDynamic",
            "args": {
                "kind": "TInst",
                "args": {
                    "path": {"pack": [], "typeName": "String"},
                    "params": [],
                },
            },
        }
        self.assertEqual(inventory.render_type(dynamic_type), "Dynamic<String>")

    def test_type_declaration_tracks_inheritance_and_abstract_contract(self) -> None:
        class_item = {
            "pack": ["sample"],
            "name": "Child",
            "moduleName": "Child",
            "kind": "class",
            "params": [],
            "args": {
                "isExtern": False,
                "isFinal": True,
                "isAbstract": False,
                "isInterface": False,
                "superClass": {
                    "path": {"pack": ["sample"], "typeName": "Parent"},
                    "params": [],
                },
                "interfaces": [
                    {
                        "path": {"pack": ["sample"], "typeName": "Named"},
                        "params": [],
                    }
                ],
            },
        }
        self.assertEqual(
            inventory.render_type_declaration(class_item),
            "final class sample.Child extends sample.Parent implements sample.Named",
        )
        abstract_item = {
            "pack": ["sample"],
            "name": "Id",
            "moduleName": "Id",
            "kind": "abstract",
            "params": [],
            "args": {
                "type": {
                    "kind": "TAbstract",
                    "args": {
                        "path": {"pack": [], "typeName": "Int"},
                        "params": [],
                    },
                },
                "from": [
                    {
                        "t": {
                            "kind": "TAbstract",
                            "args": {
                                "path": {"pack": [], "typeName": "Int"},
                                "params": [],
                            },
                        },
                        "field": None,
                    }
                ],
                "to": [],
                "binops": [{"op": {"kind": "OpAdd"}, "field": "add"}],
                "unops": [],
                "array": [],
                "read": None,
                "write": None,
            },
        }
        self.assertEqual(
            inventory.render_type_declaration(abstract_item),
            "abstract sample.Id(Int) [binary OpAdd via add; from Int]",
        )

    def test_nodejs_source_fallback_is_narrow_and_complete(self) -> None:
        source_text = """
package haxe.http;
#if nodejs
class HttpNodeJs extends haxe.http.HttpBase {
  public var responseHeaders:Map<String, String>;
  public function new(url:String) {}
  public function cancel() {}
  public override function request(?post:Bool) {}
  var privateState:Int;
}
#end
"""
        with tempfile.TemporaryDirectory() as raw_temp:
            std_root = Path(raw_temp) / "std"
            source = std_root / "haxe/http/HttpNodeJs.hx"
            source.parent.mkdir(parents=True)
            source.write_text(source_text, encoding="utf-8")
            merged = {}
            inventory.extract_nodejs_source_api(merged, source, std_root)
        names = sorted(key[5] for key in merged if key[3] != "type")
        self.assertEqual(names, ["cancel", "new", "request", "responseHeaders"])

    def test_csharp_host_source_fallback_records_only_target_extensions(self) -> None:
        source_text = """
package sys.net;
class Host {
  public var hostEntry(default, null):IPHostEntry;
  public var ipAddress(default, null):IPAddress;
  public var host(default, null):String;
}
"""
        with tempfile.TemporaryDirectory() as raw_temp:
            std_root = Path(raw_temp) / "std"
            source = std_root / "cs/_std/sys/net/Host.hx"
            source.parent.mkdir(parents=True)
            source.write_text(source_text, encoding="utf-8")
            merged = {}
            inventory.extract_cs_host_source_api(merged, source, std_root)

        self.assertEqual(sorted(key[5] for key in merged), ["hostEntry", "ipAddress"])
        rows = inventory.finalize_surface(merged, {"sys.net.Host": source})
        for row in rows:
            classification = inventory.resolved_classification(
                row,
                {
                    "applicability": "runtime",
                    "applicabilityReason": "Ordinary runtime API.",
                    "supportState": "unknown",
                    "evidenceState": "missing",
                    "evidence": [],
                    "blockers": [inventory.SEMANTIC_HOST_TASK, inventory.EVIDENCE_TASK],
                    "reviewNote": "Runtime review pending.",
                },
                None,
                {},
            )
            inventory.validate_resolved_classification(row, classification)
            self.assertEqual(classification["applicability"], "other-target")
            self.assertEqual(classification["supportState"], "not-applicable")
            self.assertEqual(classification["blockers"], [])

    def test_csharp_exception_source_fallback_records_effective_public_methods(self) -> None:
        exception_text = """
package haxe;
class Exception {
  static public function caught(value:Any):Exception { return null; }
  static public function thrown(value:Any):Any { return value; }
  public function unwrap():Any { return null; }
}
"""
        value_exception_text = """
package haxe;
class ValueException extends Exception {
  override function unwrap():Any { return null; }
}
"""
        with tempfile.TemporaryDirectory() as raw_temp:
            std_root = Path(raw_temp) / "std"
            exception_source = std_root / "cs/_std/haxe/Exception.hx"
            value_exception_source = std_root / "haxe/ValueException.hx"
            exception_source.parent.mkdir(parents=True)
            value_exception_source.parent.mkdir(parents=True)
            exception_source.write_text(exception_text, encoding="utf-8")
            value_exception_source.write_text(value_exception_text, encoding="utf-8")
            merged = {}
            inventory.extract_cs_exception_source_api(
                merged, exception_source, value_exception_source, std_root
            )

        names = sorted((key[1], key[5]) for key in merged)
        self.assertEqual(
            names,
            [
                ("haxe.Exception", "caught"),
                ("haxe.Exception", "thrown"),
                ("haxe.Exception", "unwrap"),
                ("haxe.ValueException", "unwrap"),
            ],
        )

    def test_policy_rejects_missing_and_stale_surface_reviews(self) -> None:
        row = sample_row()
        modules = {"Sample": ROOT / "Std.hx"}
        module_policy = {
            "module": "Sample",
            "surfaceDigest": inventory.module_surface_digest("Sample", [row]),
            "applicability": "runtime",
            "applicabilityReason": "Public runtime API.",
            "supportState": "unknown",
            "evidenceState": "missing",
            "evidence": [],
            "blockers": [inventory.SEMANTIC_CORE_TASK, inventory.EVIDENCE_TASK],
            "reviewNote": "Awaiting semantic and exact runtime evidence.",
        }
        policy = {
            "schemaVersion": inventory.POLICY_SCHEMA_VERSION,
            "haxeVersion": "4.3.7",
            "modules": [module_policy],
            "apiOverrides": [],
        }
        inventory.validate_policy(policy, haxe_version="4.3.7", rows=[row], modules=modules)

        missing = copy.deepcopy(policy)
        missing["modules"] = []
        with self.assertRaisesRegex(inventory.InventoryError, "module drift"):
            inventory.validate_policy(missing, haxe_version="4.3.7", rows=[row], modules=modules)

        stale = copy.deepcopy(policy)
        stale["modules"][0]["surfaceDigest"] = "0" * 64
        with self.assertRaisesRegex(inventory.InventoryError, "public surface changed"):
            inventory.validate_policy(stale, haxe_version="4.3.7", rows=[row], modules=modules)

    def test_api_runtime_evidence_requires_a_real_haxe_selector(self) -> None:
        path = "test/haxe_exunit/stdlib_parity/src_haxe/stdlib_parity/StdlibParityTest.hx"
        evidence = [
            {
                "kind": "haxe-exunit",
                "path": path,
                "selector": "testBytesCompareUsesBinaryOrdering",
            }
        ]
        self.assertEqual(
            inventory.validate_evidence(evidence, label="test", exact=True), evidence
        )
        stale = copy.deepcopy(evidence)
        stale[0]["selector"] = "testThatDoesNotExist"
        with self.assertRaisesRegex(inventory.InventoryError, "selector is stale"):
            inventory.validate_evidence(stale, label="test", exact=True)

    def test_release_gate_counts_support_and_evidence_gaps(self) -> None:
        blocked = sample_row("Blocked")
        blocked["classification"] = {
            "applicability": "runtime",
            "supportState": "supported",
            "evidenceState": "module-runtime",
        }
        ready = sample_row("Ready")
        ready["classification"] = {
            "applicability": "runtime",
            "supportState": "supported",
            "evidenceState": "api-runtime",
        }
        compiler_only = sample_row("CompilerOnly")
        compiler_only["classification"] = {
            "applicability": "compile-time",
            "supportState": "not-applicable",
            "evidenceState": "not-required",
        }
        result = inventory.release_blockers({"apis": [blocked, ready, compiler_only]})
        self.assertEqual([row["apiId"] for row in result], [blocked["apiId"]])

    def test_typed_target_extension_does_not_become_an_elixir_blocker(self) -> None:
        row = sample_row("Date")
        row["profiles"] = ["js"]
        module_policy = {
            "applicability": "runtime",
            "applicabilityReason": "Public runtime API.",
            "supportState": "unknown",
            "evidenceState": "missing",
            "evidence": [],
            "blockers": [inventory.SEMANTIC_CORE_TASK, inventory.EVIDENCE_TASK],
            "reviewNote": "Runtime review pending.",
        }
        classification = inventory.resolved_classification(
            row, module_policy, None, {}, {"Date"}
        )
        inventory.validate_resolved_classification(row, classification)
        self.assertEqual(classification["applicability"], "other-target")
        self.assertEqual(classification["evidenceState"], "not-required")
        self.assertEqual(classification["blockers"], [])


if __name__ == "__main__":
    unittest.main(verbosity=2)

# Haxe stdlib API inventory

This is the checked public surface of the Haxe version pinned by `.haxerc`. It answers a
different question from the older file-count report: a local override file is ownership, not
proof that every public function works.

An **API row** is one public type, field, property, method signature, enum constructor, or
overload. **API-level runtime evidence** means a checked ordinary-Haxe test names the exact row
it exercises and runs the generated Elixir. Module-wide tests remain useful, but they do not
automatically prove every method in that module.

Most rows come from Haxe's typed compiler data across ten targets. The Node.js HTTP module
and public C#-only additions use narrow source readers because their external target libraries
are not part of this repository. Each reader checks the exact declarations it expects and
fails if the pinned source changes.

## Current result

- Pinned Haxe version: **4.3.7**
- Pinned Java typing adapter: **hxjava 4.2.0**
- Reference modules: **204**
- Public API rows: **3,692**
- Public type rows: **494**
- Public member rows: **3,198**
- Extra overload rows beyond each primary signature: **68**
- Runtime-relevant API rows: **1,981**
- Runtime rows still blocking 1.0: **1,981**

> [!IMPORTANT]
> The final number is expected to be non-zero while the stdlib completion tasks are open.
> `npm run guard:stdlib-api-inventory` keeps that debt explicit and current. The stricter
> `npm run guard:stdlib-api-release-ready` fails until the number reaches zero.

## What the classifications mean

- `runtime`: the API can be called by a generated Elixir program and is part of the 1.0 promise.
- `compile-time` / `compiler-display`: Haxe compiler tooling, not generated application code.
- `other-target`: an implementation selected only by another Haxe target, such as browser JS.
  When a module has a macro/eval baseline, a declaration found only in another target profile
  goes in this group instead of becoming a false Elixir release blocker.
- `module-runtime`: a runtime suite exists for the module, but its assertions are not yet mapped
  to each public API row. It is therefore still a release-evidence blocker.

The runtime modules that cannot be loaded in the macro/eval profile stay in the Elixir
contract and are reviewed directly: `haxe.atomic.AtomicBool`, `haxe.atomic.AtomicInt`, `haxe.atomic.AtomicObject`, `sys.db.Mysql`, `sys.db.Sqlite`.

## Counts by applicability

| Applicability | API rows |
|---|---:|
| `compile-time` | 733 |
| `compiler-display` | 733 |
| `other-target` | 245 |
| `runtime` | 1,981 |

## Counts by support state

| Support state | API rows |
|---|---:|
| `not-applicable` | 1,711 |
| `partial` | 170 |
| `supported` | 380 |
| `unknown` | 1,409 |
| `unsupported` | 22 |

## Counts by evidence state

| Evidence state | API rows |
|---|---:|
| `missing` | 1,601 |
| `module-runtime` | 380 |
| `not-required` | 1,711 |

## Module review list

| Module | API rows | Applies to Elixir runtime? | Implementation owner | Support | Evidence | Open work |
|---|---:|---|---|---|---|---|
| `Any` | 1 | `runtime` (1) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `Array` | 50 | `other-target` (25) + `runtime` (25) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `Class` | 1 | `runtime` (1) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `Date` | 61 | `other-target` (39) + `runtime` (22) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `DateTools` | 11 | `other-target` (1) + `runtime` (10) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `EReg` | 13 | `other-target` (1) + `runtime` (12) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `Enum` | 1 | `runtime` (1) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `EnumValue` | 2 | `runtime` (2) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `IntIterator` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `Lambda` | 20 | `runtime` (20) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `List` | 1 | `runtime` (1) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `Map` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `Math` | 28 | `runtime` (28) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `Reflect` | 17 | `runtime` (17) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `Std` | 10 | `runtime` (10) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `StdTypes` | 16 | `other-target` (1) + `runtime` (15) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `String` | 31 | `other-target` (17) + `runtime` (14) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `StringBuf` | 7 | `runtime` (7) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `StringTools` | 24 | `runtime` (24) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `Sys` | 26 | `other-target` (4) + `runtime` (22) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `Type` | 32 | `other-target` (1) + `runtime` (31) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `UInt` | 1 | `runtime` (1) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `UnicodeString` | 12 | `other-target` (7) + `runtime` (5) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `Xml` | 43 | `runtime` (43) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.CallStack` | 15 | `other-target` (1) + `runtime` (14) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.Constraints` | 15 | `runtime` (15) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.DynamicAccess` | 10 | `runtime` (10) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.EntryPoint` | 6 | `runtime` (6) | `official-haxe-stdlib-fallback` | `unsupported` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.EnumFlags` | 8 | `runtime` (8) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.EnumTools` | 11 | `runtime` (11) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Exception` | 11 | `other-target` (3) + `runtime` (8) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Http` | 5 | `other-target` (4) + `runtime` (1) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Int32` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Int64` | 33 | `runtime` (33) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Int64Helper` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Json` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Log` | 5 | `other-target` (2) + `runtime` (3) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.MainLoop` | 14 | `other-target` (1) + `runtime` (13) | `official-haxe-stdlib-fallback` | `unsupported` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.NativeStackTrace` | 35 | `other-target` (30) + `runtime` (5) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.PosInfos` | 6 | `runtime` (6) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Resource` | 4 | `runtime` (4) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Rest` | 9 | `runtime` (9) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Serializer` | 10 | `runtime` (10) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.SysTools` | 4 | `runtime` (4) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Template` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Timer` | 7 | `runtime` (7) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Ucs2` | 13 | `runtime` (13) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Unserializer` | 10 | `runtime` (10) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.Utf8` | 12 | `runtime` (12) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ValueException` | 4 | `other-target` (1) + `runtime` (3) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.atomic.AtomicBool` | 6 | `runtime` (6) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.atomic.AtomicInt` | 11 | `runtime` (11) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.atomic.AtomicObject` | 6 | `runtime` (6) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.crypto.Adler32` | 8 | `runtime` (8) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.crypto.Base64` | 9 | `runtime` (9) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.crypto.BaseCode` | 8 | `runtime` (8) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.crypto.Crc32` | 6 | `runtime` (6) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.crypto.Hmac` | 7 | `runtime` (7) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.crypto.Md5` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.crypto.Sha1` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.crypto.Sha224` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.crypto.Sha256` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.display.Diagnostic` | 47 | `compiler-display` (47) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.display.Display` | 312 | `compiler-display` (312) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.display.FsPath` | 3 | `compiler-display` (3) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.display.JsonModuleTypes` | 242 | `compiler-display` (242) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.display.Position` | 9 | `compiler-display` (9) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.display.Protocol` | 38 | `compiler-display` (38) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.display.Server` | 82 | `compiler-display` (82) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.ds.ArraySort` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.BalancedTree` | 21 | `other-target` (1) + `runtime` (20) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.Either` | 3 | `runtime` (3) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.EnumValueMap` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.GenericStack` | 14 | `runtime` (14) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.HashMap` | 11 | `runtime` (11) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.IntMap` | 12 | `runtime` (12) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.List` | 17 | `runtime` (17) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.ListSort` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `unsupported` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.Map` | 13 | `runtime` (13) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.ObjectMap` | 27 | `other-target` (15) + `runtime` (12) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.Option` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.ReadOnlyArray` | 3 | `runtime` (3) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.StringMap` | 12 | `runtime` (12) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.Vector` | 16 | `runtime` (16) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.ds.WeakMap` | 12 | `runtime` (12) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.exceptions.ArgumentException` | 3 | `runtime` (3) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.exceptions.NotImplementedException` | 2 | `runtime` (2) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.exceptions.PosException` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.extern.AsVar` | 1 | `compile-time` (1) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.extern.EitherType` | 1 | `compile-time` (1) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.extern.Rest` | 1 | `compile-time` (1) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.format.JsonParser` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.format.JsonPrinter` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.http.HttpBase` | 16 | `runtime` (16) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.http.HttpJs` | 8 | `other-target` (8) | `haxe-other-target` | `not-applicable` | `not-required` | — |
| `haxe.http.HttpMethod` | 10 | `runtime` (10) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.http.HttpNodeJs` | 5 | `other-target` (5) | `haxe-other-target` | `not-applicable` | `not-required` | — |
| `haxe.http.HttpStatus` | 62 | `runtime` (62) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.ArrayBufferView` | 18 | `runtime` (18) | `official-haxe-stdlib-fallback` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.BufferInput` | 9 | `runtime` (9) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Bytes` | 29 | `other-target` (1) + `runtime` (28) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.BytesBuffer` | 12 | `runtime` (12) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.BytesData` | 7 | `other-target` (6) + `runtime` (1) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.BytesInput` | 13 | `other-target` (7) + `runtime` (6) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.BytesOutput` | 14 | `other-target` (8) + `runtime` (6) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Encoding` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Eof` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Error` | 5 | `runtime` (5) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.FPHelper` | 7 | `other-target` (2) + `runtime` (5) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Float32Array` | 15 | `runtime` (15) | `official-haxe-stdlib-fallback` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Float64Array` | 15 | `runtime` (15) | `official-haxe-stdlib-fallback` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Input` | 19 | `runtime` (19) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Int32Array` | 15 | `runtime` (15) | `official-haxe-stdlib-fallback` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Mime` | 315 | `runtime` (315) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Output` | 19 | `runtime` (19) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Path` | 17 | `runtime` (17) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.Scheme` | 7 | `runtime` (7) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.StringInput` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.UInt16Array` | 15 | `runtime` (15) | `official-haxe-stdlib-fallback` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.UInt32Array` | 15 | `runtime` (15) | `official-haxe-stdlib-fallback` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.io.UInt8Array` | 15 | `runtime` (15) | `official-haxe-stdlib-fallback` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.ArrayIterator` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.ArrayKeyValueIterator` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.DynamicAccessIterator` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.DynamicAccessKeyValueIterator` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.HashMapKeyValueIterator` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.MapKeyValueIterator` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.RestIterator` | 3 | `runtime` (3) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.RestKeyValueIterator` | 3 | `runtime` (3) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.StringIterator` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.StringIteratorUnicode` | 5 | `runtime` (5) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.StringKeyValueIterator` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.iterators.StringKeyValueIteratorUnicode` | 5 | `runtime` (5) | `reflaxe-elixir-target` | `supported` | `module-runtime` | `haxe.elixir.codex-0yn.10.5` |
| `haxe.macro.CompilationServer` | 13 | `compile-time` (13) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.Compiler` | 66 | `compile-time` (66) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.ComplexTypeTools` | 3 | `compile-time` (3) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.Context` | 69 | `compile-time` (69) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.DisplayMode` | 12 | `compile-time` (12) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.ExampleJSGenerator` | 4 | `compile-time` (4) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.Expr` | 209 | `compile-time` (209) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.ExprTools` | 8 | `compile-time` (8) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.Format` | 2 | `compile-time` (2) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.JSGenApi` | 13 | `compile-time` (13) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.MacroStringTools` | 6 | `compile-time` (6) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.MacroType` | 1 | `compile-time` (1) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.PlatformConfig` | 43 | `compile-time` (43) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.PositionTools` | 5 | `compile-time` (5) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.Printer` | 23 | `compile-time` (23) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.Tools` | 6 | `compile-time` (6) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.Type` | 227 | `compile-time` (227) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.TypeTools` | 15 | `compile-time` (15) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.macro.TypedExprTools` | 5 | `compile-time` (5) | `haxe-compiler` | `not-applicable` | `not-required` | — |
| `haxe.rtti.CType` | 126 | `runtime` (126) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.rtti.Meta` | 4 | `runtime` (4) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.rtti.Rtti` | 3 | `runtime` (3) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.rtti.XmlParser` | 7 | `runtime` (7) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.xml.Access` | 13 | `runtime` (13) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.xml.Check` | 17 | `runtime` (17) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.xml.Fast` | 1 | `runtime` (1) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.xml.Parser` | 10 | `runtime` (10) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.xml.Printer` | 2 | `runtime` (2) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.zip.Compress` | 7 | `other-target` (1) + `runtime` (6) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.zip.Entry` | 13 | `runtime` (13) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.zip.FlushMode` | 6 | `runtime` (6) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.zip.Huffman` | 7 | `runtime` (7) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.zip.InflateImpl` | 4 | `runtime` (4) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.zip.Reader` | 6 | `runtime` (6) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.zip.Tools` | 3 | `runtime` (3) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.zip.Uncompress` | 6 | `runtime` (6) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `haxe.zip.Writer` | 5 | `runtime` (5) | `official-haxe-stdlib-fallback` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.3`, `haxe.elixir.codex-0yn.10.5` |
| `sys.FileStat` | 12 | `runtime` (12) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.FileSystem` | 11 | `runtime` (11) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.Http` | 12 | `runtime` (12) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.db.Connection` | 11 | `runtime` (11) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.db.Mysql` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.db.ResultSet` | 12 | `runtime` (12) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.db.Sqlite` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.io.File` | 15 | `other-target` (5) + `runtime` (10) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.io.FileInput` | 24 | `other-target` (17) + `runtime` (7) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.io.FileOutput` | 24 | `other-target` (17) + `runtime` (7) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.io.FileSeek` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.io.Process` | 10 | `other-target` (1) + `runtime` (9) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.net.Address` | 7 | `runtime` (7) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.net.Host` | 9 | `other-target` (2) + `runtime` (7) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.net.Socket` | 22 | `other-target` (2) + `runtime` (20) | `reflaxe-elixir-target` | `partial` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.net.UdpSocket` | 5 | `runtime` (5) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.ssl.Certificate` | 15 | `other-target` (1) + `runtime` (14) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.ssl.Digest` | 4 | `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.ssl.DigestAlgorithm` | 8 | `runtime` (8) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.ssl.Key` | 5 | `other-target` (1) + `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.ssl.Socket` | 18 | `other-target` (2) + `runtime` (16) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.Condition` | 8 | `runtime` (8) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.Deque` | 5 | `runtime` (5) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.ElasticThreadPool` | 7 | `runtime` (7) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.EventLoop` | 16 | `runtime` (16) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.FixedThreadPool` | 6 | `runtime` (6) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.IThreadPool` | 7 | `runtime` (7) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.Lock` | 5 | `other-target` (1) + `runtime` (4) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.Mutex` | 5 | `runtime` (5) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.NoEventLoopException` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.Semaphore` | 5 | `runtime` (5) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.Thread` | 14 | `other-target` (4) + `runtime` (10) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.ThreadPoolException` | 2 | `runtime` (2) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |
| `sys.thread.Tls` | 3 | `runtime` (3) | `reflaxe-elixir-target` | `unknown` | `missing` | `haxe.elixir.codex-0yn.10.4`, `haxe.elixir.codex-0yn.10.5` |

## Commands

```bash
# Normal CI check: regenerate and compare the checked files.
npm run guard:stdlib-api-inventory

# Intentional update after policy review.
python3 scripts/stdlib-api-inventory.py --update

# Explicitly acknowledge a reviewed Haxe API-surface change, then update outputs.
python3 scripts/stdlib-api-inventory.py --refresh-policy
python3 scripts/stdlib-api-inventory.py --update

# Major-1 readiness check; this must fail while any runtime blocker remains.
npm run guard:stdlib-api-release-ready
```

The machine-readable rows, signatures, target profiles, owners, evidence paths, and blockers
are in [`api-inventory.json`](api-inventory.json). Human review decisions live in
[`api-policy.json`](api-policy.json). Neither file contains machine-local absolute paths.

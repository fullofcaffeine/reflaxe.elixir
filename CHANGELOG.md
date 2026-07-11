# Changelog

GitHub Releases are the version-specific release notes. This file keeps curated migration context
that remains useful across versions; released version identity comes from protected Git tags.

## Unreleased

### Bug Fixes

* **release:** restore complete GitHub Release notes by keeping the Conventional Commits preset on
  the writer contract supported by the pinned semantic-release generator; exercise the real notes
  pipeline in tests and stop publication before tagging when generated notes contain only a heading.

## [0.14.26](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.25...v0.14.26) (2026-07-11)

### Bug Fixes

* **release:** activate the immutable tested-commit publication protocol and document consumer digest verification plus the superseded `haxe.elixir.codex-m81` / `v0.14.23` release-commit design as historical predecessor evidence ([0b82ba8](https://github.com/fullofcaffeine/reflaxe.elixir/commit/0b82ba82180cc51b4adc1b2ce825f7feab391ab7))

The package, checksum, tag identity, and signed provenance for this release are valid. Its GitHub
Release body contains only the generated version heading because the then-pinned Conventional
Commits preset used a newer writer-template contract than the release-notes generator. Because the
release is immutable, the body is preserved as published; the next patch release carries the fix and
complete notes instead of rewriting `v0.14.26`.

## [0.14.25](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.24...v0.14.25) (2026-07-10)


### Bug Fixes

* **release:** skip verification on no-op ([f52adf7](https://github.com/fullofcaffeine/reflaxe.elixir/commit/f52adf7b882d5e252c1ac69fad936cbd5d665441))

## [0.14.24](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.23...v0.14.24) (2026-07-10)


### Bug Fixes

* **stdlib:** enable typed array runtime parity ([76ab79e](https://github.com/fullofcaffeine/reflaxe.elixir/commit/76ab79e89b35bdcfa2a89ba3d1976449e9cabbbd))

## [0.14.23](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.22...v0.14.23) (2026-07-10)


### Bug Fixes

* **release:** verify staged release state ([212be20](https://github.com/fullofcaffeine/reflaxe.elixir/commit/212be207e99c925c1aa897ff3f03a2cfe8b731ed))

## [0.14.22](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.21...v0.14.22) (2026-07-10)


### Bug Fixes

* **release:** verify published compiler packages ([8b2bcf1](https://github.com/fullofcaffeine/reflaxe.elixir/commit/8b2bcf1f7b53a137a98aec6984c53608d0db813f))

## [0.14.21](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.20...v0.14.21) (2026-07-09)


### Bug Fixes

* **reflaxe:** publish built packages for consumers ([4b3345f](https://github.com/fullofcaffeine/reflaxe.elixir/commit/4b3345f350272972905d478d3cf02212c6dab56c))

## Release protocol migration record (July 2026)

### Changed

* **release:** replace mutable manifest-owned version/generation state with a tag-owned SemVer policy core; delegate Conventional Commit classification to the pinned official analyzer, validate versions with locked `semver`, keep `0.x` breaking changes minor until an independently approved graduation change, and require a durable approval for every stable major.
* **release:** replace the original single graduation-evidence gate with independent, dated per-major approval records; approval remains non-releasing, and a subsequent new breaking commit is required to derive the authorized stable major.
* **release:** replace tracked version/changelog generation and release commits with development sentinels plus temporary Reflaxe package staging; tags now identify the unchanged tested source commit.
* **release:** make no-op semantic-release runs skip published-package verification; successful publication passes the exact newly created tag to the verifier instead of inferring a prior release from tracked package metadata.
* **release:** build the complete Haxelib package twice with a pinned canonical ZIP writer, require byte-identical output, validate safe layout/modes and staged source identity, smoke the exact ZIP, and publish its SHA-256 sidecar.
* **docs:** reconcile current-facing release language with the real pre-1.0 lineage; label old `v1.0.x`/`v1.1.x` milestones as unshipped historical plans and point entrypoints to the canonical generated posture.
* **test:** add adversarial release-artifact coverage for metadata mismatch, missing/unexpected/unsafe entries, duplicate names, symlinks, unsafe modes, and environment-independent archive bytes.
* **generator:** resolve scaffold package URLs from staged release metadata or the source checkout's nearest immutable tag, never from tracked development sentinels.
* **ci:** install the locked Node and Beam toolchains in package/release jobs before invoking canonical ZIP and exact-ZIP Mix/Phoenix verification.
* **ci:** make normal publication the final same-SHA `main` CI job with explicit compiler, package, examples, dogfood, sentinel, and security dependencies; remove detached `workflow_run` polling and the manual normal-release bypass.
* **release:** bind checked-out HEAD, local/origin version tags, staged package metadata, approved ZIP/checksum bytes, and immutable hosted asset digests; replace unverified backfill with reviewer-gated existing-tag-only repair and signed GitHub release-attestation verification.
* **security:** pin every third-party GitHub Action to a reviewed full commit SHA, lock Node and all direct npm tools exactly, upgrade the release/Haxe toolchain dependency graph, and enforce a zero-high-severity npm audit before publication.
* **ci:** preserve the CI-selected Node/Haxe `PATH` in the example compiler runner and force direct Haxe compilation so compiler-server macro state cannot leak between example projects.
* **examples:** align the Phoenix chat app's local scoped libraries with the canonical Reflaxe pair so `vendor/reflaxe/src` and the Elixir stdlib roots are present before compiler typing in clean development builds.
* **stdlib:** classify `haxe.io.Mime` and `haxe.io.Scheme` as verified official Haxe fallback modules; add runtime, snapshot, and source-versus-package coverage without duplicating their String enum-abstract definitions in the target stdlib.
* **compiler:** preserve omitted Haxe method defaults from Reflaxe's typed `ClassFuncData` instead of always passing `nil`, and keep multi-expression constructor blocks grouped when they are assigned as values.
* **stdlib:** enable all upstream `haxe.io.ArrayBufferView` and typed-array runtime specs through the official Haxe fallback; preserve shared Bytes views while keeping source and built-package output identical.
* **reflaxe:** align stdlib override sources with the Reflaxe `_std` layout; scoped source-tree builds now load `std/elixir/_std` before target-owned `std` APIs so PhoenixHx/examples keep using the Elixir stdlib overrides in dev mode.
* **reflaxe:** move remaining upstream-colliding `std/haxe/**` replacement modules into `std/elixir/_std`, leaving plain `std/haxe/**` for target-owned support surfaces.
* **reflaxe:** move the authored `haxe.Exception` override into `std/elixir/_std/haxe/Exception.hx`; Reflaxe now creates `src/haxe/Exception.cross.hx` only in built release packages, matching the Rust and OCaml target layout without changing exception semantics.
* **reflaxe:** align package entrypoint HXML files with Reflaxe-generated targets by applying package-scoped `nullSafety("reflaxe.elixir")` before bootstrap/init macros.
* **reflaxe:** enforce that checked-in source trees contain no `.cross.hx` package artifacts; upstream-colliding overrides must be authored under `std/elixir/_std` and flattened by Reflaxe at release time.
* **reflaxe:** move BEAM `sys.*` stdlib replacements into `std/elixir/_std/sys` so Reflaxe packages them as `.cross.hx` files instead of shadowing host/eval `sys.*` during package CLI runs.
* **ci:** strengthen the haxelib package smoke to assert the installed artifact keeps Reflaxe-flattened `src/**/*.cross.hx` overrides and does not publish source-only `_std` layout roots.
* **ci:** audit every checked-in scoped `reflaxe.elixir.hxml` so nested example/PhoenixHx development cannot silently omit the target `_std` root and fall back to upstream modules.
* **ci:** make local dogfood and docs smoke render the canonical scoped HXML after `lix dev`, covering external source-checkout projects instead of relying on late bootstrap insertion.
* **ci:** compile the same fixture from source and from the installed Reflaxe package, requiring byte-identical generated Elixir outside volatile/source-path metadata.
* **qa:** make `qa-logpeek --until-done` recognize completed logs and follow new lines without a `tail -f` pipeline race.
* **release:** attach the Reflaxe-built haxelib zip to every GitHub Release and use that immutable package for Lix installs; raw GitHub tags remain source checkouts rather than pretending to be flattened packages.
* **release:** use a fixed semantic-release asset path with a versioned upload name, then download and inspect the published package so a missing or malformed release asset fails the workflow; use GitHub's `www` release URL so Lix resolves the zip as an HTTPS archive instead of source, and make both project generators pin their installed compiler version.
* **examples:** align the Phoenix chat app-local scoped library entry with the full Reflaxe source-checkout classpath contract and refresh its generated test helper output.
* **ci:** validate the installed package CLI entrypoint so `main: "Run"` and `src/Run.hx` stay aligned in release artifacts.
* **reflaxe:** audit vendored framework patches against upstream Reflaxe plus the Rust/OCaml converted targets, documenting which local fixes remain required, which are upstream candidates, and which drift needs a separate sync task.
* **reflaxe:** remove debug-only vendored framework drift while preserving required local Reflaxe patches.
* **docs:** document the source-checkout contract: use the scoped `haxe_libraries/reflaxe.elixir.hxml` (or the source-HXML helper), and install the versioned Reflaxe package artifact instead of consuming an unbuilt checkout through raw `haxelib dev` or `lix dev`.
* **docs:** explain that `-D reflaxe_runtime` is Reflaxe's compiler-typing convention, not an Elixir runtime mode, and record why current application HXML files still declare it explicitly.
* **docs:** update stdlib parity task templates to use the current `_std` / target-owned `std/**` / early `src/haxe/**` ownership model.

## [0.14.20](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.19...v0.14.20) (2026-07-09)


### Bug Fixes

* **ci:** use pinned Haxe for package smoke ([d5299f4](https://github.com/fullofcaffeine/reflaxe.elixir/commit/d5299f4eb0d86c903aa4e33923886219ba8f65ce))

## [0.14.19](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.18...v0.14.19) (2026-07-09)


### Bug Fixes

* **stdlib:** enable String runtime parity ([ba39d06](https://github.com/fullofcaffeine/reflaxe.elixir/commit/ba39d06687c6e5795e13dba544a7af7eb402167e))

## [0.14.18](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.17...v0.14.18) (2026-07-07)


### Bug Fixes

* **stdlib:** enable Date runtime parity ([3fe835a](https://github.com/fullofcaffeine/reflaxe.elixir/commit/3fe835a2bba03828f8cd622ea9a955e24e848660))

## [0.14.17](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.16...v0.14.17) (2026-07-07)


### Bug Fixes

* **compiler:** preserve returns in reducer loops ([ed55f98](https://github.com/fullofcaffeine/reflaxe.elixir/commit/ed55f98d66b14fbcdcb47ded7fdf11e3eca041e0))

## [0.14.16](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.15...v0.14.16) (2026-07-07)


### Bug Fixes

* **stdlib:** preserve option all none semantics ([30d5d3b](https://github.com/fullofcaffeine/reflaxe.elixir/commit/30d5d3b9a1631258f5b637ef7d6023914a8190e0))

## [0.14.15](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.14...v0.14.15) (2026-07-07)


### Bug Fixes

* **stdlib:** reject haxe main loop on elixir ([8ed620c](https://github.com/fullofcaffeine/reflaxe.elixir/commit/8ed620c5cc5147bafd7da72b96f084776f667872))

## [0.14.14](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.13...v0.14.14) (2026-07-07)


### Bug Fixes

* **compiler:** support typed enum helper reflection ([2cb5d93](https://github.com/fullofcaffeine/reflaxe.elixir/commit/2cb5d93cb589d81a3de05c7ffd51244a3d7cc4e8))

## [0.14.13](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.12...v0.14.13) (2026-07-07)


### Bug Fixes

* **stdlib:** reject haxe entry point on elixir ([37e6191](https://github.com/fullofcaffeine/reflaxe.elixir/commit/37e6191344661785583d04091a62d2f3ae6f99bc))

## [0.14.12](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.11...v0.14.12) (2026-07-07)


### Bug Fixes

* **perf:** watch todo shared contracts ([8c6ef49](https://github.com/fullofcaffeine/reflaxe.elixir/commit/8c6ef49963d6be5de23b4ba80306b3e2a53cfb4c))

## [0.14.11](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.10...v0.14.11) (2026-07-04)


### Bug Fixes

* **stdlib:** support haxe ds vector ([00fc40b](https://github.com/fullofcaffeine/reflaxe.elixir/commit/00fc40b61922236552ff4a08c4a10f9ee2b6e258))

## [0.14.10](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.9...v0.14.10) (2026-07-04)


### Bug Fixes

* **stdlib:** support haxe format json parser ([ad04b38](https://github.com/fullofcaffeine/reflaxe.elixir/commit/ad04b385a676ba9cc6c9fa5911248b1fbc6a1f49))

## [0.14.9](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.8...v0.14.9) (2026-07-04)


### Bug Fixes

* **stdlib:** make timer delay one-shot deterministic ([76619a1](https://github.com/fullofcaffeine/reflaxe.elixir/commit/76619a1e75e16881de3143fae47d5b56af1a91b7))
* **stdlib:** support haxe ds list ([53893c9](https://github.com/fullofcaffeine/reflaxe.elixir/commit/53893c9fa6eae5a5a4ae6643ab009f6aef1ee359))

## [0.14.8](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.7...v0.14.8) (2026-07-04)


### Bug Fixes

* **stdlib:** support string iterators ([5be6482](https://github.com/fullofcaffeine/reflaxe.elixir/commit/5be6482d2084de3262b797c13b66d4364903b717))

## [0.14.7](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.6...v0.14.7) (2026-07-04)


### Bug Fixes

* **stdlib:** support HashMap key value iterator ([5aa9b10](https://github.com/fullofcaffeine/reflaxe.elixir/commit/5aa9b10609e3185e022cdd1a02b1c7d1abb5bcd6))

## [0.14.6](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.5...v0.14.6) (2026-07-04)


### Bug Fixes

* **stdlib:** support haxe.ds HashMap ([0fc1beb](https://github.com/fullofcaffeine/reflaxe.elixir/commit/0fc1beb357211fb1fce4fe515df73c6567c0e198))

## [0.14.5](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.4...v0.14.5) (2026-07-04)


### Bug Fixes

* **stdlib:** support haxe.ds GenericStack ([2d80729](https://github.com/fullofcaffeine/reflaxe.elixir/commit/2d8072920b6f1d9d364d84d797a94367a26ad8ee))

## [0.14.4](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.3...v0.14.4) (2026-07-04)


### Bug Fixes

* **stdlib:** classify haxe.ds sorting helpers ([fd4d960](https://github.com/fullofcaffeine/reflaxe.elixir/commit/fd4d96013c5c6d8e4f91546115e9be0d337a3793))

## [0.14.3](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.2...v0.14.3) (2026-07-04)


### Bug Fixes

* **stdlib:** cover fallback haxe exceptions ([e369fb3](https://github.com/fullofcaffeine/reflaxe.elixir/commit/e369fb3af3e980b5ab31fcd61894f831b76c2c98))

## [0.14.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.1...v0.14.2) (2026-07-04)


### Bug Fixes

* **stdlib:** implement haxe Timer runtime ([332ab16](https://github.com/fullofcaffeine/reflaxe.elixir/commit/332ab16f2eccaa73cd84f29fa2a5374ed9599e79))

## [0.14.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.14.0...v0.14.1) (2026-07-03)


### Bug Fixes

* **compiler:** collapse nil-default iife helpers ([4cbcd31](https://github.com/fullofcaffeine/reflaxe.elixir/commit/4cbcd313cfd13cbb40c5103ae78237921beb5a3f))
* **compiler:** simplify embedded nil-default helpers ([15c1d6e](https://github.com/fullofcaffeine/reflaxe.elixir/commit/15c1d6e6bc38182560207f98dff58ae6d59505e7))
* **stdlib:** consolidate target std overrides ([8fc5cb9](https://github.com/fullofcaffeine/reflaxe.elixir/commit/8fc5cb947e6b067ac9cc6f9abcd6f5e0bbedda71))

# [0.14.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.13.0...v0.14.0) (2026-07-02)


### Features

* **stdlib:** add haxe.crypto.Sha224 parity ([d4b0344](https://github.com/fullofcaffeine/reflaxe.elixir/commit/d4b0344b217663540d9edf87cbc7f23a53d81f81))

# [0.13.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.12.2...v0.13.0) (2026-07-02)


### Features

* **stdlib:** add haxe.crypto.Sha256 parity ([eeb24a5](https://github.com/fullofcaffeine/reflaxe.elixir/commit/eeb24a5ee0a77d4744ba4eb703dbcd29aaac136e))

## [0.12.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.12.1...v0.12.2) (2026-07-01)


### Bug Fixes

* **codegen:** drop wildcard literal discards ([1a343be](https://github.com/fullofcaffeine/reflaxe.elixir/commit/1a343be0772773fd488748ae940c974d1bedbb57))

## [0.12.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.12.0...v0.12.1) (2026-07-01)


### Bug Fixes

* **todo-app:** decode boundary bools without casts ([a767142](https://github.com/fullofcaffeine/reflaxe.elixir/commit/a76714298395bc41bbda88f91f20a826409fe013))

# [0.12.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.11.0...v0.12.0) (2026-06-29)


### Features

* **phoenix:** lower live event protocols natively ([5157af9](https://github.com/fullofcaffeine/reflaxe.elixir/commit/5157af95543a44d7f453213e7a7865a23aab5a4d))

# [0.11.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.10.2...v0.11.0) (2026-06-19)


### Bug Fixes

* lower discarded mutations without stale values ([233a6c8](https://github.com/fullofcaffeine/reflaxe.elixir/commit/233a6c8e0bd75a079d2c33e9cb6ccfcb81aaa983))


### Features

* advance stdlib parity and typed API surfaces ([9c9a5e5](https://github.com/fullofcaffeine/reflaxe.elixir/commit/9c9a5e57a638ae120a85693d05e8013f088f4cd6))

## Unreleased

### Features

* **stdlib:** support Haxe Float NaN/Infinity semantics on BEAM, including
  Math, operators, IEEE bytes, JSON, serialization, templates, and runtime
  boundary diagnostics.

## [0.10.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.10.1...v0.10.2) (2026-06-18)


### Bug Fixes

* legalize receiver effects before iife lowering ([6734c8a](https://github.com/fullofcaffeine/reflaxe.elixir/commit/6734c8a7dd90e03c8b912baca7e7e342a6ad8c42))

## [0.10.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.10.0...v0.10.1) (2026-06-16)


### Bug Fixes

* thread persistent receiver state ([e8091c4](https://github.com/fullofcaffeine/reflaxe.elixir/commit/e8091c4cc7075c3c3cd7bc7a65cc82f5df9b0f7a))

# [0.10.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.5...v0.10.0) (2026-06-15)


### Features

* add haxe io string input ([a6d6136](https://github.com/fullofcaffeine/reflaxe.elixir/commit/a6d6136032b4587f5751fa339151ca1b4dd2619b))

## [0.9.5](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.4...v0.9.5) (2026-06-15)


### Performance Improvements

* add example compile benchmark ([54d5283](https://github.com/fullofcaffeine/reflaxe.elixir/commit/54d5283becac3e2f73ef36a7bd4bc2e391257547))

## [0.9.4](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.3...v0.9.4) (2026-06-15)


### Performance Improvements

* add todo watch benchmark ([51555ff](https://github.com/fullofcaffeine/reflaxe.elixir/commit/51555ff0deb33c12f38ff6488cda2b9ac3de4215))

## [0.9.3](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.2...v0.9.3) (2026-06-15)


### Performance Improvements

* add haxe compile phase timings ([e4e4284](https://github.com/fullofcaffeine/reflaxe.elixir/commit/e4e42842e6a37a7126ac08423695ac1c005e38b1))

## [0.9.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.1...v0.9.2) (2026-06-15)


### Performance Improvements

* add todo compile benchmark ([808ecac](https://github.com/fullofcaffeine/reflaxe.elixir/commit/808ecac75a5aa5f8b57700d721126cba1302ff8d))

## [0.9.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.9.0...v0.9.1) (2026-06-15)


### Bug Fixes

* preserve unrelated list indexing in reducers ([f555878](https://github.com/fullofcaffeine/reflaxe.elixir/commit/f5558781a3bb4d1cfd964fac0037332d5b669186))

# [0.9.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.8.0...v0.9.0) (2026-06-15)


### Features

* **interop:** scaffold app-local extern boundaries ([ed2f4e6](https://github.com/fullofcaffeine/reflaxe.elixir/commit/ed2f4e66f42b72ff10e0269bc9365d03a1895bb0))

# [0.8.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.7.0...v0.8.0) (2026-06-15)


### Features

* **ecto:** add typed changeset field tokens ([cb65945](https://github.com/fullofcaffeine/reflaxe.elixir/commit/cb6594561617b2b52a82d4663af1545734bbdd3d))

# [0.7.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.6.0...v0.7.0) (2026-06-15)


### Features

* normalize LiveView callback names ([a465916](https://github.com/fullofcaffeine/reflaxe.elixir/commit/a465916442727487df561a310c4e3fc309d222e6))

# [0.6.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.5.3...v0.6.0) (2026-06-15)


### Features

* add checked Ecto field selectors ([47fef59](https://github.com/fullofcaffeine/reflaxe.elixir/commit/47fef59fd30216544d568141482ddd7a0af0434b))

## [0.5.3](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.5.2...v0.5.3) (2026-06-13)


### Bug Fixes

* **generator:** guard strict hxx scaffolds ([534d4a5](https://github.com/fullofcaffeine/reflaxe.elixir/commit/534d4a5c9538d311bb435ae0ee15d580831d84e0))

## [0.5.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.5.1...v0.5.2) (2026-06-13)


### Bug Fixes

* **ast:** rewrite known string length before printing ([8a9a5d2](https://github.com/fullofcaffeine/reflaxe.elixir/commit/8a9a5d295b96b6788ff5cca2fcb42424120dab03))

## [0.5.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.5.0...v0.5.1) (2026-06-12)


### Bug Fixes

* **stdlib:** keep bytes compare out of guards ([692d60d](https://github.com/fullofcaffeine/reflaxe.elixir/commit/692d60d92e8fe9c95acf4f629f01309dac3af3ba))

# [0.5.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.4.0...v0.5.0) (2026-06-12)


### Features

* **stdlib:** implement haxe http on beam ([2a69ffd](https://github.com/fullofcaffeine/reflaxe.elixir/commit/2a69ffd41c076aadb44e02f831557919144e2783))

# [0.4.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.3.3...v0.4.0) (2026-06-11)


### Bug Fixes

* **docs:** refresh stdlib parity counters ([7de7f57](https://github.com/fullofcaffeine/reflaxe.elixir/commit/7de7f570c792b229854da59e85920cd29bc1d951))


### Features

* **std:** implement Xml support ([b81e471](https://github.com/fullofcaffeine/reflaxe.elixir/commit/b81e4719169dcd4e2d6e38f49f658db887d7d8a0))

## [0.3.3](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.3.2...v0.3.3) (2026-06-10)


### Bug Fixes

* **stdlib:** preserve Map abstract conversions ([6883568](https://github.com/fullofcaffeine/reflaxe.elixir/commit/6883568f1b1a340dae86611d59fee204529e802d))

## [0.3.2](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.3.1...v0.3.2) (2026-06-10)


### Bug Fixes

* **stdlib:** reject ObjectMap identity semantics ([fd8ae53](https://github.com/fullofcaffeine/reflaxe.elixir/commit/fd8ae53a763428e6ad0d3214edd622846b93b54f))

## [0.3.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.3.0...v0.3.1) (2026-06-10)


### Bug Fixes

* **stdlib:** lock native map iterator semantics ([017d229](https://github.com/fullofcaffeine/reflaxe.elixir/commit/017d229083211282c73ab0cc48b9d43c4f32b823))

# [0.3.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.2.1...v0.3.0) (2026-06-10)


### Features

* **stdlib:** add canonical IMap unwrap runtime ([67ab169](https://github.com/fullofcaffeine/reflaxe.elixir/commit/67ab169f73cbda56c6b8190c4764d50589eb4443))

## [0.2.1](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.2.0...v0.2.1) (2026-03-07)


### Bug Fixes

* **ci:** harden mix runtime deps and generator smoke ([4562d10](https://github.com/fullofcaffeine/reflaxe.elixir/commit/4562d1036404e61d43879a2a3e3be62c5faebdf7))

# [0.2.0](https://github.com/fullofcaffeine/reflaxe.elixir/compare/v0.1.0...v0.2.0) (2026-02-19)


### Bug Fixes

* **ci:** repair release workflow parsing and gating ([948d69e](https://github.com/fullofcaffeine/reflaxe.elixir/commit/948d69e68dc547c1453dcc13095d52ca85923dc2))
* **dogfood:** handle single-tag baselines after reset ([efb503f](https://github.com/fullofcaffeine/reflaxe.elixir/commit/efb503f5e0d0eafdfbb7f7224175e2870bded02b))
* **examples:** add ex13 handwritten Elixir interop sample ([f63f07a](https://github.com/fullofcaffeine/reflaxe.elixir/commit/f63f07aeca7919d43003ef1ea6a98a3533187c8c))
* **examples:** track scoped haxe_libraries for CI compile-check ([2b9ebc1](https://github.com/fullofcaffeine/reflaxe.elixir/commit/2b9ebc11ced59205e36def22653a8a90b74433b3))
* **guards:** support --next HXX mode in example build alias ([f34d355](https://github.com/fullofcaffeine/reflaxe.elixir/commit/f34d355c148ff7e737c5054a4f9391b3d863f30c))
* **release:** add conventionalcommits preset dependency ([e10107a](https://github.com/fullofcaffeine/reflaxe.elixir/commit/e10107a081648be457caf9b7782539a538919474))


### Features

* **phoenix:** add socket-first assign helpers ([1ce6508](https://github.com/fullofcaffeine/reflaxe.elixir/commit/1ce65085e11083ae48ff7837acc1e2601d8f880b))
* **router:** optional live route action + haxe-first chat guide/example ([90c15bf](https://github.com/fullofcaffeine/reflaxe.elixir/commit/90c15bfcad17ffa9a1234c8373e6c9c4a6c9cd0c))
* tighten typed Phoenix DSL APIs and refresh docs/examples ([14d8e23](https://github.com/fullofcaffeine/reflaxe.elixir/commit/14d8e2323c68d3e0c0340fba0f42420da9d6f50b))

# Changelog

All notable changes to Reflaxe.Elixir are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-18

### Baseline Release

- Reset release history after repository history cleanup.
- Established `v0.1.0` as the new semantic-release baseline tag on current `main`.
- Future release notes continue from this baseline.

[0.1.0]: https://github.com/fullofcaffeine/reflaxe.elixir/releases/tag/v0.1.0
